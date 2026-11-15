import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'client.dart';
import 'screens/greetings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const MyApp());
}

/// Builds a theme for the given [brightness].
ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MadMaps',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'MadMaps — connection check'),
    );
  }
}

class ContributorAccountPage extends StatelessWidget {
  const ContributorAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: client.auth.authInfoListenable,
      builder: (context, _) {
        if (client.auth.isAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Contributor account')),
            body: Center(
              child: FilledButton(
                onPressed: client.auth.signOutDevice,
                child: const Text('Sign out'),
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Sign in to contribute')),
          body: SignInWidget(
            client: client,
            onAuthenticated: () {},
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sign-in failed: $error')),
              );
            },
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ListenableBuilder(
            listenable: client.auth.authInfoListenable,
            builder: (context, _) => IconButton(
              tooltip: client.auth.isAuthenticated
                  ? 'Contributor account'
                  : 'Sign in to contribute',
              icon: Icon(
                client.auth.isAuthenticated
                    ? Icons.account_circle
                    : Icons.login,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ContributorAccountPage(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: const GreetingsScreen(),
    );
  }
}
