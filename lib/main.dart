import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'petugas/app/home.dart';
import 'petugas/sidepages/product.dart';
import 'petugas/sidepages/kategory.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sewa Sepeda',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/product': (context) => const ProductPage(),
        '/category': (context) => const KategoryPage(),
      },
    );
  }
}
