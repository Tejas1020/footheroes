import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/midnight_pitch_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline-first storage
  await Hive.initFlutter();
  await Hive.openBox<Map>('pending_events');
  await Hive.openBox<Map>('active_match');
  await Hive.openBox<Map>('local_ratings');

  runApp(const ProviderScope(child: FootheroesApp()));
}

class FootheroesApp extends ConsumerWidget {
  const FootheroesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Footheroes',
      debugShowCheckedModeBanner: false,
      theme: MidnightPitchTheme.themeData,
      routerConfig: router,
    );
  }
}