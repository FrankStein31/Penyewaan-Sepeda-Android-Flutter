import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../config.dart';
import '../pages/activity.dart';
import '../pages/detail-product.dart';
import '../pages/report.dart';
import '../pages/profile.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? userData;

  final List<Widget> _pages = [
    const HomeContent(),
    const ActivityPage(),
    const ReportPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userName = await storage.read(key: 'userName');
      final userRole = await storage.read(key: 'userRole');

      // Tambahkan print untuk debugging
      debugPrint('Loaded userName: $userName');
      debugPrint('Loaded userRole: $userRole');

      if (mounted) {
        setState(() {
          userData = {
            'name': userName ?? 'Guest',
            'role': userRole ?? 'User',
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Sewa Sepeda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aplikasi Sewa Sepeda',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
           
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: () {
                // Close drawer
                Navigator.pop(context);
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Langsung navigate ke login tanpa menghapus storage
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_activity),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          backgroundColor: const Color(0xFF8B5CF6),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

// Pindahkan konten home ke widget terpisah
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  String formatRupiah(dynamic number) {
    if (number == null) return 'IDR 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/products'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with hamburger button, title, and notification icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person),
                        onPressed: () {},
                      ),
                      const Text(
                        'Sewa User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Logout'),
                                content: const Text('Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        '/login',
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Purple card with admin info
                  FutureBuilder<String?>(
                    future: Future.wait([
                      const FlutterSecureStorage().read(key: 'username'),
                      const FlutterSecureStorage().read(key: 'level'),
                    ]).then((values) => '${values[0]}|${values[1]}'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final String userName;
                      final String userRole;

                      if (snapshot.hasData && snapshot.data != null) {
                        final parts = snapshot.data!.split('|');
                        userName = parts[0];
                        userRole = parts.length > 1 ? parts[1] : 'User';
                      } else {
                        userName = 'Guest';
                        userRole = 'User';
                      }

                      debugPrint('userName: $userName, userRole: $userRole');

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hello,',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Rental Rules',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Silahkan memilih sepeda yang ingin kamu sewa',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.warning_rounded,
                                                      color: Colors.red[700],
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Keterlambatan akan dikenakan denda Rp 5.000 per 5 menit',
                                                        style: TextStyle(
                                                          color: Colors.red[700],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'Batal',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                // TODO: Navigate to bike selection
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF8B5CF6),
                                              ),
                                              child: const Text('Pilih Sepeda'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.purple,
                                  ),
                                  child: const Text('Rental Now'),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.directions_bike,
                              size: 60,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Customer section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Products',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('See All'),
                              ),
                            ],
                          ),

                          // Products list with FutureBuilder
                          Expanded(
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchProducts(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                }

                                final products = snapshot.data ?? [];
                                if (products.isEmpty) {
                                  return const Center(
                                      child: Text('No products found'));
                                }

                                return ListView.builder(
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final product = products[index];
                                    return _buildProductItem(
                                      context,
                                      product['name'] ?? 'Unknown',
                                      formatRupiah(product['price']),
                                      product['category_name'] ?? 'No Category',
                                      product['stock']?.toString() ?? '0',
                                      productId: product['id'] ?? 0,
                                      imageUrl: product['image'],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
      BuildContext context,
      String name,
      String price,
      String category,
      String stock,
      {required int productId,
      String? imageUrl}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProductPage(productId: productId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${Config.baseUrl}/uploads/products/${imageUrl.split('/').last}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.pedal_bike,
                            color: Color(0xFF8B5CF6),
                            size: 24,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.pedal_bike,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$price • Stock: $stock',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    category,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
