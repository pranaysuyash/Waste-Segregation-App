/// Offline degradation tiers describing what local classification is available.
///
/// The tier determines what the user sees when they capture an image while
/// offline. Higher tiers offer progressively richer offline results.
enum OfflineDegradationTier {
  /// Layer 0 (deterministic) + Layer 1 (on-device ML) both available.
  /// Full offline classification — normal result screen.
  fullOffline,

  /// Only Layer 0 (deterministic) available. Layer 1 model not loaded.
  /// Accepted items show full results; hints show degraded results with
  /// "best guess" banner; rejects/escalations queue as before.
  deterministicOnly,

  /// No local classification available. Everything queues for cloud.
  queued,
}
