import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_hub/firebase_options.dart';
import 'core/providers/provider_logger.dart';
import 'core/providers/theme_provider.dart';
import 'data/models/note_model.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/state_management/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: Ensure you have added google-services.json/GoogleService-Info.plist
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());
  
  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      child: const SmartHubApp(),
    ),
  );
}

class SmartHubApp extends ConsumerWidget {
  const SmartHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SmartHub',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: authState.when(
        data: (user) {
          if (user != null) return const MainScreen();
          return const AuthScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
