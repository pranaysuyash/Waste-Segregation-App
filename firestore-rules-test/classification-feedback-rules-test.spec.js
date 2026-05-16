/**
 * Classification Feedback Firestore Rules Tests
 *
 * Standalone test file with its own lifecycle to avoid env cleanup issues
 * when running alongside the main rules test suite.
 *
 * Run: cd firestore-rules-test && npm test
 * Or:  firebase emulators:exec --only firestore 'npx mocha --exit classification-feedback-rules-test.spec.js'
 */

const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'waste-seg-rules-test';
const rulesPath = path.resolve(__dirname, '../firestore.rules');

let testEnv;

// Minimal valid feedback payload matching ClassificationFeedback.toJson()
const validFeedback = {
  userId: 'user-1',
  originalClassificationId: 'class-1',
  originalAIItemName: 'Plastic Bottle',
  originalAICategory: 'Dry Waste',
  userSuggestedCategory: 'Wet Waste',
  feedbackTimestamp: new Date(),
  reviewStatus: 'pending_review',
  appVersion: '0.1.0',
};

describe('classification_feedback rules', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  afterEach(async () => {
    await testEnv.clearFirestore();
  });

  // --- Create ---

  it('authenticated owner can create classification_feedback', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('classification_feedback').doc('feedback_user-1_class-1').set(validFeedback)
    );
  });

  it('unauthenticated user cannot create classification_feedback', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('classification_feedback').doc('feedback_user-1_class-1').set(validFeedback)
    );
  });

  it('create fails when userId does not match auth.uid', async () => {
    const db = testEnv.authenticatedContext('user-2').firestore();
    await assertFails(
      db.collection('classification_feedback').doc('feedback_user-2_class-1').set({
        ...validFeedback,
        userId: 'user-1', // different from auth.uid 'user-2'
      })
    );
  });

  it('create fails when required fields are missing', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();

    // Missing originalClassificationId
    await assertFails(
      db.collection('classification_feedback').doc('fb-missing-1').set({
        userId: 'user-1',
        userSuggestedCategory: 'Wet Waste',
        feedbackTimestamp: new Date(),
        reviewStatus: 'pending_review',
        appVersion: '0.1.0',
      })
    );

    // Missing userSuggestedCategory
    await assertFails(
      db.collection('classification_feedback').doc('fb-missing-2').set({
        userId: 'user-1',
        originalClassificationId: 'class-1',
        originalAIItemName: 'Plastic Bottle',
        originalAICategory: 'Dry Waste',
        feedbackTimestamp: new Date(),
        reviewStatus: 'pending_review',
        appVersion: '0.1.0',
      })
    );

    // Missing reviewStatus
    await assertFails(
      db.collection('classification_feedback').doc('fb-missing-3').set({
        userId: 'user-1',
        originalClassificationId: 'class-1',
        originalAIItemName: 'Plastic Bottle',
        originalAICategory: 'Dry Waste',
        userSuggestedCategory: 'Wet Waste',
        feedbackTimestamp: new Date(),
        appVersion: '0.1.0',
      })
    );

    // Missing appVersion
    await assertFails(
      db.collection('classification_feedback').doc('fb-missing-4').set({
        userId: 'user-1',
        originalClassificationId: 'class-1',
        originalAIItemName: 'Plastic Bottle',
        originalAICategory: 'Dry Waste',
        userSuggestedCategory: 'Wet Waste',
        feedbackTimestamp: new Date(),
        reviewStatus: 'pending_review',
      })
    );
  });

  it('create fails with unknown unsafe field', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('classification_feedback').doc('fb-unsafe-1').set({
        ...validFeedback,
        maliciousField: 'should be rejected',
      })
    );
  });

  // --- Read ---

  it('owner can read their own feedback', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('classification_feedback').doc('fb-read-1').set(validFeedback);
    await assertSucceeds(
      db.collection('classification_feedback').doc('fb-read-1').get()
    );
  });

  it('another user cannot read feedback', async () => {
    const dbOwner = testEnv.authenticatedContext('user-1').firestore();
    await dbOwner.collection('classification_feedback').doc('fb-read-2').set(validFeedback);
    const dbOther = testEnv.authenticatedContext('user-2').firestore();
    await assertFails(
      dbOther.collection('classification_feedback').doc('fb-read-2').get()
    );
  });

  // --- Valid shapes ---

  it('valid correction feedback with optional fields succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('classification_feedback').doc('feedback_user-1_class-1_corr').set({
        ...validFeedback,
        originalAIMaterial: 'Plastic',
        originalAIConfidence: 0.92,
        userSuggestedItemName: 'Plastic Container',
        userSuggestedMaterial: 'Recyclable Plastic',
        userNotes: 'This was wet, not dry',
      })
    );
  });

  it('valid confirmation feedback succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('classification_feedback').doc('feedback_user-1_class-1_conf').set({
        ...validFeedback,
        userSuggestedCategory: 'Dry Waste', // same as original = confirmation
      })
    );
  });

  // --- Delete ---

  it('delete is always denied', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('classification_feedback').doc('fb-del-1').set(validFeedback);
    await assertFails(
      db.collection('classification_feedback').doc('fb-del-1').delete()
    );
  });

  // --- Update ---

  it('owner can update their own feedback', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('classification_feedback').doc('fb-upd-1').set(validFeedback);
    await assertSucceeds(
      db.collection('classification_feedback').doc('fb-upd-1').update({
        userNotes: 'Updated notes',
        reviewStatus: 'approved',
      })
    );
  });

  it('update fails when userId does not match auth.uid', async () => {
    const dbOwner = testEnv.authenticatedContext('user-1').firestore();
    await dbOwner.collection('classification_feedback').doc('fb-upd-2').set(validFeedback);
    const dbOther = testEnv.authenticatedContext('user-2').firestore();
    await assertFails(
      dbOther.collection('classification_feedback').doc('fb-upd-2').update({
        userNotes: 'Hacked notes',
      })
    );
  });
});
