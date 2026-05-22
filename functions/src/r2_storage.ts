import * as functions from 'firebase-functions';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const asiaSouth1 = functions.region('asia-south1');

function getR2Client(): S3Client {
  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;

  if (!accountId || !accessKeyId || !secretAccessKey) {
    throw new Error('R2 credentials not configured. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY.');
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

const BUCKET_NAME = process.env.R2_BUCKET_NAME ?? 'waste-segregation';
const EXPIRES_IN_SECONDS = 15 * 60;

interface GetUploadUrlData {
  file_name: string;
  content_type: string;
  folder?: string;
}

interface GetUploadUrlResponse {
  upload_url: string;
  public_url: string;
  object_key: string;
}

export const getR2UploadUrl = asiaSouth1.https.onCall(async (data: GetUploadUrlData, context): Promise<GetUploadUrlResponse> => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const { file_name, content_type, folder } = data;
  if (!file_name || !content_type) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'file_name and content_type are required.',
    );
  }

  const uid = context.auth.uid;
  const timestamp = Date.now();
  const sanitizedFileName = file_name.replace(/[^a-zA-Z0-9._-]/g, '_');
  const objectKey = folder
    ? `${folder}/${uid}/${timestamp}_${sanitizedFileName}`
    : `uploads/${uid}/${timestamp}_${sanitizedFileName}`;

  try {
    const client = getR2Client();
    const putCommand = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: objectKey,
      ContentType: content_type,
    });

    const uploadUrl = await getSignedUrl(client, putCommand, { expiresIn: EXPIRES_IN_SECONDS });

    const publicUrl = `https://${BUCKET_NAME}.r2.cloudflarestorage.com/${objectKey}`;

    functions.logger.info('R2 upload URL generated', {
      uid,
      objectKey,
      expiresIn: EXPIRES_IN_SECONDS,
    });

    return {
      upload_url: uploadUrl,
      public_url: publicUrl,
      object_key: objectKey,
    };
  } catch (error) {
    functions.logger.error('Failed to generate R2 upload URL', { error });
    throw new functions.https.HttpsError('internal', 'Failed to generate upload URL.');
  }
});
