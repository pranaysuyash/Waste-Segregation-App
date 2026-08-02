import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waste_segregation_app/models/society_policy_override.dart';
import 'package:waste_segregation_app/services/firestore_schema_registry.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Firestore-backed service for society-level waste policy overrides.
///
/// Societies (RWAs, apartment complexes) can register custom waste rules that
/// sit as a delta layer on top of the base city policy plugin. The policy
/// engine queries this service to resolve society overrides per scan.
///
/// Collections used:
/// - `society_policies/{societyId}` — society profile + override rules
class SocietyPolicyService {
  SocietyPolicyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.societyPolicies);

  /// Fetch a society's policy overrides by ID.
  Future<SocietyPolicyOverride?> getSocietyPolicy(String societyId) async {
    try {
      final snapshot = await _collection.doc(societyId).get();
      if (!snapshot.exists) return null;
      return SocietyPolicyOverride.fromJson(snapshot.data()!);
    } catch (e) {
      WasteAppLogger.severe('Error fetching society policy',
          error: e, context: {'societyId': societyId});
      return null;
    }
  }

  /// Stream a society's policy overrides in real time.
  Stream<SocietyPolicyOverride?> streamSocietyPolicy(String societyId) {
    return _collection.doc(societyId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return SocietyPolicyOverride.fromJson(snapshot.data()!);
    });
  }

  /// Create or overwrite a society's policy overrides.
  Future<void> setSocietyPolicy(SocietyPolicyOverride policy) async {
    try {
      await _collection.doc(policy.societyId).set(policy.toJson());
      WasteAppLogger.info('Society policy saved', context: {
        'societyId': policy.societyId,
        'societyName': policy.societyName,
        'overrides': policy.overrides.length,
      });
    } catch (e) {
      WasteAppLogger.severe('Error saving society policy',
          error: e, context: {'societyId': policy.societyId});
      rethrow;
    }
  }

  /// Update specific fields of a society policy without overwriting.
  Future<void> updateSocietyPolicy(
      String societyId, Map<String, dynamic> updates) async {
    try {
      await _collection.doc(societyId).update(updates);
      WasteAppLogger.info('Society policy updated',
          context: {'societyId': societyId, 'fields': updates.keys});
    } catch (e) {
      WasteAppLogger.severe('Error updating society policy',
          error: e, context: {'societyId': societyId});
      rethrow;
    }
  }

  /// Delete a society's policy overrides.
  Future<void> deleteSocietyPolicy(String societyId) async {
    try {
      await _collection.doc(societyId).delete();
      WasteAppLogger.info('Society policy deleted',
          context: {'societyId': societyId});
    } catch (e) {
      WasteAppLogger.severe('Error deleting society policy',
          error: e, context: {'societyId': societyId});
      rethrow;
    }
  }

  /// Find societies near a GPS location (for proximity-based detection).
  Future<List<SocietyPolicyOverride>> findSocietiesNear(
      double lat, double lng, {double radiusKm = 1.0}) async {
    try {
      final snapshot = await _collection
          .where('locationLat', isGreaterThanOrEqualTo: lat - _kmToDeg(radiusKm))
          .where('locationLat', isLessThanOrEqualTo: lat + _kmToDeg(radiusKm))
          .get();

      return snapshot.docs
          .map((doc) => SocietyPolicyOverride.fromJson(doc.data()))
          .where((s) => _isWithinRadius(s, lat, lng, radiusKm))
          .toList();
    } catch (e) {
      WasteAppLogger.severe('Error finding nearby societies',
          error: e, context: {'lat': lat, 'lng': lng});
      return [];
    }
  }

  /// Verify a society's policy (sets isVerified = true).
  ///
  /// PRIVACY-06: This method is deprecated for client-side use.
  /// The `isVerified` field is server-authoritative — Firestore rules reject
  /// non-admin writes to verification fields. Use Cloud Functions or the
  /// admin SDK to verify society policies.
  @Deprecated('Server-authoritative: use Cloud Functions or admin SDK')
  Future<void> verifySocietyPolicy(
      String societyId, String verifiedById, String verifiedByName) async {
    WasteAppLogger.warning(
      'verifySocietyPolicy called from client — will fail unless caller is admin',
      context: {'societyId': societyId, 'caller': verifiedById},
    );
    await updateSocietyPolicy(societyId, {
      'isVerified': true,
      'verifiedById': verifiedById,
      'verifiedByName': verifiedByName,
      'verifiedAt': DateTime.now().toIso8601String(),
    });
  }

  double _kmToDeg(double km) => km / 111.0;

  double _toRad(double deg) => deg * pi / 180.0;

  /// PRIVACY-06: Haversine formula using dart:math for accurate results.
  /// The previous implementation used broken Taylor-series approximations
  /// (y/x for atan2, first-order sin/cos) that produced incorrect distances.
  bool _isWithinRadius(
      SocietyPolicyOverride society, double lat, double lng, double radiusKm) {
    if (society.locationLat == null || society.locationLng == null) return false;
    const earthRadius = 6371.0; // km
    final dLat = _toRad(lat - society.locationLat!);
    final dLng = _toRad(lng - society.locationLng!);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(society.locationLat!)) *
            cos(_toRad(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c <= radiusKm;
  }

  // PRIVACY-06: Use dart:math for accurate trigonometric calculations.
  // The previous implementation used Taylor-series approximations that
  // produced incorrect results for large angles and edge cases.
}
