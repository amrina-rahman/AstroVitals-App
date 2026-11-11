import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';
import 'data/account_repository.dart';
import 'data/health_reference_thresholds.dart';
import 'data/health_repository.dart';
import 'health_page.dart';
import 'models/astro_vitals_user.dart';
import 'profile_page.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isConfigured) {
    runApp(const AstroVitalsApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    publishableKey: SupabaseConfig.publishableKey,
  );
  final accountRepository = SupabaseAccountRepository(Supabase.instance.client);
  final healthRepository = SupabaseHealthRepository(Supabase.instance.client);
  final signedInUser = await accountRepository.currentUser();
  runApp(
    AstroVitalsApp(
      accountRepository: accountRepository,
      healthRepository: healthRepository,
      initialUser: signedInUser,
    ),
  );
}

class AstroVitalsApp extends StatefulWidget {
  const AstroVitalsApp({
    this.accountRepository,
    this.healthRepository,
    this.healthThresholds = HealthReferenceThresholds.prototypeDefaults,
    this.initialUser,
    super.key,
  });

  final AccountRepository? accountRepository;
  final HealthRepository? healthRepository;
  final HealthReferenceThresholds healthThresholds;
  final AstroVitalsUser? initialUser;

  @override
  State<AstroVitalsApp> createState() => _AstroVitalsAppState();
}

class _AstroVitalsAppState extends State<AstroVitalsApp> {
  late AstroVitalsUser? _signedInUser = widget.initialUser;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF167D78);

    return MaterialApp(
      title: 'AstroVitals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
        useMaterial3: true,
      ),
      home: widget.accountRepository == null
          ? const _SupabaseSetupPage()
          : _signedInUser == null
          ? AuthPage(
              accountRepository: widget.accountRepository!,
              onAuthenticated: (user) {
                setState(() {
                  _signedInUser = user;
                });
              },
            )
          : _AppShell(
              user: _signedInUser!,
              accountRepository: widget.accountRepository!,
              healthRepository: widget.healthRepository,
              healthThresholds: widget.healthThresholds,
              onProfileUpdated: (user) {
                setState(() {
                  _signedInUser = user;
                });
              },
              onSignOut: () async {
                await widget.accountRepository!.signOut();
                if (!mounted) return;
                setState(() {
                  _signedInUser = null;
                });
              },
            ),
    );
  }
}

class _SupabaseSetupPage extends StatelessWidget {
  const _SupabaseSetupPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect AstroVitals to Supabase',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add your Supabase project URL and publishable anon key '
                    'to lib/supabase_config.dart, then restart the app.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({
    required this.user,
    required this.accountRepository,
    required this.healthRepository,
    required this.healthThresholds,
    required this.onProfileUpdated,
    required this.onSignOut,
  });

  final AstroVitalsUser user;
  final AccountRepository accountRepository;
  final HealthRepository? healthRepository;
  final HealthReferenceThresholds healthThresholds;
  final ValueChanged<AstroVitalsUser> onProfileUpdated;
  final Future<void> Function() onSignOut;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  static const _destinations = [
    _AppDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _AppDestination(
      label: 'Health',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    _AppDestination(
      label: 'History',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    _AppDestination(
      label: 'Devices',
      icon: Icons.watch_outlined,
      selectedIcon: Icons.watch_rounded,
    ),
    _AppDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 760;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _destinations[_selectedIndex].label == 'Home'
                  ? 'AstroVitals'
                  : _destinations[_selectedIndex].label,
            ),
            actions: [
              TextButton.icon(
                key: const ValueKey('sign-out'),
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (useRail) ...[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (var index = 0; index < _destinations.length; index++)
                      _destinations[index].railDestination(),
                  ],
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _HomePage(
                      user: widget.user,
                      onOpenDestination: _selectDestination,
                    ),
                    widget.healthRepository == null
                        ? const _ComingSoonPage(
                            title: 'Health',
                            icon: Icons.favorite_rounded,
                            description:
                                'Health data is not connected. Configure the '
                                'Supabase health tables and sign in again.',
                          )
                        : HealthPage(
                            key: const ValueKey('health-screen'),
                            repository: widget.healthRepository!,
                            thresholds: widget.healthThresholds,
                            initialWeightKg: widget.user.weightKg,
                            onWeightSaved: (weight) {
                              widget.onProfileUpdated(
                                widget.user.copyWith(weightKg: weight),
                              );
                            },
                          ),
                    const _ComingSoonPage(
                      title: 'History',
                      icon: Icons.insights_rounded,
                      description:
                          'Historical health records and daily or weekly '
                          'statistics are planned for a future update. No '
                          'history is available yet.',
                    ),
                    const _ComingSoonPage(
                      title: 'Devices',
                      icon: Icons.watch_rounded,
                      description:
                          'Wearable and medical-device management is planned '
                          'for a future update. No devices are connected.',
                    ),
                    ProfilePage(
                      key: const ValueKey('profile-screen'),
                      embedded: true,
                      user: widget.user,
                      onSave: (currentUser, updatedUser) async {
                        await widget.accountRepository.updateProfile(
                          currentUser: currentUser,
                          updatedUser: updatedUser,
                        );
                        widget.onProfileUpdated(updatedUser);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: [
                    for (var index = 0; index < _destinations.length; index++)
                      _destinations[index].bottomDestination(),
                  ],
                ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _signOut() async {
    try {
      await widget.onSignOut();
    } on AccountOperationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  NavigationDestination bottomDestination() => NavigationDestination(
    key: ValueKey('navigation-$label'),
    icon: Icon(icon),
    selectedIcon: Icon(selectedIcon),
    label: label,
  );

  NavigationRailDestination railDestination() => NavigationRailDestination(
    icon: Icon(icon, key: ValueKey('navigation-$label')),
    selectedIcon: Icon(selectedIcon),
    label: Text(label),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.user, required this.onOpenDestination});

  final AstroVitalsUser user;
  final ValueChanged<int> onOpenDestination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome, ${user.fullName}',
                        key: const ValueKey('home-welcome'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Astronaut ID: ${user.astronautId}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your astronaut profile is connected to your '
                        'AstroVitals account.',
                        style: TextStyle(color: Color(0xFF657370)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'App modules',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700
                      ? 4
                      : constraints.maxWidth >= 480
                      ? 2
                      : 1;
                  final cardWidth =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _HomeModuleCard(
                        width: cardWidth,
                        icon: Icons.favorite_rounded,
                        title: 'Health',
                        subtitle: 'Monitoring tools coming soon',
                        onTap: () => onOpenDestination(1),
                      ),
                      _HomeModuleCard(
                        width: cardWidth,
                        icon: Icons.insights_rounded,
                        title: 'History',
                        subtitle: 'Health trends coming soon',
                        onTap: () => onOpenDestination(2),
                      ),
                      _HomeModuleCard(
                        width: cardWidth,
                        icon: Icons.watch_rounded,
                        title: 'Devices',
                        subtitle: 'Device setup coming soon',
                        onTap: () => onOpenDestination(3),
                      ),
                      _HomeModuleCard(
                        width: cardWidth,
                        icon: Icons.person_rounded,
                        title: 'Profile',
                        subtitle: 'View and edit your details',
                        onTap: () => onOpenDestination(4),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeModuleCard extends StatelessWidget {
  const _HomeModuleCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFDCE5E2)),
        ),
        child: InkWell(
          key: ValueKey('home-module-$title'),
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFDCE5E2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(icon, color: colorScheme.primary, size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'COMING SOON',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: const Color(0xFF657370), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
