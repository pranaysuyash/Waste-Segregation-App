# Closed Beta Smoke Checklist

## Fresh Install

- [ ] Install APK on real device (Android 10+)
- [ ] Launch app
- [ ] Permission prompts appear (camera, storage)
- [ ] Guest mode / anonymous classification works
- [ ] Sign-in / sign-up flow works
- [ ] App does not crash on cold start

## Core Classification Loop

- [ ] Open camera from home screen
- [ ] Capture image of waste item
- [ ] Classification result screen loads
- [ ] Disposal instructions visible
- [ ] Points awarded and shown
- [ ] Classification saved to history
- [ ] Reclassify / correction flow works

## Feedback Pipeline

- [ ] Thumbs-up (confirmation) works
- [ ] Correction (thumbs-down) works
- [ ] Correction dialog shows categories
- [ ] Duplicate feedback does not award duplicate points
- [ ] Feedback doc in Firestore matches expected shape
- [ ] Dedup key prevents duplicate records

## Family Features

- [ ] Create a new family
- [ ] Family `memberUids` contains creator
- [ ] Invite a second user by email
- [ ] Second user accepts invitation
- [ ] Family stats visible to member
- [ ] Non-member cannot read `membersOnly` family stats
- [ ] Change `leaderboardVisibility` to `public`
- [ ] Verify non-member can now read `public` family stats
- [ ] Change `leaderboardVisibility` back to `membersOnly`
- [ ] Verify non-member read is denied again

## Data Persistence

- [ ] Local (Hive) data persists after app restart
- [ ] Cloud sync works for signed-in user
- [ ] Fresh start / data reset clears local state
- [ ] No ghost data after reset

## Failure Paths

- [ ] No internet: app shows graceful error, does not crash
- [ ] Poor/blurry image: classification handles gracefully
- [ ] API timeout: retry or clear error message
- [ ] Firestore write failure: local data not lost
- [ ] App kill mid-classification: no corruption on restart

## Privacy & Security

- [ ] Firestore rules block unauthenticated writes
- [ ] Non-member cannot write family stats
- [ ] Non-member cannot read membersOnly stats
- [ ] Leaderboard respects opt-out preference
- [ ] PII fields (email, phone) not leaked in public collections

## Observability

- [ ] Crash logs captured (Firebase Crashlytics or equivalent)
- [ ] Analytics events fire on classification, feedback, family actions
- [ ] No PII in debug/log output
- [ ] Error handler shows user-friendly messages, not stack traces in release
