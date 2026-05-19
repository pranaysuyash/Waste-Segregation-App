enum AiFailureKind {
  cancelled,
  invalidImage,
  invalidImageTooLarge,
  auth,
  rateLimited,
  budgetExceeded,
  providerUnavailable,
  malformedProviderResponse,
  unsafeClientAiBlocked,
  network,
  unknown,
}

class AiFailure implements Exception {
  AiFailure(
    this.kind,
    this.message, {
    this.provider,
    this.model,
    this.cause,
  });

  final AiFailureKind kind;
  final String message;
  final String? provider;
  final String? model;
  final Object? cause;

  @override
  String toString() => 'AiFailure(kind: $kind, message: $message)';
}
