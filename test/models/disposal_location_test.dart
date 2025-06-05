import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waste_segregation_app/models/disposal_location.dart';
import '../test_helper.dart';

void main() {
  group('DisposalLocation Model Tests', () {
    late GeoPoint testCoordinates;
    late Timestamp testTimestamp;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      testCoordinates = const GeoPoint(37.7749, -122.4194); // San Francisco coordinates
      testTimestamp = Timestamp.fromDate(DateTime.parse('2024-01-15T10:30:00Z'));
    });

    group('FacilitySource Enum Tests', () {
      test('should convert FacilitySource to string correctly', () {
        expect(facilitySourceToString(FacilitySource.adminEntered), 
               equals('ADMIN_ENTERED'));
        expect(facilitySourceToString(FacilitySource.userSuggestedIntegrated), 
               equals('USER_SUGGESTED_INTEGRATED'));
        expect(facilitySourceToString(FacilitySource.bulkImported), 
               equals('BULK_IMPORTED'));
      });

      test('should convert string to FacilitySource correctly', () {
        expect(facilitySourceFromString('ADMIN_ENTERED'), 
               equals(FacilitySource.adminEntered));
        expect(facilitySourceFromString('USER_SUGGESTED_INTEGRATED'), 
               equals(FacilitySource.userSuggestedIntegrated));
        expect(facilitySourceFromString('BULK_IMPORTED'), 
               equals(FacilitySource.bulkImported));
      });

      test('should handle invalid source strings', () {
        expect(facilitySourceFromString('INVALID_SOURCE'), 
               equals(FacilitySource.adminEntered)); // Default fallback
        expect(facilitySourceFromString(null), 
               equals(FacilitySource.adminEntered));
        expect(facilitySourceFromString(''), 
               equals(FacilitySource.adminEntered));
      });
    });

    group('DisposalLocationPhoto Tests', () {
      test('should create DisposalLocationPhoto with all fields', () {
        final photo = DisposalLocationPhoto(
          url: 'https://example.com/facility-photo.jpg',
          uploadedByUserId: 'user_123',
          caption: 'Main entrance of the recycling facility',
          uploadTimestamp: testTimestamp,
        );

        expect(photo.url, equals('https://example.com/facility-photo.jpg'));
        expect(photo.uploadedByUserId, equals('user_123'));
        expect(photo.caption, equals('Main entrance of the recycling facility'));
        expect(photo.uploadTimestamp, equals(testTimestamp));
      });

      test('should create DisposalLocationPhoto with minimal fields', () {
        final photo = DisposalLocationPhoto(
          url: 'https://example.com/facility-photo.jpg',
        );

        expect(photo.url, equals('https://example.com/facility-photo.jpg'));
        expect(photo.uploadedByUserId, isNull);
        expect(photo.caption, isNull);
        expect(photo.uploadTimestamp, isNull);
      });

      test('should serialize and deserialize DisposalLocationPhoto correctly', () {
        final original = DisposalLocationPhoto(
          url: 'https://example.com/test-photo.jpg',
          uploadedByUserId: 'user_456',
          caption: 'Test photo caption',
          uploadTimestamp: testTimestamp,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['url'], equals('https://example.com/test-photo.jpg'));
        expect(json['uploadedByUserId'], equals('user_456'));
        expect(json['caption'], equals('Test photo caption'));
        expect(json['uploadTimestamp'], equals(testTimestamp));

        // Test fromJson
        final recreated = DisposalLocationPhoto.fromJson(json);
        expect(recreated.url, equals(original.url));
        expect(recreated.uploadedByUserId, equals(original.uploadedByUserId));
        expect(recreated.caption, equals(original.caption));
        expect(recreated.uploadTimestamp, equals(original.uploadTimestamp));
      });

      test('should handle null fields in serialization', () {
        final photo = DisposalLocationPhoto(
          url: 'https://example.com/photo.jpg',
        );

        final json = photo.toJson();
        expect(json['url'], equals('https://example.com/photo.jpg'));
        expect(json['uploadedByUserId'], isNull);
        expect(json['caption'], isNull);
        expect(json['uploadTimestamp'], isNull);

        final recreated = DisposalLocationPhoto.fromJson(json);
        expect(recreated.url, equals(photo.url));
        expect(recreated.uploadedByUserId, isNull);
        expect(recreated.caption, isNull);
        expect(recreated.uploadTimestamp, isNull);
      });

      test('should copyWith correctly', () {
        final original = DisposalLocationPhoto(
          url: 'https://example.com/original.jpg',
          uploadedByUserId: 'user_123',
          caption: 'Original caption',
          uploadTimestamp: testTimestamp,
        );

        final updated = original.copyWith(
          caption: 'Updated caption',
          uploadedByUserId: 'user_456',
        );

        expect(updated.url, equals(original.url)); // Unchanged
        expect(updated.uploadedByUserId, equals('user_456')); // Changed
        expect(updated.caption, equals('Updated caption')); // Changed
        expect(updated.uploadTimestamp, equals(original.uploadTimestamp)); // Unchanged
      });
    });

    group('DisposalLocation Constructor Tests', () {
      test('should create DisposalLocation with all required fields', () {
        final location = DisposalLocation(
          id: 'location_123',
          name: 'SF Recycling Center',
          address: '123 Green St, San Francisco, CA 94102',
          coordinates: testCoordinates,
          operatingHours: {
            'monday': '9am-5pm',
            'tuesday': '9am-5pm',
            'wednesday': '9am-5pm',
            'thursday': '9am-5pm',
            'friday': '9am-5pm',
            'saturday': '10am-4pm',
            'sunday': 'Closed',
          },
          contactInfo: {
            'phone': '+1-415-555-0123',
            'email': 'info@sfrecycling.com',
            'website': 'https://sfrecycling.com',
          },
          acceptedMaterials: ['Plastic', 'Glass', 'Metal', 'Paper'],
          source: FacilitySource.adminEntered,
        );

        expect(location.id, equals('location_123'));
        expect(location.name, equals('SF Recycling Center'));
        expect(location.address, contains('San Francisco'));
        expect(location.coordinates, equals(testCoordinates));
        expect(location.operatingHours.length, equals(7));
        expect(location.contactInfo.length, equals(3));
        expect(location.acceptedMaterials.length, equals(4));
        expect(location.source, equals(FacilitySource.adminEntered));
        expect(location.isActive, isTrue);
      });

      test('should create DisposalLocation with minimal fields and defaults', () {
        final location = DisposalLocation(
          name: 'Basic Facility',
          address: '456 Basic St',
          coordinates: testCoordinates,
          operatingHours: {'monday': '9am-5pm'},
          contactInfo: {'phone': '+1-555-0123'},
          acceptedMaterials: ['Plastic'],
          source: FacilitySource.userSuggestedIntegrated,
        );

        expect(location.id, isNull);
        expect(location.photos, isNull);
        expect(location.lastAdminUpdate, isNull);
        expect(location.lastVerifiedByAdmin, isNull);
        expect(location.isActive, isTrue); // Default value
      });

      test('should create DisposalLocation with photos', () {
        final photos = [
          DisposalLocationPhoto(
            url: 'https://example.com/photo1.jpg',
            caption: 'Front entrance',
          ),
          DisposalLocationPhoto(
            url: 'https://example.com/photo2.jpg',
            caption: 'Sorting area',
          ),
        ];

        final location = DisposalLocation(
          name: 'Photo Facility',
          address: '789 Photo St',
          coordinates: testCoordinates,
          operatingHours: {'daily': '24/7'},
          contactInfo: {'phone': '+1-555-0456'},
          acceptedMaterials: ['All materials'],
          photos: photos,
          source: FacilitySource.bulkImported,
        );

        expect(location.photos?.length, equals(2));
        expect(location.photos![0].caption, equals('Front entrance'));
        expect(location.photos![1].caption, equals('Sorting area'));
      });
    });

    group('DisposalLocation Serialization Tests', () {
      test('should serialize and deserialize correctly with fromJson/toJson', () {
        final original = DisposalLocation(
          name: 'Test Recycling Center',
          address: '123 Test Ave, Test City, TC 12345',
          coordinates: testCoordinates,
          operatingHours: {
            'monday': '8am-6pm',
            'tuesday': '8am-6pm',
            'wednesday': 'Closed',
          },
          contactInfo: {
            'phone': '+1-555-TEST',
            'email': 'test@recycling.com',
          },
          acceptedMaterials: ['Plastic', 'Glass'],
          photos: [
            DisposalLocationPhoto(
              url: 'https://example.com/test.jpg',
              caption: 'Test photo',
            ),
          ],
          lastAdminUpdate: testTimestamp,
          lastVerifiedByAdmin: testTimestamp,
          source: FacilitySource.adminEntered,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['name'], equals('Test Recycling Center'));
        expect(json['address'], contains('Test City'));
        expect(json['coordinates'], equals(testCoordinates));
        expect(json['operatingHours'], isA<Map<String, String>>());
        expect(json['contactInfo'], isA<Map<String, String>>());
        expect(json['acceptedMaterials'], isA<List<String>>());
        expect(json['photos'], isA<List>());
        expect(json['source'], equals('ADMIN_ENTERED'));
        expect(json['isActive'], isTrue);

        // Test fromJson
        const documentId = 'test_doc_123';
        final recreated = DisposalLocation.fromJson(json, documentId);
        
        expect(recreated.id, equals(documentId));
        expect(recreated.name, equals(original.name));
        expect(recreated.address, equals(original.address));
        expect(recreated.coordinates, equals(original.coordinates));
        expect(recreated.operatingHours, equals(original.operatingHours));
        expect(recreated.contactInfo, equals(original.contactInfo));
        expect(recreated.acceptedMaterials, equals(original.acceptedMaterials));
        expect(recreated.photos?.length, equals(1));
        expect(recreated.source, equals(original.source));
        expect(recreated.isActive, equals(original.isActive));
      });

      test('should handle missing optional fields in fromJson', () {
        final minimalJson = {
          'name': 'Minimal Facility',
          'address': '456 Minimal St',
          'coordinates': testCoordinates,
          'operatingHours': {'monday': '9am-5pm'},
          'contactInfo': {'phone': '+1-555-0123'},
          'acceptedMaterials': ['Plastic'],
        };

        const documentId = 'minimal_doc_123';
        final location = DisposalLocation.fromJson(minimalJson, documentId);

        expect(location.id, equals(documentId));
        expect(location.name, equals('Minimal Facility'));
        expect(location.photos, isNull);
        expect(location.lastAdminUpdate, isNull);
        expect(location.lastVerifiedByAdmin, isNull);
        expect(location.source, equals(FacilitySource.adminEntered)); // Default
        expect(location.isActive, isTrue); // Default
      });

      test('should handle empty lists and maps in serialization', () {
        final location = DisposalLocation(
          name: 'Empty Facility',
          address: '789 Empty St',
          coordinates: testCoordinates,
          operatingHours: {}, // Empty map
          contactInfo: {}, // Empty map
          acceptedMaterials: [], // Empty list
          photos: [], // Empty list
          source: FacilitySource.bulkImported,
        );

        final json = location.toJson();
        expect(json['operatingHours'], isEmpty);
        expect(json['contactInfo'], isEmpty);
        expect(json['acceptedMaterials'], isEmpty);
        expect(json['photos'], isEmpty);

        const documentId = 'empty_doc_123';
        final recreated = DisposalLocation.fromJson(json, documentId);
        expect(recreated.operatingHours, isEmpty);
        expect(recreated.contactInfo, isEmpty);
        expect(recreated.acceptedMaterials, isEmpty);
        expect(recreated.photos, isEmpty);
      });
    });

    group('DisposalLocation copyWith Tests', () {
      test('should copyWith correctly updating specific fields', () {
        final original = DisposalLocation(
          id: 'original_123',
          name: 'Original Facility',
          address: '123 Original St',
          coordinates: testCoordinates,
          operatingHours: {'monday': '9am-5pm'},
          contactInfo: {'phone': '+1-555-0123'},
          acceptedMaterials: ['Plastic'],
          source: FacilitySource.adminEntered,
        );

        final updated = original.copyWith(
          name: 'Updated Facility',
          isActive: false,
          acceptedMaterials: ['Plastic', 'Glass', 'Metal'],
        );

        expect(updated.id, equals(original.id)); // Unchanged
        expect(updated.name, equals('Updated Facility')); // Changed
        expect(updated.address, equals(original.address)); // Unchanged
        expect(updated.isActive, isFalse); // Changed
        expect(updated.acceptedMaterials.length, equals(3)); // Changed
        expect(updated.source, equals(original.source)); // Unchanged
      });

      test('should preserve original values when no changes specified', () {
        final original = DisposalLocation(
          name: 'Test Facility',
          address: '456 Test St',
          coordinates: testCoordinates,
          operatingHours: {'daily': '24/7'},
          contactInfo: {'phone': '+1-555-TEST'},
          acceptedMaterials: ['All materials'],
          source: FacilitySource.userSuggestedIntegrated,
        );

        final copy = original.copyWith();

        expect(copy.name, equals(original.name));
        expect(copy.address, equals(original.address));
        expect(copy.coordinates, equals(original.coordinates));
        expect(copy.operatingHours, equals(original.operatingHours));
        expect(copy.contactInfo, equals(original.contactInfo));
        expect(copy.acceptedMaterials, equals(original.acceptedMaterials));
        expect(copy.source, equals(original.source));
        expect(copy.isActive, equals(original.isActive));
      });
    });

    group('Location Data Validation Tests', () {
      test('should handle various coordinate ranges', () {
        final locations = [
          // San Francisco
          DisposalLocation(
            name: 'SF Location',
            address: 'SF Address',
            coordinates: const GeoPoint(37.7749, -122.4194),
            operatingHours: {'monday': '9am-5pm'},
            contactInfo: {'phone': '+1-555-0123'},
            acceptedMaterials: ['Plastic'],
            source: FacilitySource.adminEntered,
          ),
          // New York
          DisposalLocation(
            name: 'NYC Location',
            address: 'NYC Address',
            coordinates: const GeoPoint(40.7128, -74.0060),
            operatingHours: {'monday': '9am-5pm'},
            contactInfo: {'phone': '+1-555-0123'},
            acceptedMaterials: ['Glass'],
            source: FacilitySource.adminEntered,
          ),
          // International (London)
          DisposalLocation(
            name: 'London Location',
            address: 'London Address',
            coordinates: const GeoPoint(51.5074, -0.1278),
            operatingHours: {'monday': '9am-5pm'},
            contactInfo: {'phone': '+44-20-1234-5678'},
            acceptedMaterials: ['Metal'],
            source: FacilitySource.adminEntered,
          ),
        ];

        for (final location in locations) {
          expect(location.coordinates.latitude, inInclusiveRange(-90.0, 90.0));
          expect(location.coordinates.longitude, inInclusiveRange(-180.0, 180.0));
        }
      });

      test('should handle various operating hours formats', () {
        final location = DisposalLocation(
          name: 'Variable Hours Facility',
          address: '123 Variable St',
          coordinates: testCoordinates,
          operatingHours: {
            'monday': '9am-5pm',
            'tuesday': '24/7',
            'wednesday': 'Closed',
            'thursday': '8:00 AM - 6:00 PM',
            'friday': '9-17',
            'saturday': 'By appointment',
            'sunday': '10am-2pm',
          },
          contactInfo: {'phone': '+1-555-0123'},
          acceptedMaterials: ['Various'],
          source: FacilitySource.adminEntered,
        );

        expect(location.operatingHours.length, equals(7));
        expect(location.operatingHours['wednesday'], equals('Closed'));
        expect(location.operatingHours['tuesday'], equals('24/7'));
      });

      test('should handle various contact info formats', () {
        final location = DisposalLocation(
          name: 'Multi-Contact Facility',
          address: '456 Contact St',
          coordinates: testCoordinates,
          operatingHours: {'daily': '9am-5pm'},
          contactInfo: {
            'phone': '+1-415-555-0123',
            'mobile': '+1-415-555-0124',
            'email': 'info@facility.com',
            'website': 'https://facility.com',
            'fax': '+1-415-555-0125',
            'social_media': '@facility_official',
          },
          acceptedMaterials: ['All types'],
          source: FacilitySource.adminEntered,
        );

        expect(location.contactInfo.length, equals(6));
        expect(location.contactInfo['phone'], startsWith('+1'));
        expect(location.contactInfo['email'], contains('@'));
        expect(location.contactInfo['website'], startsWith('https://'));
      });

      test('should handle comprehensive accepted materials list', () {
        final location = DisposalLocation(
          name: 'Comprehensive Facility',
          address: '789 Comprehensive St',
          coordinates: testCoordinates,
          operatingHours: {'daily': '24/7'},
          contactInfo: {'phone': '+1-555-0123'},
          acceptedMaterials: [
            'Plastic bottles',
            'Glass containers',
            'Aluminum cans',
            'Steel cans',
            'Cardboard',
            'Paper',
            'Electronics',
            'Batteries',
            'Textiles',
            'Furniture',
            'Hazardous materials',
            'Construction debris',
          ],
          source: FacilitySource.bulkImported,
        );

        expect(location.acceptedMaterials.length, equals(12));
        expect(location.acceptedMaterials.contains('Electronics'), isTrue);
        expect(location.acceptedMaterials.contains('Hazardous materials'), isTrue);
      });
    });

    group('Edge Cases and Error Handling Tests', () {
      test('should handle extreme coordinates', () {
        final locations = [
          // North Pole
          DisposalLocation(
            name: 'North Pole Facility',
            address: 'North Pole',
            coordinates: const GeoPoint(90.0, 0.0),
            operatingHours: {'winter': 'Closed'},
            contactInfo: {'radio': 'Emergency frequency'},
            acceptedMaterials: ['Ice'],
            source: FacilitySource.adminEntered,
          ),
          // South Pole
          DisposalLocation(
            name: 'South Pole Facility',
            address: 'South Pole',
            coordinates: const GeoPoint(-90.0, 0.0),
            operatingHours: {'summer': 'Open'},
            contactInfo: {'satellite': 'Emergency only'},
            acceptedMaterials: ['Research waste'],
            source: FacilitySource.adminEntered,
          ),
        ];

        for (final location in locations) {
          expect(location.coordinates.latitude.abs(), equals(90.0));
        }
      });

      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        
        final location = DisposalLocation(
          name: longString,
          address: longString,
          coordinates: testCoordinates,
          operatingHours: {longString: longString},
          contactInfo: {longString: longString},
          acceptedMaterials: [longString],
          source: FacilitySource.adminEntered,
        );

        expect(location.name.length, equals(1000));
        expect(location.address.length, equals(1000));
        expect(location.operatingHours.keys.first.length, equals(1000));
        expect(location.acceptedMaterials.first.length, equals(1000));
      });

      test('should handle inactive facilities', () {
        final inactiveLocation = DisposalLocation(
          name: 'Inactive Facility',
          address: '123 Closed St',
          coordinates: testCoordinates,
          operatingHours: {'all': 'Permanently closed'},
          contactInfo: {'status': 'Closed'},
          acceptedMaterials: [],
          source: FacilitySource.adminEntered,
          isActive: false,
        );

        expect(inactiveLocation.isActive, isFalse);
        expect(inactiveLocation.acceptedMaterials, isEmpty);
      });

      test('should handle future timestamps', () {
        final futureTimestamp = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365))
        );

        final location = DisposalLocation(
          name: 'Future Facility',
          address: '456 Future St',
          coordinates: testCoordinates,
          operatingHours: {'opening': 'Next year'},
          contactInfo: {'phone': '+1-555-FUTURE'},
          acceptedMaterials: ['Future materials'],
          lastAdminUpdate: futureTimestamp,
          lastVerifiedByAdmin: futureTimestamp,
          source: FacilitySource.adminEntered,
        );

        expect(location.lastAdminUpdate?.toDate().isAfter(DateTime.now()), isTrue);
        expect(location.lastVerifiedByAdmin?.toDate().isAfter(DateTime.now()), isTrue);
      });

      test('should handle special characters in all fields', () {
        final location = DisposalLocation(
          name: 'Facility with émojis 🏭♻️',
          address: '123 Spécial St, Tëst Cïty 🌍',
          coordinates: testCoordinates,
          operatingHours: {
            'mond@y': '9äm-5pm',
            'tüesday': '9ám-5pm ⏰',
          },
          contactInfo: {
            'phoñe': '+1-555-SPËCIAL',
            'emáil': 'tëst@spëcial.com 📧',
          },
          acceptedMaterials: ['Plästic 🥤', 'Glâss 🍾', 'Metál ♻️'],
          source: FacilitySource.userSuggestedIntegrated,
        );

        expect(location.name, contains('émojis'));
        expect(location.address, contains('🌍'));
        expect(location.operatingHours.keys.any((k) => k.contains('@')), isTrue);
        expect(location.contactInfo.values.any((v) => v.contains('📧')), isTrue);
        expect(location.acceptedMaterials.any((m) => m.contains('♻️')), isTrue);
      });
    });

    group('Integration Tests with Photos', () {
      test('should handle complex facility with multiple photos and updates', () {
        final photos = [
          DisposalLocationPhoto(
            url: 'https://example.com/entrance.jpg',
            uploadedByUserId: 'admin_user',
            caption: 'Main entrance with signage',
            uploadTimestamp: testTimestamp,
          ),
          DisposalLocationPhoto(
            url: 'https://example.com/sorting.jpg',
            uploadedByUserId: 'volunteer_123',
            caption: 'Sorting area for different materials',
            uploadTimestamp: Timestamp.fromDate(
              testTimestamp.toDate().add(const Duration(days: 1))
            ),
          ),
          DisposalLocationPhoto(
            url: 'https://example.com/equipment.jpg',
            caption: 'Processing equipment',
            // No uploadedByUserId or timestamp
          ),
        ];

        final complexLocation = DisposalLocation(
          id: 'complex_facility_123',
          name: 'Advanced Recycling Center',
          address: '789 Tech Blvd, Innovation District, Future City, FC 54321',
          coordinates: testCoordinates,
          operatingHours: {
            'monday': '6am-10pm',
            'tuesday': '6am-10pm',
            'wednesday': '6am-10pm',
            'thursday': '6am-10pm',
            'friday': '6am-10pm',
            'saturday': '8am-8pm',
            'sunday': '10am-6pm',
          },
          contactInfo: {
            'phone': '+1-555-RECYCLE',
            'email': 'contact@advancedrecycling.com',
            'website': 'https://advancedrecycling.com',
            'emergency': '+1-555-EMERGENCY',
          },
          acceptedMaterials: [
            'All types of plastic (1-7)',
            'Glass bottles and jars',
            'Aluminum and steel cans',
            'Paper and cardboard',
            'Electronics and e-waste',
            'Batteries (all types)',
            'Textiles and clothing',
            'Small appliances',
            'Automotive fluids',
            'Paint and chemicals',
          ],
          photos: photos,
          lastAdminUpdate: testTimestamp,
          lastVerifiedByAdmin: testTimestamp,
          source: FacilitySource.adminEntered,
        );

        expect(complexLocation.photos?.length, equals(3));
        expect(complexLocation.acceptedMaterials.length, equals(10));
        expect(complexLocation.operatingHours.length, equals(7));
        expect(complexLocation.contactInfo.length, equals(4));
        
        // Test that photos maintain their properties
        expect(complexLocation.photos![0].uploadedByUserId, equals('admin_user'));
        expect(complexLocation.photos![1].uploadedByUserId, equals('volunteer_123'));
        expect(complexLocation.photos![2].uploadedByUserId, isNull);
        
        // Test serialization of complex location
        final json = complexLocation.toJson();
        expect(json['photos'], isA<List>());
        expect((json['photos'] as List).length, equals(3));
        
        // Test deserialization
        const documentId = 'complex_doc_456';
        final recreated = DisposalLocation.fromJson(json, documentId);
        expect(recreated.photos?.length, equals(3));
        expect(recreated.photos![0].caption, equals('Main entrance with signage'));
      });
    });
  });
}
