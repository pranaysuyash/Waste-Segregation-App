import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { OpenAI } from 'openai';
import * as fs from 'fs';
import * as path from 'path';
import {
  asiaSouth1, corsHandler, shouldEnforceHttpAppCheck, verifyHttpAppCheck,
  getBearerToken, getRateLimitConfig, enforceRateLimit, getClientIp,
  respondWithApiError, respondWithApiSuccess,
} from './helpers';

interface DisposalRequest {
  materialId: string;
  material: string;
  category?: string;
  subcategory?: string;
  lang?: string;
}

interface DisposalInstructions {
  steps: string[];
  primaryMethod: string;
  timeframe?: string;
  location?: string;
  warnings?: string[];
  tips?: string[];
  recyclingInfo?: string;
  estimatedTime?: string;
  hasUrgentTimeframe: boolean;
}

const getDisposalPrompt = (): string => {
  try {
    const promptPath = path.join(__dirname, '../../prompts/disposal.txt');
    return fs.readFileSync(promptPath, 'utf8');
  } catch (error) {
    functions.logger.error('Error loading disposal prompt', { error });
    return `You are a waste management expert. Generate disposal instructions for the given material.
    
Input: {"material":"$MATERIAL","lang":"$LANG"}

Generate a JSON object with: steps (array), primaryMethod, timeframe, location, warnings (array), tips (array), recyclingInfo, estimatedTime, hasUrgentTimeframe (boolean).

Provide 4-6 specific, actionable steps for proper disposal.`;
  }
};

export const generateDisposal = asiaSouth1.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      if (shouldEnforceHttpAppCheck()) {
        const appCheckValid = await verifyHttpAppCheck(req);
        if (!appCheckValid) {
          respondWithApiError(
            res,
            401,
            'AUTH_APP_CHECK_MISSING',
            'Unauthorized: valid App Check token required',
            {
              hint: 'Attach x-firebase-appcheck header from a Firebase App Check enabled client.',
            },
          );
          return;
        }
      }

      const requireAuth = (process.env.DISPOSAL_API_REQUIRE_AUTH ?? 'true') === 'true';
      const allowAnonymous = process.env.ALLOW_ANONYMOUS_DISPOSAL === 'true';
      if (requireAuth && !allowAnonymous) {
        const token = getBearerToken(req.headers.authorization);
        if (!token) {
          respondWithApiError(
            res,
            401,
            'AUTH_TOKEN_MISSING',
            'Unauthorized: Bearer token required',
            {
              hint: 'Set ALLOW_ANONYMOUS_DISPOSAL=true only for controlled environments.',
            },
          );
          return;
        }
        try {
          await admin.auth().verifyIdToken(token);
        } catch {
          respondWithApiError(res, 401, 'AUTH_TOKEN_INVALID', 'Unauthorized: invalid token');
          return;
        }
      }

      if (req.method !== 'POST') {
        respondWithApiError(res, 405, 'METHOD_NOT_ALLOWED', 'Method not allowed');
        return;
      }

      const { materialId, material, category, subcategory, lang = 'en' }: DisposalRequest = req.body;

      if (!materialId || !material) {
        respondWithApiError(
          res,
          400,
          'VALIDATION_ERROR',
          'Missing required fields: materialId, material',
        );
        return;
      }

      const rateLimitConfig = getRateLimitConfig();
      const rateLimitState = await enforceRateLimit({
        bucket: 'generateDisposal',
        subject: `ip:${getClientIp(req)}`,
        maxRequests: Math.max(1, rateLimitConfig.disposalMax),
        windowSeconds: Math.max(1, rateLimitConfig.windowSeconds),
      });
      if (rateLimitState.retryAfterSeconds > 0) {
        respondWithApiError(
          res,
          429,
          'RATE_LIMIT_EXCEEDED',
          'Rate limit exceeded',
          {
            maxRequests: rateLimitConfig.disposalMax,
            remaining: 0,
          },
          rateLimitState.retryAfterSeconds,
        );
        return;
      }

      const db = admin.firestore();
      const cacheRef = db.collection('disposal_instructions').doc(materialId);
      const cachedDoc = await cacheRef.get();

      if (cachedDoc.exists) {
        functions.logger.info('Returning cached disposal instructions', { materialId });
        const cachedData = cachedDoc.data();
        if (cachedData) {
          respondWithApiSuccess(res, 200, {
            ...cachedData,
            source: cachedData.source ?? 'cache_firestore',
            cached: true,
          });
          return;
        }

        respondWithApiError(
          res,
          500,
          'SERVER_CACHE_CORRUPT',
          'Cached disposal instructions are invalid.',
        );
        return;
      }

      let materialDescription = material;
      if (category) materialDescription += ` (${category}`;
      if (subcategory) materialDescription += ` - ${subcategory}`;
      if (category) materialDescription += ')';

      const promptTemplate = getDisposalPrompt();
      const prompt = promptTemplate
        .replace('$MATERIAL', materialDescription)
        .replace('$LANG', lang);

      functions.logger.info('Generating disposal instructions', { materialDescription });

      const apiKey = process.env.OPENAI_API_KEY || process.env.OPENAI_KEY;
      if (!apiKey) {
        throw new Error('OpenAI not configured - using fallback');
      }
      const openai = new OpenAI({ apiKey });

      const disposalModel = process.env.DISPOSAL_MODEL ?? 'gpt-4.1-mini';
      const completion = await openai.chat.completions.create({
        model: disposalModel,
        messages: [
          { role: 'system', content: prompt },
          { role: 'user', content: JSON.stringify({ material: materialDescription, lang }) },
        ],
        functions: [{
          name: 'generate_disposal_instructions',
          description: 'Generate structured disposal instructions for waste materials',
          parameters: {
            type: 'object',
            properties: {
              steps: { type: 'array', items: { type: 'string' }, description: 'Array of 4-6 specific disposal steps' },
              primaryMethod: { type: 'string', description: 'Brief summary of main disposal method' },
              timeframe: { type: 'string', description: 'When to dispose (e.g., Immediately, Within 24 hours)' },
              location: { type: 'string', description: 'Where to dispose (bin type, facility)' },
              warnings: { type: 'array', items: { type: 'string' }, description: 'Safety or environmental warnings' },
              tips: { type: 'array', items: { type: 'string' }, description: 'Helpful disposal tips' },
              recyclingInfo: { type: 'string', description: 'Additional recycling information' },
              estimatedTime: { type: 'string', description: 'Time needed for disposal process' },
              hasUrgentTimeframe: { type: 'boolean', description: 'True for hazardous/medical waste requiring immediate disposal' },
            },
            required: ['steps', 'primaryMethod', 'hasUrgentTimeframe'],
          },
        }],
        function_call: { name: 'generate_disposal_instructions' },
        temperature: 0.3,
        max_tokens: 1000,
      });

      const functionCall = completion.choices[0]?.message?.function_call;
      if (!functionCall || !functionCall.arguments) {
        throw new Error('No function call response from OpenAI');
      }

      const disposalInstructions: DisposalInstructions = JSON.parse(functionCall.arguments);

      if (!disposalInstructions.steps || !Array.isArray(disposalInstructions.steps) || disposalInstructions.steps.length < 3) {
        throw new Error('Invalid disposal instructions format');
      }

      const result = {
        ...disposalInstructions,
        materialId,
        material: materialDescription,
        language: lang,
        generatedAt: FieldValue.serverTimestamp(),
        modelUsed: disposalModel,
        source: 'openai',
        version: '1.0',
        cached: false,
      };

      await cacheRef.set(result);
      functions.logger.info('Generated and cached disposal instructions', { materialId });
      respondWithApiSuccess(res, 200, {
        ...result,
      });
    } catch (error: any) {
      functions.logger.error('Error generating disposal instructions', { error });

      const isRetryableError = (
        error.code === 'rate_limit_exceeded' ||
        error.status === 429 ||
        error.status === 503 ||
        error.status === 502 ||
        error.status === 504 ||
        (error.message && error.message.includes('timeout'))
      );

      if (isRetryableError) {
        functions.logger.info('Retryable error detected, returning 503 with retry-after');
        respondWithApiError(
          res,
          503,
          'SERVICE_UNAVAILABLE',
          'Service temporarily unavailable',
          {
            code: 'retryable_error',
            retryAfter: 30,
            fallback: true,
          },
          30,
        );
        return;
      }

      const fallbackInstructions = {
        steps: [
          'Identify the correct waste category for this item',
          'Clean the item if required (remove food residue, rinse if needed)',
          'Place in the appropriate disposal bin or take to designated facility',
          'Follow local waste management guidelines for collection',
        ],
        primaryMethod: 'Follow local waste guidelines',
        timeframe: 'As per local collection schedule',
        location: 'Appropriate waste bin or facility',
        warnings: ['Check local regulations for specific requirements'],
        tips: ['When in doubt, contact local waste management authorities'],
        hasUrgentTimeframe: false,
        materialId: req.body.materialId,
        material: req.body.material,
        language: req.body.lang || 'en',
        generatedAt: FieldValue.serverTimestamp(),
        modelUsed: 'fallback',
        version: '1.0',
        error: 'AI generation failed, using fallback instructions',
      };

      respondWithApiSuccess(res, 200, {
        ...fallbackInstructions,
        source: 'fallback',
        cached: false,
      });
    }
  });
});
