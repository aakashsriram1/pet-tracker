import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final authService = await SupabasePawTrackAuth.bootstrap();
  runApp(PawTrackApp(authService: authService));
}

class PawTrackApp extends StatelessWidget {
  const PawTrackApp({required this.authService, super.key});

  final PawTrackAuth authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F7D6B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        useMaterial3: true,
      ),
      home: AuthGate(authService: authService),
    );
  }
}

abstract class PawTrackAuth {
  bool get isConfigured;
  String? get currentEmail;
  Stream<bool> authChanges();
  Future<bool> hasSession();
  Future<bool> signIn(String email, String password);
  Future<bool> signUp(String email, String password);
  Future<void> signOut();
}

class SupabasePawTrackAuth implements PawTrackAuth {
  SupabasePawTrackAuth._(this._client);

  final SupabaseClient? _client;

  static Future<SupabasePawTrackAuth> bootstrap() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      return SupabasePawTrackAuth._(null);
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    return SupabasePawTrackAuth._(Supabase.instance.client);
  }

  SupabaseClient get _readyClient {
    final client = _client;
    if (client == null) {
      throw const AuthSetupException(
        'Start with SUPABASE_URL and SUPABASE_ANON_KEY dart-defines.',
      );
    }
    return client;
  }

  @override
  bool get isConfigured => _client != null;

  @override
  String? get currentEmail => _client?.auth.currentUser?.email;

  @override
  Stream<bool> authChanges() {
    final client = _client;
    if (client == null) {
      return const Stream<bool>.empty();
    }

    return client.auth.onAuthStateChange.map((event) => event.session != null);
  }

  @override
  Future<bool> hasSession() async => _client?.auth.currentSession != null;

  @override
  Future<bool> signIn(String email, String password) async {
    final response = await _readyClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  @override
  Future<bool> signUp(String email, String password) async {
    final response = await _readyClient.auth.signUp(
      email: email,
      password: password,
    );
    return response.session != null;
  }

  @override
  Future<void> signOut() => _readyClient.auth.signOut();
}

abstract class PawTrackDatabaseI {
  Future<List<Pet>> fetchPets();
  Future<Pet> insertPet(Pet pet);
  Future<List<HealthLog>> fetchLogs(List<Pet> pets);
  Future<void> insertLog(HealthLog log);
}

class PawTrackDatabase implements PawTrackDatabaseI {
  final SupabaseClient _client;

  PawTrackDatabase(this._client);

  @override
  Future<List<Pet>> fetchPets() async {
    try {
      final response = await _client.from('pets').select().order('created_at', ascending: false);
      return (response as List).map((row) => Pet.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching pets: $e');
      return [];
    }
  }

  @override
  Future<Pet> insertPet(Pet pet) async {
    try {
      final data = pet.toMap();
      final response = await _client.from('pets').insert(data).select().single();
      return Pet.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('Error inserting pet: $e');
      rethrow;
    }
  }

  @override
  Future<List<HealthLog>> fetchLogs(List<Pet> pets) async {
    if (pets.isEmpty) return [];
    try {
      final allLogs = <HealthLog>[];
      final tables = [
        ('weight_entries', 'recorded_at', LogType.weight),
        ('symptoms', 'recorded_at', LogType.symptom),
        ('diet_entries', 'fed_at', LogType.diet),
        ('vaccinations', 'date_administered', LogType.vaccine),
        ('medications', 'start_date', LogType.medication),
      ];
      for (final (table, timeCol, logType) in tables) {
        try {
          final response = await _client.from(table).select().order(timeCol, ascending: false);
          for (final row in response as List) {
            final petId = (row as Map<String, dynamic>)['pet_id'] as String;
            final pet = pets.where((p) => p.id == petId).firstOrNull;
            if (pet != null) {
              allLogs.add(HealthLog.fromMap(logType, row as Map<String, dynamic>, pet.name));
            }
          }
        } catch (e) {
          print('Error fetching logs from $table: $e');
        }
      }
      allLogs.sort((a, b) => b.date.compareTo(a.date));
      return allLogs;
    } catch (e) {
      print('Error fetching logs: $e');
      return [];
    }
  }

  @override
  Future<void> insertLog(HealthLog log) async {
    if (log.petId == null) throw ArgumentError('log.petId must not be null');
    try {
      final table = _logTable(log.type);
      final data = log.toInsertMap();
      await _client.from(table).insert(data);
    } catch (e) {
      print('Error inserting log: $e');
      rethrow;
    }
  }

  String _logTable(LogType type) {
    switch (type) {
      case LogType.weight: return 'weight_entries';
      case LogType.symptom: return 'symptoms';
      case LogType.diet: return 'diet_entries';
      case LogType.vaccine: return 'vaccinations';
      case LogType.medication: return 'medications';
    }
  }
}

class FakePawTrackDatabase implements PawTrackDatabaseI {
  @override
  Future<List<Pet>> fetchPets() async => [];
  @override
  Future<Pet> insertPet(Pet pet) async => pet;
  @override
  Future<List<HealthLog>> fetchLogs(List<Pet> pets) async => [];
  @override
  Future<void> insertLog(HealthLog log) async {}
}

class AuthSetupException implements Exception {
  const AuthSetupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.authService, super.key});

  final PawTrackAuth authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<bool>? _authSubscription;
  bool _isLoading = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _hydrateSession();
    _authSubscription = widget.authService.authChanges().listen((isSignedIn) {
      if (mounted) {
        setState(() => _isSignedIn = isSignedIn);
      }
    });
  }

  Future<void> _hydrateSession() async {
    final hasSession = await widget.authService.hasSession();
    if (mounted) {
      setState(() {
        _isSignedIn = hasSession;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isSignedIn) {
      try {
        return AppShell(
          db: PawTrackDatabase(Supabase.instance.client),
        );
      } catch (e) {
        // Supabase not initialized (e.g., in tests) - create a mock database
        return AppShell(
          db: FakePawTrackDatabase(),
        );
      }
    }

    return LoginScreen(
      authService: widget.authService,
      onAuthenticated: () => setState(() => _isSignedIn = true),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authService,
    required this.onAuthenticated,
    super.key,
  });

  final PawTrackAuth authService;
  final VoidCallback onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final authenticated = _isSignUp
          ? await widget.authService.signUp(email, password)
          : await widget.authService.signIn(email, password);

      if (authenticated) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _message =
              'Check your email to confirm the account, then sign in here.';
        });
      }
    } on AuthException catch (error) {
      setState(() => _message = error.message);
    } on AuthSetupException catch (error) {
      setState(() => _message = error.message);
    } catch (_) {
      setState(() => _message = 'Unable to authenticate. Try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.pets, size: 56, color: colorScheme.primary),
                const SizedBox(height: 18),
                Text(
                  _isSignUp
                      ? 'Create your PawTrack account'
                      : 'Sign in to PawTrack',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track pet care, logs, reminders, and non-diagnostic observations in one place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                if (!widget.authService.isConfigured)
                  InfoBanner(
                    icon: Icons.key_off_outlined,
                    title: 'Supabase is not configured',
                    body:
                        'Run Flutter with SUPABASE_URL and SUPABASE_ANON_KEY dart-defines to enable login.',
                    color: colorScheme.errorContainer,
                  ),
                if (!widget.authService.isConfigured)
                  const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            key: const Key('login-email'),
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (!email.contains('@')) {
                                return 'Enter a valid email.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('login-password'),
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if ((value ?? '').length < 6) {
                                return 'Use at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            key: const Key('auth-submit'),
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _isSignUp
                                        ? Icons.person_add_alt_1
                                        : Icons.login,
                                  ),
                            label: Text(
                              _isSignUp ? 'Create account' : 'Sign in',
                            ),
                          ),
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _isSignUp = !_isSignUp;
                                    _message = null;
                                  }),
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Sign in'
                                  : 'New here? Create an account',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  InfoBanner(
                    icon: Icons.info_outline,
                    title: 'Login update',
                    body: _message!,
                    color: colorScheme.secondaryContainer,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.db,
    super.key,
  });

  final PawTrackDatabaseI db;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late List<Pet> _pets = [];
  late List<HealthLog> _logs = [];
  late List<CareTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pets = await widget.db.fetchPets();
      final logs = await widget.db.fetchLogs(pets);
      setState(() {
        _pets = pets;
        _logs = logs;
        // TODO: create care_tasks table in Supabase and persist CareTask
        _tasks = [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String get _title => switch (_selectedIndex) {
    0 => 'Pets',
    1 => 'Logs',
    2 => 'Care',
    _ => 'Insights',
  };

  String get _actionTooltip => switch (_selectedIndex) {
    0 => 'Add pet',
    1 => 'Add log',
    2 => 'Add care reminder',
    _ => 'Add log',
  };

  IconData get _actionIcon => switch (_selectedIndex) {
    0 => Icons.add_circle_outline,
    1 => Icons.note_add_outlined,
    2 => Icons.add_alarm_outlined,
    _ => Icons.note_add_outlined,
  };

  Future<void> _signOut() async {
    // TODO: wire up actual signout via Supabase auth
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _handlePrimaryAction() {
    switch (_selectedIndex) {
      case 0:
        _showAddPetSheet();
      case 1:
        _showAddLogSheet();
      case 2:
        _showAddTaskSheet();
      default:
        _showAddLogSheet();
    }
  }

  Future<void> _showAddPetSheet() async {
    final pet = await showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddPetSheet(),
    );

    if (pet != null) {
      setState(() => _pets.add(pet));
    }
  }

  Future<void> _showAddLogSheet() async {
    final log = await showModalBottomSheet<HealthLog>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddLogSheet(pets: _pets),
    );

    if (log != null) {
      setState(() => _logs.insert(0, log));
    }
  }

  Future<void> _showAddTaskSheet() async {
    final task = await showModalBottomSheet<CareTask>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddCareTaskSheet(pets: _pets),
    );

    if (task != null) {
      setState(() => _tasks.insert(0, task));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _selectedIndex,
        children: [
          PetsPage(pets: _pets, logs: _logs, onAddPet: _showAddPetSheet),
          LogsPage(logs: _logs, pets: _pets, onAddLog: _showAddLogSheet),
          CarePage(
            tasks: _tasks,
            onAddTask: _showAddTaskSheet,
            onToggleTask: (index, value) {
              setState(() => _tasks[index].completed = value);
            },
          ),
          InsightsPage(logs: _logs, tasks: _tasks, onAddLog: _showAddLogSheet),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: _actionTooltip,
        onPressed: _handlePrimaryAction,
        icon: Icon(_actionIcon),
        label: Text(_actionTooltip),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Pets',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Care',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}

class PetsPage extends StatelessWidget {
  const PetsPage({
    required this.pets,
    required this.logs,
    required this.onAddPet,
    super.key,
  });

  final List<Pet> pets;
  final List<HealthLog> logs;
  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        PageIntro(
          title: 'Pet profiles',
          body: 'Keep each pet profile, weight, notes, and care context close.',
          actionLabel: 'Add pet',
          onAction: onAddPet,
        ),
        if (pets.isEmpty)
          EmptyState(
            icon: Icons.pets_outlined,
            title: 'No pets yet',
            body: 'Add a pet to start tracking health history and reminders.',
            actionLabel: 'Add pet',
            onAction: onAddPet,
          )
        else
          ...pets.map(
            (pet) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PetSummaryCard(pet: pet, logs: logs),
            ),
          ),
      ],
    );
  }
}

class LogsPage extends StatelessWidget {
  const LogsPage({
    required this.logs,
    required this.pets,
    required this.onAddLog,
    super.key,
  });

  final List<HealthLog> logs;
  final List<Pet> pets;
  final VoidCallback onAddLog;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        PageIntro(
          title: 'Health logs',
          body:
              'Capture weight, diet, symptoms, vaccines, and medication notes.',
          actionLabel: 'Add log',
          onAction: pets.isEmpty ? null : onAddLog,
        ),
        if (logs.isEmpty)
          EmptyState(
            icon: Icons.event_note_outlined,
            title: 'No logs yet',
            body: 'Add a log to build a useful timeline for vet visits.',
            actionLabel: pets.isEmpty ? null : 'Add log',
            onAction: pets.isEmpty ? null : onAddLog,
          )
        else
          ...logs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HealthLogTile(log: log),
            ),
          ),
      ],
    );
  }
}

class CarePage extends StatelessWidget {
  const CarePage({
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    super.key,
  });

  final List<CareTask> tasks;
  final VoidCallback onAddTask;
  final void Function(int index, bool value) onToggleTask;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      children: [
        PageIntro(
          title: 'Care reminders',
          body: 'Track the next medication, vaccine, feeding, or appointment.',
          actionLabel: 'Add reminder',
          onAction: onAddTask,
        ),
        if (tasks.isEmpty)
          EmptyState(
            icon: Icons.notifications_outlined,
            title: 'No care tasks',
            body: 'Create a reminder so care routines do not get missed.',
            actionLabel: 'Add reminder',
            onAction: onAddTask,
          )
        else
          ...tasks.indexed.map((entry) {
            final (index, task) = entry;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CareTaskTile(
                task: task,
                onChanged: (value) => onToggleTask(index, value ?? false),
              ),
            );
          }),
      ],
    );
  }
}

class InsightsPage extends StatelessWidget {
  const InsightsPage({
    required this.logs,
    required this.tasks,
    required this.onAddLog,
    super.key,
  });

  final List<HealthLog> logs;
  final List<CareTask> tasks;
  final VoidCallback onAddLog;

  @override
  Widget build(BuildContext context) {
    final openTasks = tasks.where((task) => !task.completed).length;
    final weightLogs = logs.where((log) => log.type == LogType.weight).length;
    final symptomLogs = logs.where((log) => log.type == LogType.symptom).length;

    return PageScaffold(
      children: [
        PageIntro(
          title: 'Pattern flags',
          body:
              'Descriptive observations from logged data. PawTrack does not diagnose.',
          actionLabel: 'Add log',
          onAction: onAddLog,
        ),
        PatternFlagCard(
          title: '$openTasks open care reminders',
          body:
              'Observation from your logs: unfinished tasks may need attention today. Confirm care timing with your vet.',
        ),
        const SizedBox(height: 12),
        PatternFlagCard(
          title: '$weightLogs weight entries tracked',
          body:
              'Observation from your logs: weight history is available for trend review. This is not a diagnosis.',
        ),
        const SizedBox(height: 12),
        PatternFlagCard(
          title: '$symptomLogs recent symptom notes',
          body:
              'Observation from your logs: recurring symptoms should be reviewed with a veterinarian if they continue.',
        ),
      ],
    );
  }
}

class AddPetSheet extends StatefulWidget {
  const AddPetSheet({super.key});

  @override
  State<AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<AddPetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _notesController = TextEditingController();
  String _species = 'Dog';

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Pet(
        name: _nameController.text.trim(),
        type: _species,
        breed: _breedController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Add pet',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('pet-name-field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _species,
              decoration: const InputDecoration(labelText: 'Species'),
              items: const [
                DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _species = value ?? 'Dog'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(labelText: 'Breed'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('save-pet'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save pet'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddLogSheet extends StatefulWidget {
  const AddLogSheet({required this.pets, super.key});

  final List<Pet> pets;

  @override
  State<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<AddLogSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  late String _petName;
  LogType _type = LogType.weight;

  @override
  void initState() {
    super.initState();
    _petName = widget.pets.isNotEmpty ? widget.pets.first.name : '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      HealthLog(
        petName: _petName,
        type: _type,
        date: DateTime.now(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Add health log',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              key: const Key('log-pet-dropdown'),
              initialValue: _petName,
              decoration: const InputDecoration(labelText: 'Pet'),
              items: widget.pets
                  .map(
                    (pet) => DropdownMenuItem(
                      value: pet.name,
                      child: Text(pet.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _petName = value ?? _petName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LogType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Log type'),
              items: LogType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('log-note-field'),
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 4,
              validator: _required,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('save-log'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save log'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCareTaskSheet extends StatefulWidget {
  const AddCareTaskSheet({required this.pets, super.key});

  final List<Pet> pets;

  @override
  State<AddCareTaskSheet> createState() => _AddCareTaskSheetState();
}

class _AddCareTaskSheetState extends State<AddCareTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dueController = TextEditingController();
  late String _petName = widget.pets.first.name;

  @override
  void dispose() {
    _titleController.dispose();
    _dueController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      CareTask(
        petName: _petName,
        title: _titleController.text.trim(),
        dueText: _dueController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Add care reminder',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _petName,
              decoration: const InputDecoration(labelText: 'Pet'),
              items: widget.pets
                  .map(
                    (pet) => DropdownMenuItem(
                      value: pet.name,
                      child: Text(pet.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _petName = value ?? _petName),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dueController,
              decoration: const InputDecoration(labelText: 'Due'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

class Pet {
  final String? id;
  final String? ownerId;
  final String name;
  final String breed;
  final String type;
  final String? notes;

  Pet({
    this.id,
    this.ownerId,
    required this.name,
    required this.breed,
    required this.type,
    this.notes,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as String?,
      ownerId: map['owner_id'] as String?,
      name: map['name'] as String,
      breed: map['breed'] as String,
      type: map['type'] as String,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'type': type,
      // TODO: add notes column to pets table
      // TODO: add birth_date picker to AddPetSheet
    };
  }
}

class HealthLog {
  final String? id;
  final String? petId;
  final String petName;
  final LogType type;
  final DateTime date;
  final String note;
  final double? weight;
  final String? weightUnit;

  HealthLog({
    this.id,
    this.petId,
    required this.petName,
    required this.type,
    required this.date,
    required this.note,
    this.weight,
    this.weightUnit = 'lb',
  });

  factory HealthLog.fromMap(LogType logType, Map<String, dynamic> map, String petName) {
    DateTime date;
    String note = '';
    double? weight;
    String? weightUnit;

    switch (logType) {
      case LogType.weight:
        date = DateTime.parse(map['recorded_at'] as String);
        weight = (map['weight'] as num).toDouble();
        weightUnit = map['unit'] as String? ?? 'lb';
        break;
      case LogType.symptom:
        date = DateTime.parse(map['recorded_at'] as String);
        note = map['notes'] as String? ?? '';
        break;
      case LogType.diet:
        date = DateTime.parse(map['fed_at'] as String);
        note = '${map['food_type'] ?? ''} ${map['food_brand'] ?? ''}'.trim();
        break;
      case LogType.vaccine:
        date = DateTime.parse(map['date_administered'] as String);
        note = map['notes'] as String? ?? '';
        break;
      case LogType.medication:
        date = DateTime.parse(map['start_date'] as String);
        note = map['notes'] as String? ?? '';
        break;
    }

    return HealthLog(
      id: map['id'] as String?,
      petId: map['pet_id'] as String?,
      petName: petName,
      type: logType,
      date: date,
      note: note,
      weight: weight,
      weightUnit: weightUnit,
    );
  }

  Map<String, dynamic> toInsertMap() {
    final map = <String, dynamic>{'pet_id': petId};
    switch (type) {
      case LogType.weight:
        map['recorded_at'] = date.toIso8601String();
        map['weight'] = weight;
        map['unit'] = weightUnit;
        break;
      case LogType.symptom:
        map['recorded_at'] = date.toIso8601String();
        map['notes'] = note;
        break;
      case LogType.diet:
        map['fed_at'] = date.toIso8601String();
        break;
      case LogType.vaccine:
        map['date_administered'] = date.toIso8601String();
        map['notes'] = note;
        break;
      case LogType.medication:
        map['start_date'] = date.toIso8601String();
        map['notes'] = note;
        break;
    }
    return map;
  }
}

class CareTask {
  CareTask({
    required this.petName,
    required this.title,
    required this.dueText,
    this.completed = false,
  });

  final String petName;
  final String title;
  final String dueText;
  bool completed;
}

enum LogType { weight, symptom, diet, vaccine, medication }

extension LogTypeLabel on LogType {
  String get label => switch (this) {
    LogType.weight => 'Weight',
    LogType.symptom => 'Symptom',
    LogType.diet => 'Diet',
    LogType.vaccine => 'Vaccine',
    LogType.medication => 'Medication',
  };

  IconData get icon => switch (this) {
    LogType.weight => Icons.monitor_weight_outlined,
    LogType.symptom => Icons.sick_outlined,
    LogType.diet => Icons.restaurant_outlined,
    LogType.vaccine => Icons.vaccines_outlined,
    LogType.medication => Icons.medication_outlined,
  };
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: children,
      ),
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class FormSheet extends StatelessWidget {
  const FormSheet({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class PetSummaryCard extends StatelessWidget {
  const PetSummaryCard({required this.pet, required this.logs, super.key});

  final Pet pet;
  final List<HealthLog> logs;

  String? _getRecentWeight() {
    try {
      final recentWeight = logs
          .where((log) => log.petName == pet.name && log.type == LogType.weight)
          .firstOrNull;
      return recentWeight != null
          ? '${recentWeight.weight} ${recentWeight.weightUnit}'
          : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.pets,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text('${pet.type} • ${pet.breed}'),
                    ],
                  ),
                ),
                Text(
                  _getRecentWeight() ?? '—',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (pet.notes != null && pet.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(pet.notes!),
            ],
          ],
        ),
      ),
    );
  }
}

class HealthLogTile extends StatelessWidget {
  const HealthLogTile({required this.log, super.key});

  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(log.type.icon),
        title: Text('${log.petName} • ${log.type.label}'),
        subtitle: Text('${_formatDate(log.date)}\n${log.note}'),
        isThreeLine: true,
      ),
    );
  }
}

class CareTaskTile extends StatelessWidget {
  const CareTaskTile({required this.task, required this.onChanged, super.key});

  final CareTask task;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: task.completed,
        onChanged: onChanged,
        title: Text(task.title),
        subtitle: Text('${task.petName} • ${task.dueText}'),
        secondary: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class PatternFlagCard extends StatelessWidget {
  const PatternFlagCard({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return 'Required.';
  }
  return null;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}
