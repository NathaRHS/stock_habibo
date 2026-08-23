import 'package:flutter/material.dart';
import 'package:flutter_application/screens/ecran_login.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF064B9C),
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const EcranLogin(
        baseUrl: 'http://192.168.1.98:8080',
      ),
    );
  } 
}