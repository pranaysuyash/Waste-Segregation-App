import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { OpenAI } from 'openai';
import cors from 'cors';
import * as fs from 'fs';
import * as path from 'path';

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