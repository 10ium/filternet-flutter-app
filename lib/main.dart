import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/main_screen.dart'; // Changed from home_screen.dart
import 'services/history_service.dart';

void main() async {
  // Ensure that Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the history service (Hive)
  await HistoryService().init();

  runApp(const FilterNetApp());
}

class FilterNetApp extends StatelessWidget {
  const FilterNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ChangeNotifierProvider to make the AppProvider available to all widgets
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'فیلترنت',
        debugShowCheckedModeBanner: false,

        // --- THEME DEFINITION ---
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          
          // Define Vazirmatn as the default font
          textTheme: GoogleFonts.vazirmatnTextTheme(
            Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),

          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
          
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[850],
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // --- PERSIAN LANGUAGE AND RTL SUPPORT ---
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fa'), // Persian
        ],
        locale: const Locale('fa'),

        // --- HOME PAGE ---
        home: const MainScreen(), // Changed from HomeScreen()
      ),
    );
  }
}
