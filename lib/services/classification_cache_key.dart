class ClassificationCacheKey {
  ClassificationCacheKey._();

  static String build({
    required String imageHash,
    required String region,
    required String language,
    required String promptVersion,
    required String schemaVersion,
    required String localGuidelinesVersion,
    required String provider,
    required String model,
  }) {
    return [
      imageHash,
      region.trim().toLowerCase(),
      language.trim().toLowerCase(),
      promptVersion.trim(),
      schemaVersion.trim(),
      localGuidelinesVersion.trim(),
      provider.trim().toLowerCase(),
      model.trim(),
    ].join('::');
  }
}
