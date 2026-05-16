/**
 * Firestore Rules Unit Tests for Waste Segregation App
 *
 * Tests prove that real app write shapes are accepted
 * and stale/unsafe shapes are rejected.
 *
 * Run: npm test (requires Firestore emulator running)
 * Or:  npm run test:emulator (starts emulator automatically)
 */

const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'waste-seg-rules-test';

// Load rules from project root
const rulesPath = path.resolve(__dirname, '../firestore.rules');

let testEnv;
let adminDb;

// Test data matching actual CommunityFeedItem.toJson() output
const communityFeedItem = {
  id: 'feed-1',
  userId: 'user-1',
  userName: 'Test User',
  userAvatar: 'https://example.com/photo.jpg',
  activityType: 'classification',
  title: 'Test Title',
  description: 'Test Description',
  timestamp: new Date(),
  metadata: { category: 'plastic', confidence: 0.9 },
  likes: 0,
  likedBy: [],
  isAnonymous: false,
  points: 10,
};

const leaderboardEntry = {
  userId: 'user-1',
  displayName: 'Test User',
  photoUrl: 'https://example.com/photo.jpg',
  points: 100,
  lastUpdated: new Date(),
};

const familyData = {
  id: 'family-1',
  name: 'Test Family',
  description: 'A test family',
  createdBy: 'user-1',
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  members: [{ userId: 'user-1', role: 'admin', displayName: 'Test User' }],
  settings: { isPublic: false },
  isPublic: false,
};

const invitationData = {
  id: 'inv-1',
  familyId: 'family-1',
  familyName: 'Test Family',
  inviterUserId: 'user-1',
  inviterName: 'Test User',
  invitedEmail: 'test@example.com',
  status: 'pending',
  roleToAssign: 'member',
  method: 'email',
  createdAt: new Date().toISOString(),
  expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
};

const sharedClassificationData = {
  id: 'sc-1',
  classification: { category: 'plastic', itemName: 'Bottle' },
  sharedBy: 'user-1',
  sharedByDisplayName: 'Test User',
  sharedAt: new Date().toISOString(),
  familyId: 'family-1',
  isVisible: true,
  reactions: [],
  comments: [],
  familyTags: [],
};

describe('Firestore Rules Tests', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
    });
    adminDb = testEnv.authenticatedContext('admin').firestore();
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  afterEach(async () => {
    await testEnv.clearFirestore();
  });

  // ============================================================
  // 1. Community feed create with actual model fields succeeds
  // ============================================================
  it('community_feed create with CommunityFeedItem fields succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('community_feed').doc('post-1').set({
        ...communityFeedItem,
        userId: 'user-1',
        timestamp: new Date(),
      })
    );
  });

  // ============================================================
  // 2. Community feed create with old stale schema shape fails
  // ============================================================
  it('community_feed create with old stale schema (content/type) fails', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('community_feed').doc('post-stale').set({
        userId: 'user-1',
        content: 'Test content',
        type: 'classification',
        timestamp: new Date(),
      })
    );
  });

  // ============================================================
  // 3. Community feed create with ISO String timestamp fails
  // ============================================================
  it('community_feed create with ISO String timestamp fails', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('community_feed').doc('post-ts-string').set({
        ...communityFeedItem,
        userId: 'user-1',
        timestamp: '2026-05-16T12:00:00Z',
      })
    );
  });

  // ============================================================
  // 4. Community feed create with Firestore Timestamp succeeds
  // ============================================================
  it('community_feed create with Firestore Timestamp succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('community_feed').doc('post-ts-timestamp').set({
        ...communityFeedItem,
        userId: 'user-1',
        timestamp: new Date(),
      })
    );
  });

  // ============================================================
  // 5. Anonymous community feed still requires userId matching auth
  // ============================================================
  it('community_feed create without userId fails even if isAnonymous', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('community_feed').doc('anon-no-user').set({
        id: 'anon-1',
        activityType: 'classification',
        title: 'Anonymous Post',
        description: 'No user',
        timestamp: new Date(),
        isAnonymous: true,
        points: 0,
      })
    );
  });

  // ============================================================
  // 6. Leaderboard write with photoUrl succeeds
  // ============================================================
  it('leaderboard_allTime write with photoUrl succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('leaderboard_allTime').doc('user-1').set(leaderboardEntry)
    );
  });

  // ============================================================
  // 7. Leaderboard write with unknown extra field fails
  // ============================================================
  it('leaderboard_allTime write with unknown extra field fails', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('leaderboard_allTime').doc('user-1-extra').set({
        ...leaderboardEntry,
        unknownField: 'should fail',
      })
    );
  });

  // ============================================================
  // 8. Leaderboard write where auth uid does not match userId fails
  // ============================================================
  it('leaderboard_allTime write where auth.uid != userId fails', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      db.collection('leaderboard_allTime').doc('user-2').set({
        ...leaderboardEntry,
        userId: 'user-2',
      })
    );
  });

  // ============================================================
  // 9. Families create with required fields succeeds
  // ============================================================
  it('families create with required fields succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('families').doc('family-1').set(familyData)
    );
  });

  // ============================================================
  // 10. Invitations create with required fields succeeds
  // ============================================================
  it('invitations create with required fields succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('invitations').doc('inv-1').set(invitationData)
    );
  });

  // ============================================================
  // 10b. Shared classifications create succeeds
  // ============================================================
  it('shared_classifications create with required fields succeeds', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      db.collection('shared_classifications').doc('sc-1').set(sharedClassificationData)
    );
  });

  // ============================================================
  // 11. Protected collections deny unauthenticated writes
  // ============================================================
  it('unauthenticated user cannot write to users collection', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('users').doc('user-1').set({ displayName: 'Hacker' })
    );
  });

  it('unauthenticated user cannot read community_feed', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('community_feed').get()
    );
  });

  it('unauthenticated user cannot write to leaderboard_allTime', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('leaderboard_allTime').doc('user-1').set(leaderboardEntry)
    );
  });

  it('unauthenticated user cannot write to families', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('families').doc('family-1').set(familyData)
    );
  });

  it('unauthenticated user cannot write to invitations', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('invitations').doc('inv-1').set(invitationData)
    );
  });

  it('unauthenticated user cannot write to shared_classifications', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('shared_classifications').doc('sc-1').set(sharedClassificationData)
    );
  });

  // ============================================================
  // 11b. Community stats is read-only for users
  // ============================================================
  it('community_stats is read-only for authenticated users', async () => {
    const db = testEnv.authenticatedContext('user-1').firestore();
    // Read should succeed
    await assertSucceeds(
      db.collection('community_stats').doc('main').get()
    );
    // Write should fail
    await assertFails(
      db.collection('community_stats').doc('main').set({
        totalUsers: 100,
        totalClassifications: 500,
        totalPoints: 5000,
        lastUpdated: new Date(),
      })
    );
  });
});
