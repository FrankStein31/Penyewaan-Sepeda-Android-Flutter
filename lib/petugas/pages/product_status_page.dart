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

  // Tambah fungsi untuk update status
  Future<void> _updateProductStatus(
      int productId, String status, int quantity) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/products/$productId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status produk berhasil diupdate')),
        );
        _loadProducts();
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Gagal update status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Dialog untuk update status
  Future<void> _showUpdateStatusDialog(Map<String, dynamic> product) async {
    String selectedStatus = product['status'];
    int quantity = 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status Produk'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'tersedia', child: Text('Tersedia')),
                  DropdownMenuItem(value: 'disewa', child: Text('Disewa')),
                  DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
                  DropdownMenuItem(value: 'hilang', child: Text('Hilang')),
                ],
                onChanged: (value) {
                  setState(() => selectedStatus = value!);
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  hintText: 'Masukkan jumlah unit (0 atau lebih)',
                ),
                keyboardType: TextInputType.number,
                initialValue: '0',
                onChanged: (value) {
                  quantity = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (quantity >= 0) {
                _updateProductStatus(product['id'], selectedStatus, quantity);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jumlah tidak boleh negatif')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Update card widget untuk menampilkan detail stok
  Widget _buildProductCard(Map<String, dynamic> product) {
    final totalStock = product['total_stock'] ?? 0;
    final stockAvailable = product['stock_available'] ?? 0;
    final stockRented = product['disewa'] ?? 0;
    final stockDamaged = product['rusak'] ?? 0;
    final stockLost = product['hilang'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showUpdateStatusDialog(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (product['image'] != null)
                    Image.network(
                      '${Config.baseUrl}/${product['image']}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  else
                    const Icon(Icons.pedal_bike),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Kategori: ${product['category_name']}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Detail Stok:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStockInfo('Total', totalStock, Colors.purple),
                  _buildStockInfo('Tersedia', stockAvailable, Colors.green),
                  _buildStockInfo('Disewa', stockRented, Colors.blue),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStockInfo('Rusak', stockDamaged, Colors.orange),
                  _buildStockInfo('Hilang', stockLost, Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status Produk',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product['status']),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product['status'].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      itemCount: _getFilteredProducts().length,
                      itemBuilder: (context, index) {
                        final product = _getFilteredProducts()[index];
                        return _buildProductCard(product);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
