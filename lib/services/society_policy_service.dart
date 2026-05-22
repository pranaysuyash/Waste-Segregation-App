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
  Future<void> verifySocietyPolicy(
      String societyId, String verifiedById, String verifiedByName) async {
    await updateSocietyPolicy(societyId, {
      'isVerified': true,
      'verifiedById': verifiedById,
      'verifiedByName': verifiedByName,
      'verifiedAt': DateTime.now().toIso8601String(),
    });
  }

  double _kmToDeg(double km) => km / 111.0;

  bool _isWithinRadius(
      SocietyPolicyOverride society, double lat, double lng, double radiusKm) {
    if (society.locationLat == null || society.locationLng == null) return false;
    const earthRadius = 6371.0;
    final dLat = _toRad(lat - society.locationLat!);
    final dLng = _toRad(lng - society.locationLng!);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(society.locationLat!)) *
            _cos(_toRad(lat)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c <= radiusKm;
  }

  double _toRad(double deg) => deg * 3.141592653589793 / 180.0;
  double _sin(double v) => v - (v * v * v) / 6;
  double _cos(double v) => 1 - (v * v) / 2;
  double _sqrt(double v) => v < 0 ? 0 : v > 1 ? 1 : v;
  double _atan2(double y, double x) => y / x;
}
