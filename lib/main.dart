import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants.dart';
import 'core/router/router.dart';
import 'providers/settings_notifier.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: SocietyApp()));
}

class SocietyApp extends ConsumerWidget {
  const SocietyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off the settings fetch immediately at startup
    ref.read(settingsNotifierProvider);
    
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'Society App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.theme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
