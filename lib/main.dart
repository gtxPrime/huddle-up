// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/screens/home_screen.dart';
import 'services/game_storage.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage, audio & AdMob
  await GameStorage.init();
  await AdService.init();
  await AudioService.init();
  AudioService.startMusic();

  // Portrait lock strictly
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Immersive mode
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1B2A),
  ));
  runApp(const ProviderScope(child: HuddleUpApp()));
}

class HuddleUpApp extends StatelessWidget {
  const HuddleUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huddle Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2196F3),
          secondary: Colors.lightBlueAccent,
          surface: Color(0xFF1B2631),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
