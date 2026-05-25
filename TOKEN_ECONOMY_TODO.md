# Token Economy Phase 2-6 Implementation TODO

**Status Update**: Phase 4 complete (HMAC, backup/restore, audit logging). Phase 5: Remote Config pricing, cost guardrails, freemium gating, and daily scan limit enforcement are done. Gaps: cross-device sync is one-way push (not bidirectional), token purchase storefront not built, batch processing returns placeholder results (OpenAI Batch API not integrated). Phase 6: TokenService and WalletEncryption unit tests exist and pass; integration, performance, security, and UAT tests still needed.

## Phase 4: Security & Infrastructure
- [x] Implement Firestore security rules for wallet data protection
- [x] Add wallet data integrity verification (HMAC-SHA256) — `lib/utils/wallet_encryption.dart`
- [x] Create token transaction audit logging
- [x] Add wallet backup (export) and restore (import) — `lib/screens/token_wallet_screen.dart`
- [~] Add cross-device wallet synchronization (one-way push to Firestore exists; bidirectional pull-on-login + conflict resolution not implemented)

## Phase 5: Cost Management & Analytics
- [x] Implement Remote Config for dynamic pricing — `lib/services/dynamic_pricing_service.dart`
- [x] Add cost guardrails and budget monitoring — `lib/services/cost_guardrail_service.dart`
- [x] Create usage analytics and cost reporting — `lib/services/cost_tracking_interceptor.dart` + `lib/services/ai_cost_tracker.dart`
- [x] Implement freemium feature gating — `lib/services/premium_service.dart` with feature flag checks
- [x] Enforce `freeDailyScanLimit` (gated in `image_capture_screen.dart:824-834` via `PremiumService.canPerformScan()`, tracked in local Hive with daily reset)
- [ ] Add token purchase/earn incentives UI (storefront for buying tokens, earn-through-engagement prompts)

## Phase 6: Testing & Optimization
- [x] Add comprehensive unit tests for TokenService (earn, spend, convert, restoreWallet) — `test/services/token_service_test.dart` (12 tests, all passing)
- [x] Add unit tests for WalletEncryption integrity verification — `test/utils/wallet_encryption_test.dart` (8 tests, all passing)
- [ ] Implement integration tests for wallet operations
- [ ] Performance testing for high-volume token transactions
- [ ] Security testing for wallet data protection (verify HMAC detects tampering)
- [ ] User acceptance testing for token economy flows

## Success Metrics
- [ ] 40-50% reduction in OpenAI API costs
- [ ] >80% user adoption of batch mode
- [ ] Positive user feedback on token system
- [ ] Secure wallet data with zero breaches
- [ ] Smooth integration with existing AI workflows
