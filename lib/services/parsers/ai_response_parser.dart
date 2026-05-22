import 'dart:convert';

import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class AiResponseParser {
  AiResponseParser._();

  static WasteClassification processResponse(
    Map<String, dynamic> responseData,
    String imagePath,
    String region,
    String? instructionsLang,
    List<String>? reanalysisModelsTried,
    String? classificationId, {
    required String provider,
    required String model,
    String? thumbnailPath,
  }) {
    try {
      if (responseData['choices'] != null &&
          responseData['choices'].isNotEmpty) {
        final choice = responseData['choices'][0];
        if (choice['message'] != null && choice['message']['content'] != null) {
          final String content = choice['message']['content'];

          final jsonString = cleanJsonString(content);

          Map<String, dynamic> jsonContent;
          try {
            jsonContent = jsonDecode(jsonString);

            return _createClassificationFromJsonContent(
              jsonContent,
              imagePath,
              region,
              instructionsLang,
              reanalysisModelsTried,
              classificationId,
              provider: provider,
              model: model,
              thumbnailPath: thumbnailPath,
            );
          } catch (jsonError) {
            WasteAppLogger.severe(
              'Failed to decode provider response JSON',
              error: jsonError,
              context: {
                'provider': provider,
                'model': model,
                'classification_id': classificationId,
              },
            );

            return _createFallbackClassification(
              content,
              imagePath,
              region,
              provider: provider,
              model: model,
              classificationId: classificationId,
            );
          }
        }
      }
    } catch (e, s) {
      WasteAppLogger.severe('AI response processing failed',
          error: e,
          stackTrace: s,
          context: {
            'provider': provider,
            'model': model,
            'classification_id': classificationId,
          });
      return WasteClassification.fallback(imagePath, id: classificationId);
    }

    WasteAppLogger.severe('Error occurred');
    return WasteClassification.fallback(imagePath, id: classificationId);
  }

  static String cleanJsonString(String rawContent) {
    final jsonCodeBlockRegExp =
        RegExp(r'```json\s*([\s\S]*?)\s*```', multiLine: true);
    final Match? match = jsonCodeBlockRegExp.firstMatch(rawContent);

    String jsonString;
    if (match != null && match.group(1) != null) {
      jsonString = match.group(1)!.trim();
    } else {
      final firstCurly = rawContent.indexOf('{');
      final lastCurly = rawContent.lastIndexOf('}');

      if (firstCurly != -1 && lastCurly != -1 && lastCurly > firstCurly) {
        jsonString = rawContent.substring(firstCurly, lastCurly + 1).trim();
      } else {
        jsonString = rawContent;
      }
    }

    jsonString = jsonString.replaceAll(RegExp(r'//.*'), '');
    jsonString = jsonString.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    return jsonString.trim();
  }

  static DisposalInstructions parseDisposalInstructions(
      dynamic jsonDisposalInstructions) {
    if (jsonDisposalInstructions == null) {
      return DisposalInstructions(
        primaryMethod: 'Review required',
        steps: ['Please review manually'],
        hasUrgentTimeframe: false,
      );
    }

    if (jsonDisposalInstructions is Map) {
      try {
        return DisposalInstructions.fromJson(
            Map<String, dynamic>.from(jsonDisposalInstructions));
      } catch (e) {
        WasteAppLogger.severe('Error occurred');
        return DisposalInstructions(
          primaryMethod:
              jsonDisposalInstructions['primaryMethod']?.toString() ??
                  'Review required',
          steps: parseStepsFromString(
              jsonDisposalInstructions['steps']?.toString() ?? ''),
          hasUrgentTimeframe: false,
        );
      }
    } else if (jsonDisposalInstructions is String) {
      return DisposalInstructions(
        primaryMethod: jsonDisposalInstructions.isNotEmpty
            ? jsonDisposalInstructions
            : 'Review required',
        steps: parseStepsFromString(jsonDisposalInstructions),
        hasUrgentTimeframe: false,
      );
    } else if (jsonDisposalInstructions is List) {
      final primaryMethod = jsonDisposalInstructions.isNotEmpty
          ? jsonDisposalInstructions[0].toString()
          : 'Review required';
      final steps = jsonDisposalInstructions.map((e) => e.toString()).toList();
      return DisposalInstructions(
        primaryMethod: primaryMethod,
        steps: steps,
        hasUrgentTimeframe: false,
      );
    }

    return DisposalInstructions(
      primaryMethod: 'Review required',
      steps: ['Please review manually'],
      hasUrgentTimeframe: false,
    );
  }

  static List<AlternativeClassification> parseAlternatives(
      dynamic alternativesJson) {
    if (alternativesJson == null) return [];
    if (alternativesJson is List) {
      return alternativesJson
          .map((alt) {
            try {
              return AlternativeClassification.fromJson(
                  alt as Map<String, dynamic>);
            } catch (e) {
              WasteAppLogger.severe('Error occurred');
              return null;
            }
          })
          .whereType<AlternativeClassification>()
          .toList();
    }
    return [];
  }

  static WasteClassification _createClassificationFromJsonContent(
    Map<String, dynamic> jsonContent,
    String imagePath,
    String region,
    String? instructionsLang,
    List<String>? reanalysisModelsTried,
    String? classificationId, {
    required String provider,
    required String model,
    String? thumbnailPath,
  }) {
    try {
      final disposalInstructions =
          parseDisposalInstructions(jsonContent['disposalInstructions']);
      final alternatives = parseAlternatives(jsonContent['alternatives']);

      var itemName = safeStringParse(jsonContent['itemName']) ?? '';

      if (itemName.isEmpty || itemName == 'null') {
        WasteAppLogger.info(
            'AI response contained empty or null itemName. Attempting extraction from other fields.',
            context: {'jsonContent': jsonContent});
        final explanation = safeStringParse(jsonContent['explanation']) ?? '';
        final subcategory = safeStringParse(jsonContent['subcategory']) ?? '';
        final category = safeStringParse(jsonContent['category']) ?? '';

        if (explanation.isNotEmpty) {
          final patterns = [
            RegExp(
                r'(?:shows?|depicts?|contains?|is)\s+(?:an?|the)?\s*([^.]+?)(?:\s+(?:which|that|in|on)|\.|$)',
                caseSensitive: false),
            RegExp(
                r'(?:This|It)\s+(?:appears to be|looks like|is)\s+(?:an?|the)?\s*([^.]+?)(?:\s+(?:which|that|in|on)|\.|$)',
                caseSensitive: false),
          ];

          for (final pattern in patterns) {
            final match = pattern.firstMatch(explanation);
            if (match != null && match.group(1) != null) {
              final extractedName = match.group(1)!.trim();
              if (extractedName.isNotEmpty && extractedName.length < 50) {
                itemName = extractedName;
                WasteAppLogger.info('Extracted itemName from explanation.',
                    context: {
                      'extractedName': itemName,
                      'explanation': explanation
                    });
                break;
              }
            }
          }
        }

        if (itemName.isEmpty && subcategory.isNotEmpty) {
          itemName = subcategory;
          WasteAppLogger.info('Falling back to subcategory for itemName.',
              context: {'subcategory': itemName});
        }

        if (itemName.isEmpty && category.isNotEmpty) {
          itemName = category;
          WasteAppLogger.info('Falling back to category for itemName.',
              context: {'category': itemName});
        }

        if (itemName.isEmpty) {
          itemName = 'Unidentified Item - Fallback';
          WasteAppLogger.warning(
              'Could not extract itemName from AI response; defaulting to "Unidentified Item - Fallback".',
              context: {'jsonContent': jsonContent});
        }
      }

      String? imageRelativePath;
      if (imagePath.contains('/images/')) {
        final index = imagePath.indexOf('/images/');
        imageRelativePath = imagePath.substring(index + 1);
      } else if (imagePath.contains('\\images\\')) {
        final index = imagePath.indexOf('\\images\\');
        imageRelativePath =
            imagePath.substring(index + 1).replaceAll('\\', '/');
      } else if (imagePath.contains('.jpg') ||
          imagePath.contains('.png') ||
          imagePath.contains('.jpeg') ||
          imagePath.contains('.webp')) {
        final fileName = imagePath.split('/').last.split('\\').last;
        imageRelativePath = 'images/$fileName';
      }

      String? thumbnailRelativePath;
      if (thumbnailPath != null) {
        if (thumbnailPath.contains('/thumbnails/')) {
          final index = thumbnailPath.indexOf('/thumbnails/');
          thumbnailRelativePath = thumbnailPath.substring(index + 1);
        } else if (thumbnailPath.contains('\\thumbnails\\')) {
          final index = thumbnailPath.indexOf('\\thumbnails\\');
          thumbnailRelativePath =
              thumbnailPath.substring(index + 1).replaceAll('\\', '/');
        } else if (thumbnailPath.contains('.jpg') ||
            thumbnailPath.contains('.png') ||
            thumbnailPath.contains('.jpeg') ||
            thumbnailPath.contains('.webp')) {
          final fileName = thumbnailPath.split('/').last.split('\\').last;
          thumbnailRelativePath = 'thumbnails/$fileName';
        }
      }

      final classification = WasteClassification(
        id: classificationId,
        itemName: itemName,
        category: safeStringParse(jsonContent['category']) ??
            'Requires Manual Review',
        subcategory: safeStringParse(jsonContent['subcategory']),
        materialType: safeStringParse(jsonContent['materialType']),
        recyclingCode: parseRecyclingCode(jsonContent['recyclingCode']),
        explanation: safeStringParse(jsonContent['explanation']) ??
            'No explanation provided',
        disposalMethod: safeStringParse(jsonContent['disposalMethod']),
        disposalInstructions: disposalInstructions,
        region: region,
        localGuidelinesReference:
            safeStringParse(jsonContent['localGuidelinesReference']),
        imageUrl: imagePath,
        imageRelativePath: imageRelativePath,
        thumbnailRelativePath: thumbnailRelativePath,
        visualFeatures: parseStringListSafely(jsonContent['visualFeatures']),
        isRecyclable: parseBool(jsonContent['isRecyclable']),
        isCompostable: parseBool(jsonContent['isCompostable']),
        requiresSpecialDisposal:
            parseBool(jsonContent['requiresSpecialDisposal']),
        isSingleUse: parseBool(jsonContent['isSingleUse']),
        colorCode: safeStringParse(jsonContent['colorCode']),
        riskLevel: safeStringParse(jsonContent['riskLevel']),
        requiredPPE: parseStringListSafely(jsonContent['requiredPPE']),
        brand: safeStringParse(jsonContent['brand']),
        product: safeStringParse(jsonContent['product']),
        barcode: safeStringParse(jsonContent['barcode']),
        confidence: parseDouble(jsonContent['confidence']),
        clarificationNeeded: parseBool(jsonContent['clarificationNeeded']),
        alternatives: alternatives,
        suggestedAction: safeStringParse(jsonContent['suggestedAction']),
        hasUrgentTimeframe: parseBool(jsonContent['hasUrgentTimeframe']),
        instructionsLang: safeStringParse(jsonContent['instructionsLang']),
        translatedInstructions:
            parseStringMapSafely(jsonContent['translatedInstructions']),
        modelVersion: safeStringParse(jsonContent['modelVersion']),
        modelSource:
            safeStringParse(jsonContent['modelSource']) ?? '$provider-$model',
        processingTimeMs: parseInt(jsonContent['processingTimeMs']),
        analysisSessionId: safeStringParse(jsonContent['analysisSessionId']),
        disagreementReason: safeStringParse(jsonContent['disagreementReason']),
        environmentalImpact:
            safeStringParse(jsonContent['environmentalImpact']),
        relatedItems: parseStringListSafely(jsonContent['relatedItems']),
        source: 'ai_analysis_$provider',
        analysisSource: WasteClassification.analysisSourceCloudPrimary,
        reanalysisModelsTried: reanalysisModelsTried,
        recyclability: safeStringParse(jsonContent['recyclability']),
        hazardLevel: parseInt(jsonContent['hazardLevel']),
        co2Impact: parseDouble(jsonContent['co2Impact']),
        decompositionTime: safeStringParse(jsonContent['decompositionTime']),
        properEquipment: parseStringListSafely(jsonContent['properEquipment']),
        materials: parseStringListSafely(jsonContent['materials']),
        subCategory: safeStringParse(jsonContent['subCategory']),
        commonUses: parseStringListSafely(jsonContent['commonUses']),
        alternativeOptions:
            parseStringListSafely(jsonContent['alternativeOptions']),
        localRegulations:
            parseStringMapSafely(jsonContent['localRegulations']),
        waterPollutionLevel: parseInt(jsonContent['waterPollutionLevel']),
        soilContaminationRisk: parseInt(jsonContent['soilContaminationRisk']),
        biodegradabilityDays: parseInt(jsonContent['biodegradabilityDays']),
        recyclingEfficiency: parseInt(jsonContent['recyclingEfficiency']),
        manufacturingEnergyFootprint:
            parseDouble(jsonContent['manufacturingEnergyFootprint']),
        transportationFootprint:
            parseDouble(jsonContent['transportationFootprint']),
        endOfLifeCost: safeStringParse(jsonContent['endOfLifeCost']),
        circularEconomyPotential:
            parseStringListSafely(jsonContent['circularEconomyPotential']),
        generatesMicroplastics:
            parseBool(jsonContent['generatesMicroplastics']),
        humanToxicityLevel: parseInt(jsonContent['humanToxicityLevel']),
        wildlifeImpactSeverity:
            parseInt(jsonContent['wildlifeImpactSeverity']),
        resourceScarcity: safeStringParse(jsonContent['resourceScarcity']),
        disposalCostEstimate: parseDouble(jsonContent['disposalCostEstimate']),
        bbmpComplianceStatus:
            safeStringParse(jsonContent['bbmpComplianceStatus']),
        localGuidelinesVersion:
            safeStringParse(jsonContent['localGuidelinesVersion']),
      );

      final calculatedPoints = classification.calculatePoints();

      return classification.copyWith(pointsAwarded: calculatedPoints);
    } catch (e) {
      WasteAppLogger.severe('Error occurred');
      return _createFallbackClassification(
          jsonContent.toString(), imagePath, region,
          provider: provider,
          model: model,
          classificationId: classificationId);
    }
  }

  static String? safeStringParse(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    return value.toString().trim().isEmpty ? null : value.toString().trim();
  }

  static List<String> parseStringListSafely(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      if (value.startsWith('[') && value.endsWith(']')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return value
          .split(RegExp(r'[;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static Map<String, String>? parseStringMapSafely(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, String>.fromEntries(value.entries
          .map((e) => MapEntry(e.key.toString(), e.value.toString())));
    }
    return null;
  }

  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? parseRecyclingCode(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final numRegExp = RegExp(r'\d+');
      final Match? match = numRegExp.firstMatch(value);
      if (match != null) {
        return int.tryParse(match.group(0)!);
      }
    }
    return null;
  }

  static Map<String, double>? parseImageMetrics(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, double>.fromEntries(value.entries.map(
          (e) => MapEntry(e.key.toString(), parseDouble(e.value) ?? 0.0)));
    }
    return null;
  }

  static List<String> parseStepsFromString(String stepsString) {
    if (stepsString.trim().isEmpty) {
      return ['Please review manually'];
    }

    var steps = <String>[];

    if (stepsString.contains('\n')) {
      steps = stepsString
          .split('\n')
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    } else if (stepsString.contains(',')) {
      steps = stepsString
          .split(',')
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    } else if (stepsString.contains(';')) {
      steps = stepsString
          .split(';')
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    } else if (RegExp(r'\d+\.').hasMatch(stepsString)) {
      steps = stepsString
          .split(RegExp(r'\d+\.'))
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
    } else {
      steps = [stepsString.trim()];
    }

    return steps.isNotEmpty ? steps : ['Please review manually'];
  }

  static WasteClassification _createFallbackClassification(
      String content, String imagePath, String region,
      {required String provider,
      required String model,
      String? classificationId}) {
    WasteAppLogger.severe(
        'Creating fallback classification due to JSON parsing error.',
        context: {
          'rawContent': content,
          'imagePath': imagePath,
          'region': region
        });

    var itemName = 'Unknown Item - Fallback';
    var category = 'Dry Waste';
    var explanation = 'Classification extracted from partial AI response.';

    final lines = content.split('\n');
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('itemname') || lowerLine.contains('item_name')) {
        final itemPattern = RegExp(r'"([^"]+)"|' r"'([^']+)'");
        final itemMatch = itemPattern.firstMatch(line);
        if (itemMatch != null) {
          itemName = (itemMatch.group(1) ?? itemMatch.group(2)) ?? itemName;
        }
      } else if (lowerLine.contains('category')) {
        if (lowerLine.contains('wet')) {
          category = 'Wet Waste';
        } else if (lowerLine.contains('dry')) {
          category = 'Dry Waste';
        } else if (lowerLine.contains('hazardous')) {
          category = 'Hazardous Waste';
        } else if (lowerLine.contains('medical')) {
          category = 'Medical Waste';
        }
      } else if (lowerLine.contains('explanation')) {
        final explanationPattern = RegExp(r'"([^"]+)"|' r"'([^']+)'");
        final explanationMatch = explanationPattern.firstMatch(line);
        if (explanationMatch != null) {
          explanation =
              (explanationMatch.group(1) ?? explanationMatch.group(2)) ??
                  explanation;
        }
      }
    }

    return WasteClassification.fallback(
      imagePath,
      id: classificationId,
      ).copyWith(
        itemName: itemName,
        category: category,
        explanation: explanation,
        modelSource: '$provider-$model',
        source: 'ai_analysis_$provider',
        analysisSource: WasteClassification.analysisSourceCloudPrimary,
        analysisFallbackReason: 'malformed_provider_response',
      );
  }
}
