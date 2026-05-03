import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawtrack/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _InMemoryAsyncStorage(),
      ),
    );
    client = Supabase.instance.client;
    await client.auth.signInWithPassword(
      email: 'barajasgluis525@gmail.com',
      password: dotenv.env['TEST_PASSWORD']!,
    );
  });

  tearDownAll(() async {
    await client.auth.signOut();
  });

  test('fetchPets returns list from real DB', () async {
    final db = PawTrackDatabase(client);
    final pets = await db.fetchPets();
    expect(pets, isA<List<Pet>>());
  });

  test('insertPet round-trip: inserts and appears in fetchPets, then cleans up', () async {
    final db = PawTrackDatabase(client);
    final before = await db.fetchPets();

    final testPet = Pet(name: '__test_dog__', breed: 'Lab', type: 'Dog');
    final saved = await db.insertPet(testPet);

    expect(saved.id, isNotNull);
    expect(saved.name, '__test_dog__');

    final after = await db.fetchPets();
    expect(after.length, greaterThan(before.length));

    // cleanup
    await client.from('pets').delete().eq('id', saved.id!);
  });

  test('insertPet saves notes and returns pet with id', () async {
    final db = PawTrackDatabase(client);
    final pet = Pet(name: '__test_notes__', breed: 'Poodle', type: 'Dog', notes: 'test notes');
    final saved = await db.insertPet(pet);

    expect(saved.id, isNotNull);
    expect(saved.notes, 'test notes');

    await client.from('pets').delete().eq('id', saved.id!);
  });

  test('insertPet without notes succeeds', () async {
    final db = PawTrackDatabase(client);
    final pet = Pet(name: '__test_nonotes__', breed: 'Poodle', type: 'Dog');
    final saved = await db.insertPet(pet);

    expect(saved.id, isNotNull);
    expect(saved.notes, isNull);

    await client.from('pets').delete().eq('id', saved.id!);
  });

  // D — Data persistence / DB wiring tests

  test('D1: insertLog weight round-trip', () async {
    final db = PawTrackDatabase(client);

    // Create test pet
    final pet = Pet(name: '__test_weight__', breed: 'Lab', type: 'Dog');
    final savedPet = await db.insertPet(pet);

    // Insert weight log
    final log = HealthLog(
      petName: savedPet.name,
      petId: savedPet.id,
      type: LogType.weight,
      date: DateTime.now(),
      note: '',
      weight: 65.5,
      weightUnit: 'lb',
    );
    await db.insertLog(log);

    // Fetch and verify
    final logs = await db.fetchLogs([savedPet]);
    expect(logs, isNotEmpty);
    expect(logs.first.weight, 65.5);
    expect(logs.first.weightUnit, 'lb');

    // Cleanup
    await client.from('weight_entries').delete().eq('pet_id', savedPet.id!);
    await client.from('pets').delete().eq('id', savedPet.id!);
  });

  test('D2: insertLog symptom with tags round-trip', () async {
    final db = PawTrackDatabase(client);

    // Create test pet
    final pet = Pet(name: '__test_symptom__', breed: 'Poodle', type: 'Dog');
    final savedPet = await db.insertPet(pet);

    // Insert symptom log with tags
    final log = HealthLog(
      petName: savedPet.name,
      petId: savedPet.id,
      type: LogType.symptom,
      date: DateTime.now(),
      note: 'seemed off',
      tags: ['vomiting', 'lethargy'],
    );
    await db.insertLog(log);

    // Fetch and verify
    final logs = await db.fetchLogs([savedPet]);
    expect(logs, isNotEmpty);
    expect(logs.first.tags, isNotNull);
    expect(logs.first.tags!.length, 2);
    expect(logs.first.tags!.contains('vomiting'), true);

    // Cleanup
    await client.from('symptoms').delete().eq('pet_id', savedPet.id!);
    await client.from('pets').delete().eq('id', savedPet.id!);
  });

  test('D3: insertLog diet round-trip', () async {
    final db = PawTrackDatabase(client);

    // Create test pet
    final pet = Pet(name: '__test_diet__', breed: 'Beagle', type: 'Dog');
    final savedPet = await db.insertPet(pet);

    // Insert diet log
    final log = HealthLog(
      petName: savedPet.name,
      petId: savedPet.id,
      type: LogType.diet,
      date: DateTime.now(),
      note: '',
      foodBrand: 'Blue Buffalo',
      portionSize: '2',
      portionUnit: 'cups',
    );
    await db.insertLog(log);

    // Fetch and verify
    final logs = await db.fetchLogs([savedPet]);
    expect(logs, isNotEmpty);
    expect(logs.first.foodBrand, 'Blue Buffalo');

    // Cleanup
    await client.from('diet_entries').delete().eq('pet_id', savedPet.id!);
    await client.from('pets').delete().eq('id', savedPet.id!);
  });

  test('D4: insertLog vaccine round-trip', () async {
    final db = PawTrackDatabase(client);

    // Create test pet
    final pet = Pet(name: '__test_vaccine__', breed: 'Shepherd', type: 'Dog');
    final savedPet = await db.insertPet(pet);

    // Insert vaccine log
    final nextDue = DateTime.now().add(Duration(days: 365));
    final log = HealthLog(
      petName: savedPet.name,
      petId: savedPet.id,
      type: LogType.vaccine,
      date: DateTime.now(),
      note: '',
      vaccineName: 'Rabies',
      nextDueDate: nextDue,
    );
    await db.insertLog(log);

    // Fetch and verify
    final logs = await db.fetchLogs([savedPet]);
    expect(logs, isNotEmpty);
    expect(logs.first.vaccineName, 'Rabies');
    expect(logs.first.nextDueDate, isNotNull);

    // Cleanup
    await client.from('vaccinations').delete().eq('pet_id', savedPet.id!);
    await client.from('pets').delete().eq('id', savedPet.id!);
  });

  test('D5: insertLog medication round-trip', () async {
    final db = PawTrackDatabase(client);

    // Create test pet
    final pet = Pet(name: '__test_med__', breed: 'Retriever', type: 'Dog');
    final savedPet = await db.insertPet(pet);

    // Insert medication log
    final log = HealthLog(
      petName: savedPet.name,
      petId: savedPet.id,
      type: LogType.medication,
      date: DateTime.now(),
      note: '',
      medicationName: 'Heartgard',
      dose: '1 tablet',
      frequency: 'Every 30 days',
    );
    await db.insertLog(log);

    // Fetch and verify
    final logs = await db.fetchLogs([savedPet]);
    expect(logs, isNotEmpty);
    expect(logs.first.medicationName, 'Heartgard');
    expect(logs.first.dose, '1 tablet');
    expect(logs.first.frequency, 'Every 30 days');

    // Cleanup
    await client.from('medications').delete().eq('pet_id', savedPet.id!);
    await client.from('pets').delete().eq('id', savedPet.id!);
  });

  test('D6: insertLog throws ArgumentError when petId is null', () async {
    final db = PawTrackDatabase(client);

    final log = HealthLog(
      petName: 'Test',
      petId: null,
      type: LogType.weight,
      date: DateTime.now(),
      note: '',
      weight: 50,
    );

    expect(() => db.insertLog(log), throwsA(isA<ArgumentError>()));
  });

  test('D7: fetchLogs returns empty list when no pets', () async {
    final db = PawTrackDatabase(client);
    final logs = await db.fetchLogs([]);
    expect(logs, isEmpty);
  });

  test('D8: fetchLogs returns logs sorted newest-first', () async {
    final db = PawTrackDatabase(client);

    // Create test pet
    final pet = Pet(name: '__test_sort__', breed: 'Mix', type: 'Dog');
    final savedPet = await db.insertPet(pet);

    // Insert two weight logs with different dates
    final olderDate = DateTime.now().subtract(Duration(days: 1));
    final newerDate = DateTime.now();

    final log1 = HealthLog(
      petName: savedPet.name,
      petId: savedPet.id,
      type: LogType.weight,
      date: olderDate,
      note: '',
      weight: 50,
    );
    final log2 = HealthLog(
      petName: savedPet.name,
      petId: savedPet.id,
      type: LogType.weight,
      date: newerDate,
      note: '',
      weight: 51,
    );

    await db.insertLog(log1);
    await db.insertLog(log2);

    // Fetch and verify order
    final logs = await db.fetchLogs([savedPet]);
    expect(logs.length, greaterThanOrEqualTo(2));
    expect(logs.first.date.isAfter(logs.last.date), true);

    // Cleanup
    await client.from('weight_entries').delete().eq('pet_id', savedPet.id!);
    await client.from('pets').delete().eq('id', savedPet.id!);
  });
}

class _InMemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> getItem({required String key}) async => _map[key];

  @override
  Future<void> removeItem({required String key}) async {
    _map.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _map[key] = value;
  }
}
