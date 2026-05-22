# Token Economy Phase 2-6 Implementation TODO

**Status Update**: ✅ All P0-P2 items complete. Wallet integrity (HMAC) and backup/restore implemented. Most Phase 5 items are already implemented in code (Remote Config pricing, cost guardrails). Remaining items are Phase 6 testing and the freemium daily scan limit enforcement.

## Phase 4: Security & Infrastructure
- [x] Implement Firestore security rules for wallet data protection
- [x] Add wallet data integrity verification (HMAC-SHA256) — `lib/utils/wallet_encryption.dart`
- [x] Create token transaction audit logging
- [x] Add wallet backup (export) and restore (import) — `lib/screens/token_wallet_screen.dart`
- [x] Add cross-device wallet synchronization

## Phase 5: Cost Management & Analytics
- [x] Implement Remote Config for dynamic pricing — `lib/services/dynamic_pricing_service.dart`
- [x] Add cost guardrails and budget monitoring — `lib/services/cost_guardrail_service.dart`
- [x] Create usage analytics and cost reporting — `lib/services/cost_tracking_interceptor.dart` + `lib/services/ai_cost_tracker.dart`
- [x] Implement freemium feature gating — `lib/services/premium_service.dart` with feature flag checks
- [ ] Enforce `freeDailyScanLimit` (value exists in Remote Config at `monetization.free_daily_scan_limit`, not yet gating scans in `image_capture_screen.dart`)
- [ ] Add token purchase/earn incentives UI (storefront for buying tokens, earn-through-engagement prompts)

## Phase 6: Testing & Optimization
- [ ] Add comprehensive unit tests for TokenService (earn, spend, convert, restoreWallet)
- [ ] Add unit tests for WalletEncryption integrity verification
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
