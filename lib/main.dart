import 'package:flutter/material.dart';
import 'auth/login.dart';
import 'auth/register.dart';
import 'auth/edit_profile.dart';
import 'petugas/app/home.dart';
import 'petugas/sidepages/product.dart';
import 'petugas/sidepages/kategory.dart';
import 'petugas/pages/product_status_page.dart';
import 'petugas/pages/rental_monitoring_page.dart';
import 'petugas/pages/penalty_report_page.dart';
import 'petugas/pages/blacklist_page.dart';
import 'petugas/pages/user_management_page.dart';
import 'user/pages/notification_page.dart';

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
        '/register': (context) => const RegisterScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/home': (context) => const HomePage(),
        '/product': (context) => const ProductPage(),
        '/category': (context) => const KategoryPage(),
        '/product-status': (context) => const ProductStatusPage(),
        '/rental-monitoring': (context) => const RentalMonitoringPage(),
        '/penalty-report': (context) => const PenaltyReportPage(),
        '/blacklist': (context) => const BlacklistPage(),
        '/user-management': (context) => const UserManagementPage(),
      },
    );
  }
}
