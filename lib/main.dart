import 'package:flutter/material.dart';

void main() {
  runApp(const PawTrackApp());
}

class PawTrackApp extends StatelessWidget {
  const PawTrackApp({super.key});

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
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PawTrack'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Add pet',
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Good evening, Aakash',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Here is what needs attention for your pets today.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const PetSummaryCard(
              name: 'Milo',
              details: 'Golden Retriever • 4 years',
              weight: '62.4 lb',
              nextCare: 'Heartworm dose tonight',
              color: Color(0xFF2F7D6B),
            ),
            const SizedBox(height: 12),
            const PetSummaryCard(
              name: 'Luna',
              details: 'Domestic Shorthair • 2 years',
              weight: '9.8 lb',
              nextCare: 'Rabies vaccine due soon',
              color: Color(0xFF7861A8),
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Today',
              actionLabel: 'View all',
              onAction: () {},
            ),
            const SizedBox(height: 10),
            const CareTaskTile(
              icon: Icons.medication_outlined,
              title: 'Milo medication',
              subtitle: 'Heartworm tablet • 8:00 PM',
            ),
            const CareTaskTile(
              icon: Icons.monitor_weight_outlined,
              title: 'Log Luna weight',
              subtitle: 'Weekly trend check',
            ),
            const CareTaskTile(
              icon: Icons.restaurant_outlined,
              title: 'Diet note',
              subtitle: 'Record dinner appetite for both pets',
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Pattern flags',
              actionLabel: 'Add log',
              onAction: () {},
            ),
            const SizedBox(height: 10),
            const PatternFlagCard(
              title: 'Milo weight changed',
              body:
                  'Logged weight is down 2.1 lb across the last 30 days. This is an observation from your records, not a diagnosis.',
            ),
            const SizedBox(height: 12),
            const PatternFlagCard(
              title: 'Luna vaccine window',
              body:
                  'Rabies vaccine appears due based on the date in her record. Confirm timing with your vet.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
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
        ],
      ),
    );
  }
}

class PetSummaryCard extends StatelessWidget {
  const PetSummaryCard({
    required this.name,
    required this.details,
    required this.weight,
    required this.nextCare,
    required this.color,
    super.key,
  });

  final String name;
  final String details;
  final String weight;
  final String nextCare;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(Icons.pets, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(details),
                  const SizedBox(height: 8),
                  Text(
                    nextCare,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              weight,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class CareTaskTile extends StatelessWidget {
  const CareTaskTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Checkbox(value: false, onChanged: (_) {}),
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
      elevation: 0,
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
