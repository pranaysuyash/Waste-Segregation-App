import 'package:path/path.dart' as p;

String sanitizeFileName(String input, {String fallback = 'file'}) {
  final baseName = p.basename(input.trim());
  final sanitized = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
    return fallback;
  }
  return sanitized;
}

String safeJoinWithin(String baseDir, String untrustedPath) {
  final sanitizedRelative = untrustedPath
      .replaceAll('\\', '/')
      .split('/')
      .where(
          (segment) => segment.isNotEmpty && segment != '.' && segment != '..')
      .map((segment) => sanitizeFileName(segment, fallback: 'segment'))
      .join('/');

  final normalizedBase = p.normalize(baseDir);
  final candidate = p.normalize(p.join(normalizedBase, sanitizedRelative));
  final basePrefix = normalizedBase.endsWith(p.separator)
      ? normalizedBase
      : '$normalizedBase${p.separator}';

  if (candidate == normalizedBase || candidate.startsWith(basePrefix)) {
    return candidate;
  }

  throw ArgumentError('Unsafe path outside allowed base directory');
}
