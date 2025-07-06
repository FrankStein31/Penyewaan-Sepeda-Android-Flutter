import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfilePage({super.key, this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'Guest';
  String userRole = 'User';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      final username = await _storage.read(key: 'username');
      final level = await _storage.read(key: 'level');

      setState(() {
        userName = username ?? 'Guest';
        userRole = level ?? 'User';
      });

      debugPrint('userName: $userName, userRole: $userRole');
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _handleLogout(BuildContext context) async {
    // Clear stored data
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'level');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Profile Picture and Info
                Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF8B5CF6),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userRole,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Menu Items
                
               
                _buildMenuItem(Icons.security, 'Security', onTap: () {}),
                _buildMenuItem(Icons.help_outline, 'Help Center', onTap: () {}),
                _buildMenuItem(
                  Icons.logout,
                  'Logout',
                  isLogout: true,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      {bool isLogout = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Icon(
          icon,
          size: 20,
          color: isLogout ? Colors.red : const Color(0xFF8B5CF6),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isLogout ? Colors.red : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: isLogout
            ? null
            : const Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.grey,
              ),
        onTap: onTap,
      ),
    );
  }
}
