import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../pages/activity.dart';
import '../pages/report.dart';
import '../pages/profile.dart';
import '../../config.dart';
import 'detail.dart';
import 'product_detail.dart';
import '../app/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      drawer: AdminDrawer(
        username: userData != null ? userData!['name'] ?? 'Admin' : 'Admin',
        onLogout: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (Route<dynamic> route) => false,
          );
        },
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
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String selectedCategory = 'Semua';
  String selectedSort = 'Nama';
  List<String> categories = ['Semua'];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _fetchProducts();
    setState(() {
      allProducts = products;
      filteredProducts = products;

      // Extract unique categories
      final Set<String> uniqueCategories = {'Semua'};
      for (var product in products) {
        if (product['category_name'] != null) {
          uniqueCategories.add(product['category_name']);
        }
      }
      categories = uniqueCategories.toList();
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(allProducts);

    // Filter by category
    if (selectedCategory != 'Semua') {
      filtered = filtered
          .where((product) => product['category_name'] == selectedCategory)
          .toList();
    }

    // Sort by selected criteria
    switch (selectedSort) {
      case 'Nama':
        filtered.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'Harga Terendah':
        filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
      case 'Harga Tertinggi':
        filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        break;
      case 'Stok Terbanyak':
        filtered.sort((a, b) =>
            (b['stock_available'] ?? 0).compareTo(a['stock_available'] ?? 0));
        break;
      case 'Stok Terdikit':
        filtered.sort((a, b) =>
            (a['stock_available'] ?? 0).compareTo(b['stock_available'] ?? 0));
        break;
    }

    setState(() {
      filteredProducts = filtered;
    });
  }

  String formatRupiah(dynamic number) {
    if (number == null) return 'IDR 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
    final name = product['name'] ?? 'Unknown';
    final price = formatRupiah(product['price']);
    final totalStock = product['total_stock']?.toString() ?? '0';
    final stockAvailable = product['stock_available']?.toString() ?? '0';
    final stockRented = product['disewa']?.toString() ?? '0';
    final stockDamaged = product['rusak']?.toString() ?? '0';
    final stockLost = product['hilang']?.toString() ?? '0';
    final imageUrl = product['image'] ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: product['id']?.toString() ?? '',
              name: name,
              price: (product['price'] as num?)?.toDouble() ?? 0.0,
              stock: (product['total_stock'] as num?)?.toInt() ?? 0,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(
                    imageUrl.isNotEmpty
                        ? '${Config.baseUrl}/$imageUrl'
                        : 'https://via.placeholder.com/60',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Info
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStockInfo('Total', totalStock, Colors.purple),
                      const SizedBox(width: 8),
                      _buildStockInfo('Tersedia', stockAvailable, Colors.green),
                      const SizedBox(width: 8),
                      _buildStockInfo('Disewa', stockRented, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStockInfo('Rusak', stockDamaged, Colors.orange),
                      const SizedBox(width: 8),
                      _buildStockInfo('Hilang', stockLost, Colors.red),
                    ],
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

  Widget _buildStockInfo(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          // Add drawer functionality here
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      const Text(
                        'Sewa Sepeda',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
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
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.purple,
                                  ),
                                  child: const Text('Home'),
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

                          // Filter and Sort Section
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                // Category Filter
                                Container(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      final isSelected =
                                          selectedCategory == category;
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          label: Text(category),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              selectedCategory = category;
                                            });
                                            _applyFilters();
                                          },
                                          backgroundColor: Colors.grey[200],
                                          selectedColor:
                                              const Color(0xFF8B5CF6),
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Sort Dropdown
                                Row(
                                  children: [
                                    const Text(
                                      'Urutkan: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedSort,
                                            isExpanded: true,
                                            items: [
                                              'Nama',
                                              'Harga Terendah',
                                              'Harga Tertinggi',
                                              'Stok Terbanyak',
                                              'Stok Terdikit',
                                            ].map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  selectedSort = newValue;
                                                });
                                                _applyFilters();
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Customer list with FutureBuilder
                          Expanded(
                            child: filteredProducts.isEmpty
                                ? const Center(
                                    child:
                                        Text('Tidak ada produk yang ditemukan'))
                                : ListView.builder(
                                    itemCount: filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = filteredProducts[index];
                                      return _buildProductItem(
                                          context, product);
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
}
