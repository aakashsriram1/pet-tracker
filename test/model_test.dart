import 'package:flutter_test/flutter_test.dart';
import 'package:pawtrack/main.dart';

void main() {
  group('Pet model', () {
    test('E1: Pet.fromMap() correctly parses all fields', () {
      final map = {
        'id': 'pet-123',
        'owner_id': 'user-456',
        'name': 'Buddy',
        'breed': 'Beagle',
        'type': 'Dog',
        'notes': 'Friendly and energetic',
      };

      final pet = Pet.fromMap(map);

      expect(pet.id, 'pet-123');
      expect(pet.ownerId, 'user-456');
      expect(pet.name, 'Buddy');
      expect(pet.breed, 'Beagle');
      expect(pet.type, 'Dog');
      expect(pet.notes, 'Friendly and energetic');
    });

    test('E2: Pet.toMap() excludes id and owner_id', () {
      final pet = Pet(
        id: 'pet-123',
        ownerId: 'user-456',
        name: 'Max',
        breed: 'Golden Retriever',
        type: 'Dog',
        notes: 'Good boy',
      );

      final map = pet.toMap();

      expect(map.containsKey('id'), false);
      expect(map.containsKey('owner_id'), false);
      expect(map['name'], 'Max');
      expect(map['breed'], 'Golden Retriever');
    });

    test('E3: Pet.toMap() omits notes when null', () {
      final pet = Pet(
        name: 'Fluffy',
        breed: 'Siamese',
        type: 'Cat',
        notes: null,
      );

      final map = pet.toMap();

      expect(map.containsKey('notes'), false);
    });
  });

  group('HealthLog model', () {
    test('E4: HealthLog.toInsertMap() weight includes correct keys', () {
      final log = HealthLog(
        petName: 'Buddy',
        petId: 'pet-123',
        type: LogType.weight,
        date: DateTime(2025, 5, 3, 10, 30),
        note: '',
        weight: 65.5,
        weightUnit: 'lb',
      );

      final map = log.toInsertMap();

      expect(map['pet_id'], 'pet-123');
      expect(map.containsKey('recorded_at'), true);
      expect(map['weight'], 65.5);
      expect(map['unit'], 'lb');
    });

    test('E5: HealthLog.toInsertMap() symptom includes tags', () {
      final log = HealthLog(
        petName: 'Max',
        petId: 'pet-456',
        type: LogType.symptom,
        date: DateTime.now(),
        note: 'seemed lethargic',
        tags: ['vomiting', 'lethargy'],
      );

      final map = log.toInsertMap();

      expect(map['pet_id'], 'pet-456');
      expect(map['tags'], ['vomiting', 'lethargy']);
      expect(map['notes'], 'seemed lethargic');
    });

    test('E6: HealthLog.toInsertMap() symptom omits notes when empty', () {
      final log = HealthLog(
        petName: 'Whiskers',
        petId: 'pet-789',
        type: LogType.symptom,
        date: DateTime.now(),
        note: '',
        tags: ['coughing'],
      );

      final map = log.toInsertMap();

      expect(map.containsKey('notes'), false);
    });

    test('E7: HealthLog.toInsertMap() diet omits null optional fields', () {
      final log = HealthLog(
        petName: 'Buddy',
        petId: 'pet-123',
        type: LogType.diet,
        date: DateTime.now(),
        note: '',
        foodType: null,
        foodBrand: null,
        portionSize: null,
        portionUnit: null,
      );

      final map = log.toInsertMap();

      expect(map['pet_id'], 'pet-123');
      expect(map.containsKey('fed_at'), true);
      expect(map.containsKey('food_type'), false);
      expect(map.containsKey('food_brand'), false);
      expect(map.containsKey('portion_size'), false);
      expect(map.containsKey('portion_unit'), false);
    });

    test('E8: HealthLog.toInsertMap() vaccine includes next_due_date', () {
      final nextDue = DateTime(2026, 5, 3);
      final log = HealthLog(
        petName: 'Max',
        petId: 'pet-456',
        type: LogType.vaccine,
        date: DateTime.now(),
        note: '',
        vaccineName: 'Rabies',
        nextDueDate: nextDue,
      );

      final map = log.toInsertMap();

      expect(map['name'], 'Rabies');
      expect(map.containsKey('next_due_date'), true);
    });

    test('E9: HealthLog.toInsertMap() medication includes end_date when set', () {
      final endDate = DateTime(2026, 1, 1);
      final log = HealthLog(
        petName: 'Buddy',
        petId: 'pet-123',
        type: LogType.medication,
        date: DateTime.now(),
        note: '',
        medicationName: 'Heartgard',
        dose: '1 tablet',
        frequency: 'Every 30 days',
        endDate: endDate,
      );

      final map = log.toInsertMap();

      expect(map['name'], 'Heartgard');
      expect(map.containsKey('end_date'), true);
    });

    test('E10: HealthLog.toInsertMap() medication omits end_date when null', () {
      final log = HealthLog(
        petName: 'Buddy',
        petId: 'pet-123',
        type: LogType.medication,
        date: DateTime.now(),
        note: '',
        medicationName: 'Heartgard',
        dose: '1 tablet',
        frequency: 'Every 30 days',
        endDate: null,
      );

      final map = log.toInsertMap();

      expect(map.containsKey('end_date'), false);
    });

    test('E11: HealthLog.fromMap() weight parses correctly', () {
      final map = {
        'id': 'log-123',
        'pet_id': 'pet-456',
        'recorded_at': '2025-05-03T10:30:00Z',
        'weight': 65.5,
        'unit': 'lb',
      };

      final log = HealthLog.fromMap(LogType.weight, map, 'Buddy');

      expect(log.id, 'log-123');
      expect(log.weight, 65.5);
      expect(log.weightUnit, 'lb');
      expect(log.type, LogType.weight);
    });

    test('E12: HealthLog.fromMap() symptom casts tags list', () {
      final map = {
        'id': 'log-456',
        'pet_id': 'pet-789',
        'recorded_at': '2025-05-03T10:30:00Z',
        'tags': ['vomiting', 'lethargy'],
        'notes': 'seemed off',
      };

      final log = HealthLog.fromMap(LogType.symptom, map, 'Max');

      expect(log.tags, ['vomiting', 'lethargy']);
      expect(log.tags is List<String>, true);
      expect(log.note, 'seemed off');
    });

    test('E13: HealthLog.fromMap() vaccine parses next_due_date', () {
      final map = {
        'id': 'log-789',
        'pet_id': 'pet-123',
        'date_administered': '2025-05-03T10:30:00Z',
        'name': 'Rabies',
        'next_due_date': '2026-05-03T00:00:00Z',
        'notes': 'First dose',
      };

      final log = HealthLog.fromMap(LogType.vaccine, map, 'Buddy');

      expect(log.vaccineName, 'Rabies');
      expect(log.nextDueDate, isNotNull);
      expect(log.nextDueDate!.year, 2026);
    });

    test('E14: HealthLog.fromMap() medication parses optional end_date as null when missing', () {
      final map = {
        'id': 'log-abc',
        'pet_id': 'pet-123',
        'start_date': '2025-01-01T00:00:00Z',
        'name': 'Heartgard',
        'dose': '1 tablet',
        'frequency': 'Every 30 days',
        'end_date': null,
        'notes': '',
      };

      final log = HealthLog.fromMap(LogType.medication, map, 'Buddy');

      expect(log.medicationName, 'Heartgard');
      expect(log.endDate, isNull);
    });
  });
}
