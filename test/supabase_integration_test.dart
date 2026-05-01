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
