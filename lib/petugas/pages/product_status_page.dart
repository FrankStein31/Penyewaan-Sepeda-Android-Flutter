import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class ProductStatusPage extends StatefulWidget {
  const ProductStatusPage({super.key});

  @override
  State<ProductStatusPage> createState() => _ProductStatusPageState();
}

class _ProductStatusPageState extends State<ProductStatusPage> {
  List<dynamic> _products = [];
  String _selectedStatus = 'semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/products'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = data['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'tersedia':
        return Colors.green;
      case 'disewa':
        return Colors.blue;
      case 'rusak':
        return Colors.orange;
      case 'hilang':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<dynamic> _getFilteredProducts() {
    if (_selectedStatus == 'semua') {
      return _products;
    }
    return _products.where((p) => p['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Sepeda'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter Status: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'semua', child: Text('Semua')),
                    DropdownMenuItem(
                        value: 'tersedia', child: Text('Tersedia')),
                    DropdownMenuItem(value: 'disewa', child: Text('Disewa')),
                    DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
                    DropdownMenuItem(value: 'hilang', child: Text('Hilang')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      itemCount: _getFilteredProducts().length,
                      itemBuilder: (context, index) {
                        final product = _getFilteredProducts()[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: product['image'] != null
                                ? Image.network(
                                    '${Config.baseUrl}/${product['image']}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.pedal_bike),
                            title: Text(product['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kategori: ${product['category_name']}'),
                                Text('Stok: ${product['stock']}'),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _getStatusColor(product['status']),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product['status'].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (product['active_rentals'] > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sedang disewa: ${product['active_rentals']}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              // TODO: Tampilkan detail produk dan riwayat penyewaan
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
