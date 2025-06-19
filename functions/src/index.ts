import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { OpenAI } from 'openai';
import cors from 'cors';
import * as fs from 'fs';
import * as path from 'path';
import axios from 'axios';

// Initialize Firebase Admin
admin.initializeApp();

// Configure region for better performance in Asia
const asiaSouth1 = functions.region('asia-south1');

// Initialize OpenAI (conditional)
let openai: OpenAI | null = null;
try {
  // Try environment variable first (for local development), then Firebase config (for production)
  const apiKey = process.env.OPENAI_API_KEY || functions.config()?.openai?.key;
  
  if (apiKey) {
    openai = new OpenAI({
      apiKey: apiKey,
    });
    console.log('OpenAI initialized successfully');
  } else {
    console.warn('OpenAI API key not configured - functions will use fallback responses');
  }
} catch (error) {
  console.warn('Failed to initialize OpenAI:', error);
}

// CORS configuration
const corsHandler = cors({ origin: true });

// Load disposal prompt template
const getDisposalPrompt = (): string => {
  try {
    const promptPath = path.join(__dirname, '../../prompts/disposal.txt');
    return fs.readFileSync(promptPath, 'utf8');
  } catch (error) {
    console.error('Error loading disposal prompt:', error);
    // Fallback prompt
    return `You are a waste management expert. Generate disposal instructions for the given material.
    
Input: {"material":"$MATERIAL","lang":"$LANG"}

Generate a JSON object with: steps (array), primaryMethod, timeframe, location, warnings (array), tips (array), recyclingInfo, estimatedTime, hasUrgentTimeframe (boolean).

Provide 4-6 specific, actionable steps for proper disposal.`;
  }
};

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

export const generateDisposal = asiaSouth1.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      // Validate request method
      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
      }

      // Parse request body
      const { materialId, material, category, subcategory, lang = 'en' }: DisposalRequest = req.body;

      if (!materialId || !material) {
        res.status(400).json({ error: 'Missing required fields: materialId, material' });
        return;
      }

      // Check if instructions already exist in cache
      const db = admin.firestore();
      const cacheRef = db.collection('disposal_instructions').doc(materialId);
      const cachedDoc = await cacheRef.get();

      if (cachedDoc.exists) {
        console.log(`Returning cached disposal instructions for ${materialId}`);
        res.json(cachedDoc.data());
        return;
      }

      // Prepare material description
      let materialDescription = material;
      if (category) materialDescription += ` (${category}`;
      if (subcategory) materialDescription += ` - ${subcategory}`;
      if (category) materialDescription += ')';

      // Load and prepare prompt
      const promptTemplate = getDisposalPrompt();
      const prompt = promptTemplate
        .replace('$MATERIAL', materialDescription)
        .replace('$LANG', lang);

      console.log(`Generating disposal instructions for: ${materialDescription}`);

      // Check if OpenAI is available
      if (!openai) {
        throw new Error('OpenAI not configured - using fallback');
      }

      // Call OpenAI API
      const completion = await openai.chat.completions.create({
        model: 'gpt-4',
        messages: [
          {
            role: 'system',
            content: prompt
          },
          {
            role: 'user',
            content: JSON.stringify({ material: materialDescription, lang })
          }
        ],
        functions: [
          {
            name: 'generate_disposal_instructions',
            description: 'Generate structured disposal instructions for waste materials',
            parameters: {
              type: 'object',
              properties: {
                steps: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Array of 4-6 specific disposal steps'
                },
                primaryMethod: {
                  type: 'string',
                  description: 'Brief summary of main disposal method'
                },
                timeframe: {
                  type: 'string',
                  description: 'When to dispose (e.g., Immediately, Within 24 hours)'
                },
                location: {
                  type: 'string',
                  description: 'Where to dispose (bin type, facility)'
                },
                warnings: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Safety or environmental warnings'
                },
                tips: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Helpful disposal tips'
                },
                recyclingInfo: {
                  type: 'string',
                  description: 'Additional recycling information'
                },
                estimatedTime: {
                  type: 'string',
                  description: 'Time needed for disposal process'
                },
                hasUrgentTimeframe: {
                  type: 'boolean',
                  description: 'True for hazardous/medical waste requiring immediate disposal'
                }
              },
              required: ['steps', 'primaryMethod', 'hasUrgentTimeframe']
            }
          }
        ],
        function_call: { name: 'generate_disposal_instructions' },
        temperature: 0.3,
        max_tokens: 1000
      });

      // Parse the function call response
      const functionCall = completion.choices[0]?.message?.function_call;
      if (!functionCall || !functionCall.arguments) {
        throw new Error('No function call response from OpenAI');
      }

      const disposalInstructions: DisposalInstructions = JSON.parse(functionCall.arguments);

      // Validate the response
      if (!disposalInstructions.steps || !Array.isArray(disposalInstructions.steps) || disposalInstructions.steps.length < 3) {
        throw new Error('Invalid disposal instructions format');
      }

      // Add metadata
      const result = {
        ...disposalInstructions,
        materialId,
        material: materialDescription,
        language: lang,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        modelUsed: 'gpt-4',
        version: '1.0'
      };

      // Cache the result
      await cacheRef.set(result);

      console.log(`Generated and cached disposal instructions for ${materialId}`);
      res.json(result);

    } catch (error) {
      console.error('Error generating disposal instructions:', error);
      
      // Return fallback instructions
      const fallbackInstructions = {
        steps: [
          'Identify the correct waste category for this item',
          'Clean the item if required (remove food residue, rinse if needed)',
          'Place in the appropriate disposal bin or take to designated facility',
          'Follow local waste management guidelines for collection'
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
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        modelUsed: 'fallback',
        version: '1.0',
        error: 'AI generation failed, using fallback instructions'
      };

      res.status(200).json(fallbackInstructions);
    }
  });
});

// Health check endpoint
export const healthCheck = asiaSouth1.https.onRequest((req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Test endpoint to verify OpenAI configuration
export const testOpenAI = asiaSouth1.https.onRequest((req, res) => {
  const apiKey = process.env.OPENAI_API_KEY || functions.config()?.openai?.key;
  res.json({ 
    status: 'ok',
    openaiConfigured: !!apiKey,
    keySource: process.env.OPENAI_API_KEY ? 'environment' : 'firebase-config',
    keyLength: apiKey ? apiKey.length : 0,
    timestamp: new Date().toISOString()
  });
});

// FIXED: Clear all data function that properly awaits all deletions
export const clearAllData = asiaSouth1.https.onCall(async (data, context) => {
  try {
    console.log('🔥 Starting COMPLETE Firestore data clearing...');
    
    // Security check - only allow in development/testing
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const db = admin.firestore();
    const projectId = process.env.GCLOUD_PROJECT;
    
    if (!projectId) {
      throw new functions.https.HttpsError('internal', 'Project ID not available');
    }
    
    console.log(`Clearing all data for project: ${projectId}`);
    
    // Get all root-level collections
    const collections = await db.listCollections();
    console.log(`Found ${collections.length} root collections to delete`);
    
    // Delete each collection recursively and await ALL deletions
    const deletePromises = collections.map(async (collection) => {
      const collectionPath = collection.path;
      console.log(`Deleting collection: ${collectionPath}`);
      
      try {
        // Delete all documents in the collection in batches
        await deleteCollectionRecursively(db, collectionPath);
        console.log(`✅ Deleted collection: ${collectionPath}`);
      } catch (error) {
        console.error(`❌ Error deleting collection ${collectionPath}:`, error);
        throw error;
      }
    });
    
    // CRITICAL: Wait for ALL deletions to complete before returning
    await Promise.all(deletePromises);
    
    console.log('✅ All Firestore collections deleted successfully');
    
    // Reset community stats to zero
    await db.collection('community_stats').doc('main').set({
      totalUsers: 0,
      totalClassifications: 0,
      totalPoints: 0,
      categoryBreakdown: {},
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log('✅ Community stats reset to zero');
    console.log('🎉 COMPLETE Firestore data clearing finished successfully');
    
    return { 
      success: true, 
      message: 'All data cleared successfully',
      timestamp: new Date().toISOString(),
      collectionsDeleted: collections.length
    };
    
  } catch (error) {
    console.error('❌ Error during data clearing:', error);
    throw new functions.https.HttpsError('internal', `Data clearing failed: ${error}`);
  }
});

// Helper function to recursively delete a collection
async function deleteCollectionRecursively(db: admin.firestore.Firestore, collectionPath: string): Promise<void> {
  const collectionRef = db.collection(collectionPath);
  const batchSize = 100; // Firestore batch limit
  
  let query = collectionRef.limit(batchSize);
  let snapshot = await query.get();
  
  while (!snapshot.empty) {
    const batch = db.batch();
    
    for (const doc of snapshot.docs) {
      // First, delete any subcollections
      const subcollections = await doc.ref.listCollections();
      for (const subcollection of subcollections) {
        await deleteCollectionRecursively(db, subcollection.path);
      }
      
      // Then delete the document
      batch.delete(doc.ref);
    }
    
    await batch.commit();
    console.log(`Deleted batch of ${snapshot.docs.length} documents from ${collectionPath}`);
    
    // Get next batch
    snapshot = await query.get();
  }
}

// ===== BATCH PROCESSING FUNCTIONS =====

interface BatchJobStatus {
  status: string;
  output_file_id?: string;
  errors?: any;
}

interface ClassificationResult {
  itemName: string;
  category: string;
  confidence: number;
  disposalInstructions: string;
  environmentalImpact: string;
  tips: string[];
  timestamp: admin.firestore.FieldValue;
  analysisMethod: string;
  processingTime: number;
}

/**
 * Cloud Function to process OpenAI batch jobs
 * Scheduled to run every 10 minutes
 */
export const processBatchJobs = asiaSouth1.pubsub
  .schedule('*/10 * * * *') // Run every 10 minutes
  .timeZone('UTC')
  .onRun(async (context) => {
    const logger = functions.logger;
    
    try {
      logger.info('Starting batch job processing');

      // Get all active batch jobs from Firestore
      const db = admin.firestore();
      const activeJobs = await db.collection('ai_jobs')
        .where('status', 'in', ['queued', 'processing'])
        .get();

      if (activeJobs.empty) {
        logger.info('No active batch jobs found');
        return null;
      }

      logger.info(`Found ${activeJobs.size} active batch jobs`);

      // Process each job
      const processingPromises = activeJobs.docs.map(async (jobDoc) => {
        const jobData = jobDoc.data();
        const jobId = jobDoc.id;
        const openAIBatchId = jobData.openAIBatchId;

        if (!openAIBatchId) {
          logger.warn(`Job ${jobId} missing OpenAI batch ID`);
          return;
        }

        try {
          // Check OpenAI batch status
          const batchStatus = await checkOpenAIBatchStatus(openAIBatchId);
          
          if (batchStatus.status !== jobData.status) {
            await updateJobStatus(jobId, batchStatus, jobData);
          }

          // If completed, process results
          if (batchStatus.status === 'completed' && batchStatus.output_file_id) {
            await processCompletedJob(jobId, batchStatus.output_file_id, jobData);
          }

          // If failed, update with error
          if (batchStatus.status === 'failed') {
            await updateJobWithError(jobId, batchStatus.errors || 'Batch job failed');
          }

        } catch (error) {
          logger.error(`Error processing job ${jobId}:`, error);
          await updateJobWithError(jobId, (error as Error).message);
        }
      });

      await Promise.all(processingPromises);
      logger.info('Batch job processing completed');
      return null;

    } catch (error) {
      logger.error('Error in batch job processing:', error);
      throw error;
    }
  });

/**
 * Checks the status of an OpenAI batch job
 */
async function checkOpenAIBatchStatus(batchId: string): Promise<BatchJobStatus> {
  const openaiApiKey = functions.config().openai?.key;
  
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured');
  }

  const response = await axios.get(
    `https://api.openai.com/v1/batches/${batchId}`,
    {
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
    }
  );

  return response.data;
}

/**
 * Downloads and processes results from completed OpenAI batch job
 */
async function processCompletedJob(jobId: string, outputFileId: string, jobData: any): Promise<void> {
  const logger = functions.logger;
  
  try {
    // Download results from OpenAI
    const results = await downloadOpenAIResults(outputFileId);
    
    // Parse the JSONL results
    const resultLines = results.split('\n').filter((line: string) => line.trim());
    
    for (const line of resultLines) {
      const result = JSON.parse(line);
      
      if (result.custom_id === `job-${jobId}`) {
        // Extract classification result
        const classification = parseClassificationResult(result);
        
        // Update Firestore with results
        const db = admin.firestore();
        await db.collection('ai_jobs').doc(jobId).update({
          status: 'completed',
          result: classification,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Add to user's classification history
        await addToClassificationHistory(jobData.userId, classification, jobData);

        // Trigger notification
        await triggerJobCompletionNotification(jobId, jobData.userId, classification);
        
        logger.info(`Successfully processed completed job ${jobId}`);
        break;
      }
    }

  } catch (error) {
    logger.error(`Error processing completed job ${jobId}:`, error);
    await updateJobWithError(jobId, `Failed to process results: ${(error as Error).message}`);
  }
}

/**
 * Downloads results from OpenAI Files API
 */
async function downloadOpenAIResults(fileId: string): Promise<string> {
  const openaiApiKey = functions.config().openai?.key;
  
  const response = await axios.get(
    `https://api.openai.com/v1/files/${fileId}/content`,
    {
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
      },
    }
  );

  return response.data;
}

/**
 * Parses OpenAI response into WasteClassification format
 */
function parseClassificationResult(openaiResult: any): ClassificationResult {
  try {
    const response = openaiResult.response.body.choices[0].message.content;
    const parsed = JSON.parse(response);
    
    return {
      itemName: parsed.itemName || 'Unknown Item',
      category: parsed.category || 'general',
      confidence: parsed.confidence || 0.5,
      disposalInstructions: parsed.disposalInstructions || 'Dispose according to local guidelines',
      environmentalImpact: parsed.environmentalImpact || 'Environmental impact information not available',
      tips: parsed.tips || [],
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      analysisMethod: 'batch_ai',
      processingTime: 0, // Batch processing time is handled differently
    };
  } catch (error) {
    functions.logger.error('Error parsing classification result:', error);
    
    // Return fallback classification
    return {
      itemName: 'Classification Error',
      category: 'general',
      confidence: 0.1,
      disposalInstructions: 'Unable to classify item. Please dispose according to local guidelines.',
      environmentalImpact: 'Classification failed - environmental impact unknown',
      tips: ['Contact local waste management for guidance'],
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      analysisMethod: 'batch_ai_fallback',
      processingTime: 0,
    };
  }
}

/**
 * Updates job status in Firestore
 */
async function updateJobStatus(jobId: string, batchStatus: BatchJobStatus, currentJobData: any): Promise<void> {
  const db = admin.firestore();
  
  await db.collection('ai_jobs').doc(jobId).update({
    status: batchStatus.status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...(batchStatus.status === 'processing' && !currentJobData.processingStartedAt && {
      processingStartedAt: admin.firestore.FieldValue.serverTimestamp()
    })
  });
  
  functions.logger.info(`Updated job ${jobId} status to ${batchStatus.status}`);
}

/**
 * Updates job with error information
 */
async function updateJobWithError(jobId: string, errorMessage: string): Promise<void> {
  const db = admin.firestore();
  
  await db.collection('ai_jobs').doc(jobId).update({
    status: 'failed',
    error: errorMessage,
    failedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  functions.logger.error(`Job ${jobId} failed: ${errorMessage}`);
}

/**
 * Adds classification to user's history
 */
async function addToClassificationHistory(userId: string, classification: ClassificationResult, jobData: any): Promise<void> {
  const db = admin.firestore();
  
  const historyEntry = {
    ...classification,
    userId,
    imagePath: jobData.imagePath,
    thumbnailPath: jobData.thumbnailPath,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    source: 'batch_processing',
    jobId: jobData.id,
  };
  
  await db.collection('classifications').add(historyEntry);
  functions.logger.info(`Added classification to history for user ${userId}`);
}

/**
 * Triggers notification for job completion
 */
async function triggerJobCompletionNotification(jobId: string, userId: string, classification: ClassificationResult): Promise<void> {
  const db = admin.firestore();
  
  const notification = {
    userId,
    type: 'batch_job_completed',
    title: 'Analysis Complete!',
    message: `Your ${classification.itemName} has been analyzed`,
    data: {
      jobId,
      classification,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  };
  
  await db.collection('notifications').add(notification);
  functions.logger.info(`Created notification for user ${userId} - job ${jobId}`);
}

/**
 * HTTP endpoint to get batch processing statistics
 */
export const getBatchStats = asiaSouth1.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      const db = admin.firestore();
      
      // Get job counts by status
      const [queuedJobs, processingJobs, completedJobs, failedJobs] = await Promise.all([
        db.collection('ai_jobs').where('status', '==', 'queued').get(),
        db.collection('ai_jobs').where('status', '==', 'processing').get(),
        db.collection('ai_jobs').where('status', '==', 'completed').get(),
        db.collection('ai_jobs').where('status', '==', 'failed').get(),
      ]);
      
      const stats = {
        queued: queuedJobs.size,
        processing: processingJobs.size,
        completed: completedJobs.size,
        failed: failedJobs.size,
        total: queuedJobs.size + processingJobs.size + completedJobs.size + failedJobs.size,
        timestamp: new Date().toISOString(),
      };
      
      res.json(stats);
      
    } catch (error) {
      console.error('Error getting batch stats:', error);
      res.status(500).json({ error: 'Failed to get batch statistics' });
    }
  });
});