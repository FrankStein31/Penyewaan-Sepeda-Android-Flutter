import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../config.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? productDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
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

  Future<void> _fetchProductDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/products/${widget.productId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            productDetails = Map<String, dynamic>.from(data['data']);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRentalsForProduct(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final allRentals = List<Map<String, dynamic>>.from(data['data']);
          // Pastikan productId dibandingkan dengan benar (int)
          return allRentals.where((r) => r['product_id']?.toString() == productId.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetch rentals for product: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image dengan efek transisi dan shadow
                        Hero(
                          tag: 'product-image-${widget.productId}',
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.32,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(36),
                                bottomRight: Radius.circular(36),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                              image: widget.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        '${Config.baseUrl}/${widget.imageUrl}',
                                      ),
                                      fit: BoxFit.contain,
                                    )
                                  : null,
                            ),
                            child: widget.imageUrl == null
                                ? const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 90,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Card utama info produk
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nama produk
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Harga
                              Text(
                                formatRupiah(widget.price),
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Badge stok
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: widget.stock > 0
                                          ? const Color(0xFF7C3AED).withOpacity(0.13)
                                          : Colors.red.withOpacity(0.13),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 20,
                                          color: widget.stock > 0
                                              ? const Color(0xFF7C3AED)
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          'Stock: ${widget.stock}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: widget.stock > 0
                                                ? const Color(0xFF7C3AED)
                                                : Colors.red,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Divider(color: Colors.grey[200], thickness: 1.2),
                              const SizedBox(height: 18),
                              // Deskripsi
                              const Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                                child: Text(
                                  productDetails?['description'] ?? 'Tidak ada deskripsi.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Divider(color: Colors.grey[200], thickness: 1.2),
                              const SizedBox(height: 16),
                              // Kategori
                              Row(
                                children: [
                                  const Icon(
                                    Icons.category_outlined,
                                    color: Color(0xFF7C3AED),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Kategori:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    productDetails?['category_name'] ?? 'Tidak ada kategori',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
