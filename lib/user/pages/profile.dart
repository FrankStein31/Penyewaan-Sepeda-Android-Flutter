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
  Map<String, dynamic>? userProfile;

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
      final userId = await _storage.read(key: 'userId');

      setState(() {
        userName = username ?? 'Guest';
        userRole = level ?? 'User';
      });

      // Fetch user profile data
      if (userId != null) {
        try {
          final response = await http.get(
            Uri.parse('${Config.baseUrl}/users/$userId'),
            headers: {'Content-Type': 'application/json'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == true && data['data'] != null) {
              setState(() {
                userProfile = data['data'];
              });
            }
          }
        } catch (e) {
          debugPrint('Error fetching user profile: $e');
        }
      }

      debugPrint('userName: $userName, userRole: $userRole');
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Image.network(
                      '${Config.baseUrl.replaceAll('/api', '')}/' + imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Gagal memuat gambar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                    GestureDetector(
                      onTap: () {
                        if (userProfile?['profile_image'] != null &&
                            userProfile!['profile_image']
                                .toString()
                                .isNotEmpty) {
                          _showImageDialog(
                              userProfile!['profile_image'], 'Foto Profile');
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF8B5CF6),
                        backgroundImage: userProfile?['profile_image'] !=
                                    null &&
                                userProfile!['profile_image']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(
                                '${Config.baseUrl.replaceAll('/api', '')}/${userProfile!['profile_image']}')
                            : null,
                        child: userProfile?['profile_image'] == null ||
                                userProfile!['profile_image'].toString().isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
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

                // User Details Section
                if (userProfile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pribadi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (userProfile!['phone'] != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 18),
                              const SizedBox(width: 8),
                              Text('No HP: ${userProfile!['phone']}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (userProfile!['nik'] != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.credit_card, size: 18),
                              const SizedBox(width: 8),
                              Text('NIK: ${userProfile!['nik']}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (userProfile!['address'] != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.home, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child:
                                    Text('Alamat: ${userProfile!['address']}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (userProfile!['ktp_image'] != null &&
                            userProfile!['ktp_image']
                                .toString()
                                .isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.image, size: 18),
                              const SizedBox(width: 8),
                              const Text('Foto KTP:'),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showImageDialog(
                                    userProfile!['ktp_image'], 'Foto KTP'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(
                                    '${Config.baseUrl.replaceAll('/api', '')}/${userProfile!['ktp_image']}',
                                    width: 80,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Menu Items
                _buildMenuItem(Icons.person_outline, 'Edit Profile',
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(userData: widget.userData)),
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

  Widget _buildStatCard(String title, String value, IconData icon,
      {Color? color}) {
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
          final userRentals = allRentals
              .where((r) =>
                  (r['customer_name'] ?? '').toString().toLowerCase() ==
                  name.toLowerCase())
              .toList();
          final total = userRentals.length;
          final amount = userRentals.fold(
              0, (sum, r) => sum + ((r['total_amount'] ?? 0) as int));
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
