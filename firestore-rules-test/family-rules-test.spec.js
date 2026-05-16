/**
 * Family, Invitation, and Shared Classification Firestore Rules Tests
 *
 * Standalone test file with its own lifecycle.
 *
 * Run: cd firestore-rules-test && npm run test:family
 * Or:  firebase emulators:exec --only firestore 'npx mocha --exit family-rules-test.spec.js'
 */

const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'waste-seg-rules-test';
const rulesPath = path.resolve(__dirname, '../firestore.rules');

let testEnv;

// --- Families ---
const validFamily = {
  id: 'family-1',
  name: 'Test Family',
  description: 'A test family',
  createdBy: 'user-1',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  members: [{ userId: 'user-1', role: 'admin', joinedAt: new Date().toISOString(), individualStats: { totalPoints: 0, totalClassifications: 0, currentStreak: 0, bestStreak: 0 } }],
  settings: { isPublic: false, allowMemberInvites: true, leaderboardVisibility: 'membersOnly' },
  isPublic: false,
};

// --- Invitations ---
const validInvitation = {
  id: 'inv-1',
  familyId: 'family-1',
  familyName: 'Test Family',
  inviterUserId: 'user-1',
  inviterName: 'Test User',
  invitedEmail: 'invitee@example.com',
  invitedUserId: null,
  status: 'pending',
  roleToAssign: 'member',
  method: 'email',
  createdAt: new Date().toISOString(),
  expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  respondedAt: null,
};

// --- Shared Classifications ---
const validSharedClassification = {
  id: 'shared-1',
  classification: { itemName: 'Plastic Bottle', category: 'Dry Waste', subCategory: 'Recyclable' },
  sharedBy: 'user-1',
  sharedByDisplayName: 'Test User',
  sharedByPhotoUrl: null,
  sharedAt: new Date().toISOString(),
  familyId: 'family-1',
  reactions: [],
  comments: [],
  isVisible: true,
  familyTags: [],
};

describe('Family rules', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
    });
  });

  after(async () => {
    if (testEnv) { await testEnv.cleanup(); }
  });

  afterEach(async () => {
    await testEnv.clearFirestore();
  });

  // --- Families create ---
  it('authenticated user can create a family', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('families').doc('family-1').set(validFamily)
    );
  });

  it('unauthenticated user cannot create a family', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('families').doc('family-2').set(validFamily)
    );
  });

  it('family create fails with missing required fields', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('families').doc('family-bad').set({ name: 'No creator' })
    );
  });

  it('family create fails with unknown unsafe field', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('families').doc('family-unsafe').set({ ...validFamily, maliciousField: 'bad' })
    );
  });

  it('family creator can update family', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('families').doc('family-1').set(validFamily);
    await assertSucceeds(
      db.collection('families').doc('family-1').update({ name: 'Updated Family' })
    );
  });

  it('family update cannot change createdBy', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('families').doc('family-1').set(validFamily);
    await assertFails(
      db.collection('families').doc('family-1').update({ createdBy: 'user-2' })
    );
  });

  it('family creator can delete family', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('families').doc('family-1').set(validFamily);
    await assertSucceeds(
      db.collection('families').doc('family-1').delete()
    );
  });

  it('non-creator cannot delete family', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('families').doc('family-1').set(validFamily);
    const db2 = testEnv.authenticatedContext('user-2').firestore();
    await assertFails(
      db2.collection('families').doc('family-1').delete()
    );
  });

  // --- Invitations create ---
  it('authenticated user can create invitation with inviterUserId matching auth', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('invitations').doc('inv-1').set(validInvitation)
    );
  });

  it('unauthenticated user cannot create invitation', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('invitations').doc('inv-2').set(validInvitation)
    );
  });

  it('invitation create fails if inviterUserId does not match auth', async () => {
    const db = testEnv.authenticatedContext('user-2').firestore();
    await assertFails(
      db.collection('invitations').doc('inv-3').set({ ...validInvitation, inviterUserId: 'user-1' })
    );
  });

  it('invitation create fails with missing required fields', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('invitations').doc('inv-bad').set({ familyId: 'f1', status: 'pending' })
    );
  });

  it('invitation create fails with unknown unsafe field', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('invitations').doc('inv-unsafe').set({ ...validInvitation, maliciousField: 'bad' })
    );
  });

  it('invitation create fails with invalid status', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('invitations').doc('inv-bad-status').set({ ...validInvitation, status: 'unknown_status' })
    );
  });

  // --- Invitations update ---
  it('inviter can update invitation', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('invitations').doc('inv-1').set(validInvitation);
    await assertSucceeds(
      db.collection('invitations').doc('inv-1').update({ status: 'accepted', respondedAt: new Date().toISOString() })
    );
  });

  it('invitation update cannot change inviterUserId', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('invitations').doc('inv-1').set(validInvitation);
    await assertFails(
      db.collection('invitations').doc('inv-1').update({ inviterUserId: 'user-2' })
    );
  });

  it('invitation update cannot change familyId', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('invitations').doc('inv-1').set(validInvitation);
    await assertFails(
      db.collection('invitations').doc('inv-1').update({ familyId: 'different-family' })
    );
  });

  // --- Invitations delete ---
  it('inviter can delete invitation', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('invitations').doc('inv-1').set(validInvitation);
    await assertSucceeds(
      db.collection('invitations').doc('inv-1').delete()
    );
  });

  it('unrelated user cannot delete invitation', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('invitations').doc('inv-1').set(validInvitation);
    const db2 = testEnv.authenticatedContext('user-3').firestore();
    await assertFails(
      db2.collection('invitations').doc('inv-1').delete()
    );
  });

  // --- Shared classifications create ---
  it('authenticated user can create shared classification with sharedBy matching auth', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('shared_classifications').doc('shared-1').set(validSharedClassification)
    );
  });

  it('shared classification create fails if sharedBy does not match auth', async () => {
    const db = testEnv.authenticatedContext('user-2').firestore();
    await assertFails(
      db.collection('shared_classifications').doc('shared-2').set({ ...validSharedClassification, sharedBy: 'user-1' })
    );
  });

  it('shared classification create fails with missing required fields', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('shared_classifications').doc('shared-bad').set({ sharedBy: 'user-1', familyId: 'f1' })
    );
  });

  it('shared classification create fails with unknown unsafe field', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('shared_classifications').doc('shared-unsafe').set({ ...validSharedClassification, maliciousField: 'bad' })
    );
  });

  // --- Shared classifications update (reactions/comments) ---
  it('authenticated user can update shared classification (add reaction)', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('shared_classifications').doc('shared-1').set(validSharedClassification);
    const db2 = testEnv.authenticatedContext('user-2').firestore();
    await assertSucceeds(
      db2.collection('shared_classifications').doc('shared-1').update({
        reactions: [{ userId: 'user-2', displayName: 'User 2', type: 'like', timestamp: new Date().toISOString() }]
      })
    );
  });

  it('shared classification update cannot change sharedBy', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('shared_classifications').doc('shared-1').set(validSharedClassification);
    await assertFails(
      db.collection('shared_classifications').doc('shared-1').update({ sharedBy: 'user-2' })
    );
  });

  it('shared classification update cannot change familyId', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('shared_classifications').doc('shared-1').set(validSharedClassification);
    await assertFails(
      db.collection('shared_classifications').doc('shared-1').update({ familyId: 'different-family' })
    );
  });

  // --- Shared classifications delete ---
  it('sharedBy user can delete shared classification', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('shared_classifications').doc('shared-1').set(validSharedClassification);
    await assertSucceeds(
      db.collection('shared_classifications').doc('shared-1').delete()
    );
  });

  it('non-sharer cannot delete shared classification', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await db.collection('shared_classifications').doc('shared-1').set(validSharedClassification);
    const db2 = testEnv.authenticatedContext('user-2').firestore();
    await assertFails(
      db2.collection('shared_classifications').doc('shared-1').delete()
    );
  });

  // --- Family stats ---
  it('authenticated user can read family stats', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    // Create stats doc first (admin context)
    const adminDb = testEnv.authenticatedContext('admin').firestore();
    await adminDb.collection('family_stats').doc('family-1').set({ totalClassifications: 0, totalPoints: 0 });
    await assertSucceeds(
      db.collection('family_stats').doc('family-1').get()
    );
  });

  it('authenticated user can write family stats', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('family_stats').doc('family-1').set({
        totalClassifications: 1,
        totalPoints: 10,
        memberCount: 2,
        currentStreak: 1,
        categoryCounts: {},
        lastUpdated: new Date().toISOString(),
      })
    );
  });

  it('unauthenticated user cannot write family stats', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('family_stats').doc('family-1').set({ totalClassifications: 0 })
    );
  });
});
