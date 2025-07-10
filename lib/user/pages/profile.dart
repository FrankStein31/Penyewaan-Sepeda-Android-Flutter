import 'package:flutter/material.dart';
import 'edit-profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

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

  // Statistics
  int totalRentals = 0;
  int totalPenalties = 0;
  int unpaidPenalties = 0;
  int activeRentals = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      final username = await _storage.read(key: 'username');
      final level = await _storage.read(key: 'level');
      final token = await _storage.read(key: 'token');

      setState(() {
        userName = username ?? 'Guest';
        userRole = level ?? 'User';
      });

      // Fetch user rentals and calculate statistics
      if (username != null && token != null) {
        try {
          final response = await http.get(
            Uri.parse('${Config.apiUrl}/rentals'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> rentals = json.decode(response.body);
            int active = 0;
            int penalties = 0;
            int unpaid = 0;

            for (var rental in rentals) {
              final String rentalId = rental['id'].toString();
              
              // Check if rental is active
              if (rental['returnDate'] == null && rental['stopDate'] == null) {
                // Get payment status for active rental
                final paymentResponse = await http.get(
                  Uri.parse('${Config.apiUrl}/rentals/$rentalId/payment'),
                  headers: {
                    'Authorization': 'Bearer $token',
                  },
                );

                if (paymentResponse.statusCode == 200) {
                  final paymentData = json.decode(paymentResponse.body);
                  // Only count as active if payment is completed
                  if (paymentData['status'] == 'settlement' || 
                      paymentData['status'] == 'capture') {
                    active++;
                  }
                }
              }
              
              // Check penalty status
              if (rental['penalty'] != null) {
                penalties++;
                // Get penalty payment status
                final penaltyResponse = await http.get(
                  Uri.parse('${Config.apiUrl}/rentals/$rentalId/penalty/payment/status'),
                  headers: {
                    'Authorization': 'Bearer $token',
                  },
                );

                if (penaltyResponse.statusCode == 200) {
                  final penaltyData = json.decode(penaltyResponse.body);
                  // Count as unpaid if no payment or payment not completed
                  if (penaltyData['status'] == null || 
                      (penaltyData['status'] != 'settlement' && 
                       penaltyData['status'] != 'capture')) {
                    unpaid++;
                  }
                } else {
                  // If can't get status, assume unpaid
                  unpaid++;
                }
              }
            }

            setState(() {
              totalRentals = rentals.length;
              activeRentals = active;
              totalPenalties = penalties;
              unpaidPenalties = unpaid;
            });
          }
        } catch (e) {
          debugPrint('Error fetching rentals and payment data: $e');
        }
      }

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
                const SizedBox(height: 25),


                // Menu Items
                _buildMenuItem(Icons.person_outline, 'Edit Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage(userData: widget.userData)),
                    )),
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

  Widget _buildStatCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color ?? const Color(0xFF8B5CF6),
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchRentalSummaryByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final allRentals = List<Map<String, dynamic>>.from(data['data']);
          final userRentals = allRentals.where((r) => (r['customer_name'] ?? '').toString().toLowerCase() == name.toLowerCase()).toList();
          final total = userRentals.length;
          final amount = userRentals.fold(0, (sum, r) => sum + ((r['total_amount'] ?? 0) as int));
          return {'total': total, 'amount': amount};
        }
      }
      return {'total': 0, 'amount': 0};
    } catch (e) {
      debugPrint('Error fetch rental summary: $e');
      return {'total': 0, 'amount': 0};
    }
  }

  String formatRupiah(dynamic number) {
    if (number == null) return '0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(number).trim();
  }
}