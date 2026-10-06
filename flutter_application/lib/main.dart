import 'package:flutter/material.dart';
import 'package:flutter_application/screens/ecran_login.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8080',
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habibo Group',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF064B9C)),
        fontFamily: 'Inter',
        useMaterial3: true,
        // Pas d'ondulation Material au toucher : un simple voile gris.
        splashFactory: NoSplash.splashFactory,
        highlightColor: const Color(0x0F18212A),
      ),
      home: const EcranLogin(baseUrl: apiBaseUrl),
    );
  }
}
