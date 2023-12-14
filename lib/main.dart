

import 'package:chillout_hrm/pages/scan_page.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'package:chillout_hrm/global.dart';
import 'package:flutter/services.dart';

void main() {
  // Lock device in landscape mode
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((value) => runApp(const MyApp()));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Application name
  final String _appTitle = "YogaBodyTracker";

  // Dark green color which is used to generate the ColorScheme for the Theme
  final Color _seedColor = const Color(0xff2e7d32);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      theme: ThemeData(
        // Theme with a dark green primary color
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        useMaterial3: true,
      ),
      initialRoute: homeRoute,
      routes: {
        homeRoute: (context) => const HomePage(),
        scanRoute: (context) => const ScanPage(),
      },
    );
  }
}
