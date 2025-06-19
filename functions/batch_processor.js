const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to process OpenAI batch jobs
 * 
 * This function:
 * 1. Polls OpenAI Batch API for job status updates
 * 2. Downloads completed batch results
 * 3. Updates Firestore with results
 * 4. Triggers notifications for completed jobs
 * 
 * Scheduled to run every 10 minutes during business hours
 */
exports.processBatchJobs = functions.pubsub
  .schedule('*/10 * * * *') // Run every 10 minutes
  .timeZone('UTC')
  .onRun(async (context) => {
    const logger = functions.logger;
    
    try {
      logger.info('Starting batch job processing');

      // Get all active batch jobs from Firestore
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
          await updateJobWithError(jobId, error.message);
        }
      });

      await Promise.all(processingPromises);
      logger.info('Batch job processing completed');

    } catch (error) {
      logger.error('Error in batch job processing:', error);
      throw error;
    }
  });

/**
 * Checks the status of an OpenAI batch job
 */
async function checkOpenAIBatchStatus(batchId) {
  const openaiApiKey = functions.config().openai?.api_key;
  
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
async function processCompletedJob(jobId, outputFileId, jobData) {
  const logger = functions.logger;
  
  try {
    // Download results from OpenAI
    const results = await downloadOpenAIResults(outputFileId);
    
    // Parse the JSONL results
    const resultLines = results.split('\n').filter(line => line.trim());
    
    for (const line of resultLines) {
      const result = JSON.parse(line);
      
      if (result.custom_id === `job-${jobId}`) {
        // Extract classification result
        const classification = parseClassificationResult(result);
        
        // Update Firestore with results
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
    await updateJobWithError(jobId, `Failed to process results: ${error.message}`);
  }
}

/**
 * Downloads results from OpenAI Files API
 */
async function downloadOpenAIResults(fileId) {
  const openaiApiKey = functions.config().openai?.api_key;
  
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
function parseClassificationResult(openaiResult) {
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
      disposalInstructions: 'Unable to classify. Please consult local waste management guidelines.',
      environmentalImpact: 'Classification failed',
      tips: ['Try taking a clearer photo', 'Ensure good lighting', 'Contact support if issue persists'],
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      analysisMethod: 'batch_ai_error',
      processingTime: 0,
    };
  }
}

/**
 * Updates job status in Firestore
 */
async function updateJobStatus(jobId, batchStatus, currentJobData) {
  const statusMapping = {
    'validating': 'queued',
    'in_progress': 'processing',
    'finalizing': 'processing',
    'completed': 'completed',
    'failed': 'failed',
    'expired': 'failed',
    'cancelled': 'failed',
  };

  const newStatus = statusMapping[batchStatus.status] || currentJobData.status;

  if (newStatus !== currentJobData.status) {
    await db.collection('ai_jobs').doc(jobId).update({
      status: newStatus,
      openAIStatus: batchStatus.status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Updated job ${jobId} status: ${currentJobData.status} -> ${newStatus}`);
  }
}

/**
 * Updates job with error information
 */
async function updateJobWithError(jobId, errorMessage) {
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
async function addToClassificationHistory(userId, classification, jobData) {
  try {
    const historyEntry = {
      ...classification,
      imageUrl: jobData.imageUrl,
      imageName: jobData.imageName,
      useSegmentation: jobData.useSegmentation || false,
      segments: jobData.segments || null,
      jobId: jobData.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('users').doc(userId)
      .collection('classifications').add(historyEntry);

    functions.logger.info(`Added classification to history for user ${userId}`);
  } catch (error) {
    functions.logger.error(`Error adding to classification history:`, error);
  }
}

/**
 * Triggers notification for job completion
 */
async function triggerJobCompletionNotification(jobId, userId, classification) {
  try {
    // Create notification document
    const notification = {
      userId: userId,
      type: 'batch_job_completed',
      title: 'Analysis Complete!',
      message: `Your waste classification is ready: ${classification.itemName}`,
      data: {
        jobId: jobId,
        classification: classification,
      },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('notifications').add(notification);

    // TODO: Send push notification if user has FCM token
    // This would integrate with Firebase Cloud Messaging

    functions.logger.info(`Created notification for user ${userId}, job ${jobId}`);
  } catch (error) {
    functions.logger.error(`Error creating notification:`, error);
  }
}

/**
 * Manual trigger for processing specific batch job (for testing)
 */
exports.processSingleBatchJob = functions.https.onCall(async (data, context) => {
  // Verify user authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { jobId } = data;
  
  if (!jobId) {
    throw new functions.https.HttpsError('invalid-argument', 'Job ID is required');
  }

  try {
    const jobDoc = await db.collection('ai_jobs').doc(jobId).get();
    
    if (!jobDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Job not found');
    }

    const jobData = jobDoc.data();
    
    // Verify user owns this job
    if (jobData.userId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Access denied');
    }

    const openAIBatchId = jobData.openAIBatchId;
    
    if (!openAIBatchId) {
      throw new functions.https.HttpsError('failed-precondition', 'Job missing OpenAI batch ID');
    }

    // Check status and process if needed
    const batchStatus = await checkOpenAIBatchStatus(openAIBatchId);
    await updateJobStatus(jobId, batchStatus, jobData);

    if (batchStatus.status === 'completed' && batchStatus.output_file_id) {
      await processCompletedJob(jobId, batchStatus.output_file_id, jobData);
    }

    return { 
      success: true, 
      status: batchStatus.status,
      message: 'Job processed successfully' 
    };

  } catch (error) {
    functions.logger.error(`Error processing single job ${jobId}:`, error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Health check endpoint for monitoring batch processing
 */
exports.batchProcessorHealth = functions.https.onRequest(async (req, res) => {
  try {
    const stats = await getBatchProcessingStats();
    
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      stats: stats,
    });
  } catch (error) {
    functions.logger.error('Health check failed:', error);
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * Gets batch processing statistics
 */
async function getBatchProcessingStats() {
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  const recentJobs = await db.collection('ai_jobs')
    .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
    .get();

  const stats = {
    total: recentJobs.size,
    pending: 0,
    queued: 0,
    processing: 0,
    completed: 0,
    failed: 0,
  };

  recentJobs.forEach(doc => {
    const status = doc.data().status;
    if (stats.hasOwnProperty(status)) {
      stats[status]++;
    }
  });

  stats.successRate = stats.total > 0 ? 
    ((stats.completed / stats.total) * 100).toFixed(2) : '0.00';

  return stats;
} 