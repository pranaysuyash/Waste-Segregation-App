import '../services/ai_failure.dart';

class AiErrorMessages {
  AiErrorMessages._();

  static String toUserMessage(Object error) {
    if (error is AiFailure) {
      switch (error.kind) {
        case AiFailureKind.cancelled:
          return 'Analysis cancelled.';
        case AiFailureKind.invalidImage:
        case AiFailureKind.invalidImageTooLarge:
          return 'We could not read this image. Try a clearer photo.';
        case AiFailureKind.network:
          return 'Network issue while analyzing. Please try again.';
        case AiFailureKind.rateLimited:
          return 'Service is busy right now. Please retry in a moment.';
        case AiFailureKind.auth:
        case AiFailureKind.unsafeClientAiBlocked:
          return 'AI service is not configured on this build.';
        case AiFailureKind.budgetExceeded:
          return 'Daily AI limit reached. Please try again later.';
        case AiFailureKind.providerUnavailable:
        case AiFailureKind.provider:
        case AiFailureKind.malformedProviderResponse:
        case AiFailureKind.unknown:
          return 'Analysis failed. Please try again.';
      }
    }

    final value = error.toString().toLowerCase();
    if (value.contains('placeholder/missing api key') ||
        value.contains('missing api key')) {
      return 'AI service is not configured on this build.';
    }
    if (value.contains('socketexception') ||
        value.contains('failed host lookup') ||
        value.contains('network')) {
      return 'Network issue while analyzing. Please try again.';
    }

    return 'Analysis failed. Please try again.';
  }
}

