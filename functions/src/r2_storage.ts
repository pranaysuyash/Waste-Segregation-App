import * as functions from 'firebase-functions';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import {
  enforceRateLimit,
  getRateLimitConfig,
  shouldEnforceCallableAppCheck,
} from './helpers';

const asiaSouth1 = functions.region('asia-south1');

const BUCKET_NAME = process.env.R2_BUCKET_NAME ?? 'waste-segregation';
const EXPIRES_IN_SECONDS = 15 * 60;
const MAX_UPLOAD_BYTES = 4 * 1024 * 1024;
const MAX_FILENAME_LENGTH = 128;
const DEFAULT_UPLOAD_PREFIX = 'uploads';
const ALLOWED_UPLOAD_PREFIXES = new Set([DEFAULT_UPLOAD_PREFIX]);
const ALLOWED_CONTENT_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

function getR2Client(): S3Client {
  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;

  if (!accountId || !accessKeyId || !secretAccessKey) {
    throw new Error(
      'R2 credentials not configured. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY.',
    );
  }

  return new S3Client({
    region: 'auto',
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId,
      secretAccessKey,
    },
  });
}

interface GetUploadUrlData {
  file_name?: string;
  content_type?: string;
  folder?: string;
  content_length?: number | string;
  file_size_bytes?: number | string;
  file_size?: number | string;
  size_bytes?: number | string;
}

interface GetUploadUrlResponse {
  upload_url: string;
  public_url: string;
  object_key: string;
}

function normalizeFileName(value: unknown): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'file_name is required.',
    );
  }

  const fileName = value.trim();
  if (fileName.includes('/') || fileName.includes('\\')) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'file_name must be a base filename.',
    );
  }

  const normalized = fileName
    .slice(0, MAX_FILENAME_LENGTH)
    .replace(/[^a-zA-Z0-9._-]/g, '_');
  if (normalized.length === 0 || normalized === '.' || normalized === '..') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'file_name is invalid.',
    );
  }
  return normalized;
}

function normalizeContentType(value: unknown): string {
  if (typeof value !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'content_type is required.',
    );
  }

  const contentType = value.trim().toLowerCase();
  if (!ALLOWED_CONTENT_TYPES.has(contentType)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Unsupported content_type. Only supported image types may be uploaded.',
    );
  }
  return contentType;
}

function parseContentLength(data: GetUploadUrlData): number {
  const suppliedLength = data.content_length
    ?? data.file_size_bytes
    ?? data.file_size
    ?? data.size_bytes;

  if (suppliedLength == null || suppliedLength === '') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'content_length is required so the upload can be constrained.',
    );
  }

  const contentLength = Number(suppliedLength);
  if (!Number.isSafeInteger(contentLength) || contentLength <= 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'content_length must be a positive whole number of bytes.',
    );
  }
  if (contentLength > MAX_UPLOAD_BYTES) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Uploads may not exceed ${MAX_UPLOAD_BYTES} bytes.`,
    );
  }
  return contentLength;
}

function resolveUploadPrefix(value: unknown): string {
  if (value == null || value === '') return DEFAULT_UPLOAD_PREFIX;
  if (typeof value !== 'string' || !ALLOWED_UPLOAD_PREFIXES.has(value)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'folder is not an allowed upload purpose.',
    );
  }
  return value;
}

function getPublicBaseUrl(): string {
  const configuredBaseUrl = process.env.R2_PUBLIC_BASE_URL?.trim();
  if (!configuredBaseUrl) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'R2_PUBLIC_BASE_URL is not configured for public object delivery.',
    );
  }

  let parsed: URL;
  try {
    parsed = new URL(configuredBaseUrl);
  } catch {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'R2_PUBLIC_BASE_URL is invalid.',
    );
  }
  if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'R2_PUBLIC_BASE_URL must use HTTP or HTTPS.',
    );
  }
  return configuredBaseUrl.replace(/\/+$/, '');
}

function buildPublicUrl(baseUrl: string, objectKey: string): string {
  const encodedKey = objectKey
    .split('/')
    .map((segment) => encodeURIComponent(segment))
    .join('/');
  return `${baseUrl.replace(/\/+$/, '')}/${encodedKey}`;
}

export const getR2UploadUrl = asiaSouth1.https.onCall(
  async (
    data: GetUploadUrlData,
    context,
  ): Promise<GetUploadUrlResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    if (shouldEnforceCallableAppCheck() && !context.app) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'App Check token required.',
      );
    }

    const fileName = normalizeFileName(data?.file_name);
    const contentType = normalizeContentType(data?.content_type);
    const contentLength = parseContentLength(data ?? {});
    const uploadPrefix = resolveUploadPrefix(data?.folder);
    const publicBaseUrl = getPublicBaseUrl();
    const uid = context.auth.uid;

    const rateLimitConfig = getRateLimitConfig();
    const rateLimitState = await enforceRateLimit({
      bucket: 'r2_upload',
      subject: `uid:${uid}`,
      maxRequests: Math.max(1, rateLimitConfig.disposalMax),
      windowSeconds: Math.max(1, rateLimitConfig.windowSeconds),
    });
    if (rateLimitState.retryAfterSeconds > 0) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Upload request rate limit exceeded. Try again later.',
        { retryAfterSeconds: rateLimitState.retryAfterSeconds },
      );
    }

    const safeUid = uid.replace(/[^a-zA-Z0-9_:-]/g, '_');
    const objectKey = `${uploadPrefix}/${safeUid}/${Date.now()}_${fileName}`;

    try {
      const client = getR2Client();
      const putCommand = new PutObjectCommand({
        Bucket: BUCKET_NAME,
        Key: objectKey,
        ContentType: contentType,
        ContentLength: contentLength,
      });

      const uploadUrl = await getSignedUrl(client, putCommand, {
        expiresIn: EXPIRES_IN_SECONDS,
      });
      const publicUrl = buildPublicUrl(publicBaseUrl, objectKey);

      functions.logger.info('R2 upload URL generated', {
        uid,
        objectKey,
        contentType,
        contentLength,
        expiresIn: EXPIRES_IN_SECONDS,
      });

      return {
        upload_url: uploadUrl,
        public_url: publicUrl,
        object_key: objectKey,
      };
    } catch (error) {
      functions.logger.error('Failed to generate R2 upload URL', {
        uid,
        objectKey,
        errorType: error instanceof Error ? error.name : 'unknown',
      });
      throw new functions.https.HttpsError(
        'internal',
        'Failed to generate upload URL.',
      );
    }
  },
);

export const __testables = {
  buildPublicUrl,
  normalizeContentType,
  normalizeFileName,
  parseContentLength,
  resolveUploadPrefix,
};
