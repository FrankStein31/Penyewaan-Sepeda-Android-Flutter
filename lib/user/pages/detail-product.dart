import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config.dart';
import 'payment_webview.dart';

class DetailProductPage extends StatefulWidget {
  final int productId;

  const DetailProductPage({super.key, required this.productId});

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  Map<String, dynamic>? productData;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? paymentUrl;
  DateTime now = DateTime.now();
  int selectedDuration = 1; // Default duration 1 hour
  List<int> availableDurations = [1, 2, 3, 4, 5, 6]; // Available duration options in hours

  @override
  void initState() {
    super.initState();
    _initializeData();
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
            productData = data['data'];
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchProductDetails(),
      _fetchUserData(),
    ]);
  }

  Future<void> _fetchUserData() async {
    try {
      const storage = FlutterSecureStorage();
      final userId = await storage.read(key: 'userId');
      if (userId == null) return;

      debugPrint('Fetching user data for ID: $userId');
      debugPrint('Fetching username for user ID: $userId');
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('User data response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            userData = data['data'];
          });
          debugPrint('Found user data: $userData');
        }
      } else {
        debugPrint('Failed to get user data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<String?> _getUsernameById(String userId) async {
    try {
      debugPrint('Getting username for ID: $userId');
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Username response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final username = data['data']['username'];
          debugPrint('Found username: $username');
          return username;
        }
      }
    } catch (e) {
      debugPrint('Error getting username: $e');
    }
    return null;
  }

  Future<void> _createRental() async {
    if (productData == null) return;

    try {
      const storage = FlutterSecureStorage();
      final userId = await storage.read(key: 'userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        Navigator.pushNamed(context, '/login');
        return;
      }

      final username = await _getUsernameById(userId);
      if (username == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get username')),
        );
        return;
      }

      debugPrint('Creating rental with username: $username');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final startDateTime = DateTime.now();
      final endDateTime = startDateTime.add(Duration(hours: selectedDuration));

      final totalAmount = selectedDuration * (productData!['price'] ?? 0);

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/rentals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': productData!['id'],
          'user_id': int.parse(userId),
          'customer_name': username,
          'rental_hours': selectedDuration,
          'total_amount': totalAmount,
          'payment_status': 'pending',
          'payment_method': 'gopay',
          'start_time': startDateTime.toIso8601String(),
          'end_time': endDateTime.toIso8601String(),
        }),
      );

      Navigator.pop(context);

      debugPrint('Create rental response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final rentalId = data['data']['id'];
          await _initiatePayment(rentalId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to create rental')),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to create rental')),
        );
      }
    } catch (e) {
      debugPrint('Error creating rental: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _initiatePayment(int rentalId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Initiate payment with Midtrans
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/rentals/$rentalId/payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_method': 'gopay'
        }),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final paymentUrl = data['data']['redirect_url'];
          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            debugPrint('Opening payment URL: $paymentUrl');
            debugPrint('Opening payment URL in WebView: $paymentUrl');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebView(
                  url: paymentUrl,
                  rentalId: rentalId,
                ),
              ),
            );

            if (result == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment successful')),
              );
              Navigator.pop(context); // Back to home
            } else if (result == 'failed') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment failed')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment URL not found')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to initiate payment')),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to initiate payment')),
        );
      }
    } catch (e) {
      debugPrint('Error initiating payment: $e');
      Navigator.pop(context); // Close loading dialog if error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (productData == null) {
      return const Scaffold(
        body: Center(child: Text('Product not found')),
      );
    }

    final endTime = DateTime.now().add(Duration(hours: selectedDuration));
    final totalPrice = (productData!['price'] ?? 0) * selectedDuration;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          productData!['name'] ?? 'Unknown Product',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              productData!['name'] ?? 'Unknown Product',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: ClipOval(
                  child: productData != null && productData!['image'] != null
                      ? Image.network(
                          '${Config.baseUrl}/${productData!['image']}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.directions_bike,
                              size: 80,
                              color: Colors.black54,
                            );
                          },
                        )
                      : const Icon(
                          Icons.directions_bike,
                          size: 80,
                          color: Colors.black54,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Price Display
            Column(
              children: [
                Text(
                  'Harga per jam: ${formatRupiah(productData!['price'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(totalPrice),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's date display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tanggal Sewa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rental duration selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Durasi Sewa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement button
                      IconButton(
                        onPressed: () {
                          if (selectedDuration > 1) {
                            setState(() {
                              selectedDuration--;
                            });
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selectedDuration > 1 ? const Color(0xFF8B5CF6) : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove,
                            color: selectedDuration > 1 ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                      // Duration display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8B5CF6)),
                        ),
                        child: Text(
                          '$selectedDuration Jam',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      // Increment button
                      IconButton(
                        onPressed: () {
                          if (selectedDuration < 6) {
                            setState(() {
                              selectedDuration++;
                            });
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selectedDuration < 6 ? const Color(0xFF8B5CF6) : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: selectedDuration < 6 ? Colors.white : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mulai',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(endTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Bayar Button
            ElevatedButton(
              onPressed: () => _createRental(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Bayar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
