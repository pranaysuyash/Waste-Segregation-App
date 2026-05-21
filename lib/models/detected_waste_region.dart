import 'dart:math';
import 'package:uuid/uuid.dart';
import 'waste_classification.dart';

class DetectedWasteRegion {
  DetectedWasteRegion({
    String? id,
    required this.boundingBox,
    this.cropPath,
    this.cropBytes,
    this.classification,
    this.confidence,
    this.userConfirmed = false,
    this.label,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final NormalizedBoundingBox boundingBox;
  String? cropPath;
  List<int>? cropBytes;
  WasteClassification? classification;
  double? confidence;
  bool userConfirmed;
  String? label;

  DetectedWasteRegion copyWith({
    String? id,
    NormalizedBoundingBox? boundingBox,
    String? cropPath,
    List<int>? cropBytes,
    WasteClassification? classification,
    double? confidence,
    bool? userConfirmed,
    String? label,
  }) {
    return DetectedWasteRegion(
      id: id ?? this.id,
      boundingBox: boundingBox ?? this.boundingBox,
      cropPath: cropPath ?? this.cropPath,
      cropBytes: cropBytes ?? this.cropBytes,
      classification: classification ?? this.classification,
      confidence: confidence ?? this.confidence,
      userConfirmed: userConfirmed ?? this.userConfirmed,
      label: label ?? this.label,
    );
  }

  factory DetectedWasteRegion.fromJson(Map<String, dynamic> json) =>
      DetectedWasteRegion(
        id: json['id'],
        boundingBox:
            NormalizedBoundingBox.fromJson(json['boundingBox']),
        cropPath: json['cropPath'],
        cropBytes: json['hasCropBytes'] == true ? [] : null,
        classification: json['classification'] != null
            ? WasteClassification.fromJson(json['classification'])
            : null,
        confidence: (json['confidence'] as num?)?.toDouble(),
        userConfirmed: json['userConfirmed'] ?? false,
        label: json['label'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'boundingBox': boundingBox.toJson(),
    'cropPath': cropPath,
    'hasCropBytes': cropBytes != null,
    'classification': classification?.toJson(),
    'confidence': confidence,
    'userConfirmed': userConfirmed,
    'label': label,
  };
}

class NormalizedBoundingBox {
  NormalizedBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory NormalizedBoundingBox.fromJson(Map<String, dynamic> json) =>
      NormalizedBoundingBox(
        left: (json['left'] as num).toDouble(),
        top: (json['top'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => (left + width).clamp(0.0, 1.0);
  double get bottom => (top + height).clamp(0.0, 1.0);
  double get area => width * height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  NormalizedBoundingBox copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) =>
      NormalizedBoundingBox(
        left: left ?? this.left,
        top: top ?? this.top,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  double intersectionOverUnion(NormalizedBoundingBox other) {
    final interLeft = max(left, other.left);
    final interTop = max(top, other.top);
    final interRight = min(right, other.right);
    final interBottom = min(bottom, other.bottom);

    if (interLeft >= interRight || interTop >= interBottom) return 0.0;

    final interArea =
        (interRight - interLeft) * (interBottom - interTop);
    final unionArea = area + other.area - interArea;
    return unionArea > 0 ? interArea / unionArea : 0.0;
  }

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };
}

enum RegionDetectionSource {
  manual,
  automaticModel,
  gridOverlay,
  segmentationModel,
}
