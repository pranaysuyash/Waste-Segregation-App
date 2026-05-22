/**
 * Firebase Storage security rules tests
 *
 * Run:
 *   cd firestore-rules-test && npm run test:storage:emulator
 */

const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { ref, uploadString, listAll, getDownloadURL } = require('firebase/storage');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'waste-seg-rules-test';
const rulesPath = path.resolve(__dirname, '../storage.rules');

let testEnv;

function userStorage(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

function anonStorage() {
  return testEnv.unauthenticatedContext().storage();
}

describe('Storage rules', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      storage: { rules: fs.readFileSync(rulesPath, 'utf8') },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  it('allows authenticated owner to upload batch image under own UID path', async () => {
    const storage = userStorage('user-1');
    const uploadRef = ref(storage, `batch_images/user-1/test-${Date.now()}.jpg`);

    await assertSucceeds(uploadString(uploadRef, 'mock-image-data'));
  });

  it('rejects authenticated user upload to another user batch path', async () => {
    const storage = userStorage('user-1');
    const uploadRef = ref(storage, `batch_images/user-2/test-${Date.now()}.jpg`);

    await assertFails(uploadString(uploadRef, 'mock-image-data'));
  });

  it('rejects unauthenticated batch upload', async () => {
    const storage = anonStorage();
    const uploadRef = ref(storage, `batch_images/user-1/test-${Date.now()}.jpg`);

    await assertFails(uploadString(uploadRef, 'mock-image-data'));
  });

  it('allows owner to list own contribution photos and blocks cross-user listing', async () => {
    // Seed one file for each user with rules disabled.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminStorage = context.storage();
      await uploadString(ref(adminStorage, `contribution_photos/user-1/seed-${Date.now()}.jpg`), 'seed-1');
      await uploadString(ref(adminStorage, `contribution_photos/user-2/seed-${Date.now()}.jpg`), 'seed-2');
    });

    const storageUser1 = userStorage('user-1');

    await assertSucceeds(
      listAll(ref(storageUser1, 'contribution_photos/user-1')),
    );

    await assertFails(
      listAll(ref(storageUser1, 'contribution_photos/user-2')),
    );
  });

  it('rejects reads/writes to non-whitelisted paths', async () => {
    const storage = userStorage('user-1');
    const blockedRef = ref(storage, `misc/user-1/test-${Date.now()}.txt`);

    await assertFails(uploadString(blockedRef, 'blocked'));
    await assertFails(getDownloadURL(blockedRef));
  });
});
