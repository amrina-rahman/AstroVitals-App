import 'package:flutter/material.dart';

import 'auth_page.dart';
import 'data/account_repository.dart';
import 'models/astro_vitals_user.dart';

void main() {
  runApp(const AstroVitalsApp());
}

class AstroVitalsApp extends StatefulWidget {
  const AstroVitalsApp({super.key});

  @override
  State<AstroVitalsApp> createState() => _AstroVitalsAppState();
}

class _AstroVitalsAppState extends State<AstroVitalsApp> {
  final AccountRepository _accountRepository = InMemoryAccountRepository();
  AstroVitalsUser? _signedInUser;

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
      home: _signedInUser == null
          ? AuthPage(
              accountRepository: _accountRepository,
              onAuthenticated: (user) {
                setState(() {
                  _signedInUser = user;
                });
              },
            )
          : _WelcomePage(
              user: _signedInUser!,
              onSignOut: () {
                setState(() {
                  _signedInUser = null;
                });
              },
            ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.user, required this.onSignOut});

  final AstroVitalsUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AstroVitals'),
        actions: [
          TextButton(onPressed: onSignOut, child: const Text('Sign out')),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user.fullName}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Astronaut ID: ${user.astronautId}',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                const Text(
                  'You’re signed in. Your account is stored only while this '
                  'app is open and will be cleared when it closes.',
                  style: TextStyle(color: Color(0xFF657370)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
