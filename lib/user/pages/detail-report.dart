import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/payment_webview.dart';

class DetailReportPage extends StatefulWidget {
  final Map<String, dynamic> rental;

  const DetailReportPage({super.key, required this.rental});

  @override
  State<DetailReportPage> createState() => _DetailReportPageState();
}

class _DetailReportPageState extends State<DetailReportPage> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  bool isProcessingPayment = false;
  String? paymentUrl;
  String? userName;
  String? userId;
  int lateMinutes = 0;
  Timer? _statusCheckTimer;
  String penaltyPaymentStatus = '';

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
    getUserData();
    checkPenaltyPaymentStatus();
  }

  Future<void> getUserData() async {
    try {
      const storage = FlutterSecureStorage();
      final username = await storage.read(key: 'username');
      final id =
          await storage.read(key: 'userId'); // Changed from 'id' to 'userId'

      if (username == null || id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Session telah berakhir. Silakan login kembali.')),
          );
          // Navigate to login page
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      setState(() {
        userName = username;
        userId = id;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _createPenaltyPayment() async {
    if (isProcessingPayment) return; // Prevent double tap

    // Cek jika denda sudah dibayar
    if ((widget.rental['penalty_payment_status'] ?? '').toString() == 'paid') {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Info'),
              content: const Text('Denda sudah dibayar!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    try {
      // Check if user data is available
      if (userId == null || userName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Data pengguna tidak tersedia. Silakan login ulang.')),
        );
        return;
      }

      setState(() => isProcessingPayment = true);

      // Create payment for penalty only
      final response = await http.post(
        Uri.parse(
            '${Config.baseUrl}/rentals/${widget.rental['id']}/penalty/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'payment_method': 'gopay'}),
      );

      debugPrint('Payment Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          final paymentUrl = responseData['data']['redirect_url'];
          if (paymentUrl != null) {
            final Uri url = Uri.parse(paymentUrl);
            if (await canLaunchUrl(url)) {
              // Launch payment in WebView
              if (mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentWebView(
                      url: paymentUrl,
                      rentalId: widget.rental['id'],
                      isPenaltyPayment: true,
                    ),
                  ),
                );

                if (result == 'success') {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Pembayaran denda berhasil!')),
                    );
                    Navigator.pop(context, true);
                  }
                  return;
                }
              }
              // Start checking payment status
              startStatusCheck();
              // Stay on screen and show message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Silakan selesaikan pembayaran di Midtrans')),
                );
                setState(() => isProcessingPayment = false);
              }
            } else {
              throw Exception('Could not launch $paymentUrl');
            }
          } else {
            throw Exception('Payment URL tidak ditemukan');
          }
        } else {
          throw Exception(
              responseData['message'] ?? 'Gagal membuat pembayaran');
        }
      } else {
        final errorData = json.decode(response.body);
        // Tambahkan pengecekan pesan error dari backend
        if (errorData['message'] != null &&
            errorData['message']
                .toString()
                .toLowerCase()
                .contains('denda sudah dibayar')) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Info'),
                  content: const Text('Denda sudah dibayar!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
          setState(() => isProcessingPayment = false);
          return;
        }
        // Jangan throw Exception jika error denda sudah dibayar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(errorData['message'] ?? 'Gagal membuat pembayaran')),
          );
        }
        setState(() => isProcessingPayment = false);
        return;
      }
    } catch (e) {
      debugPrint('Error creating payment: $e');
      if (mounted) {
        setState(() => isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> fetchProductDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/products/${widget.rental['product_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          setState(() {
            productData = responseData['data'];
            isLoading = false;
            // Calculate late minutes
            final remainingMinutes = widget.rental['remaining_minutes'] ?? 0;
            lateMinutes = remainingMinutes < 0 ? -remainingMinutes : 0;
          });
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> checkPenaltyPaymentStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.baseUrl}/rentals/${widget.rental['id']}/penalty/payment/status'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Payment status response: $responseData'); // Debug log

        if (mounted) {
          // Get status from response data
          final status = responseData['status'];
          final paymentData = responseData['data'];

          if (status == true && paymentData != null) {
            final transactionStatus =
                paymentData['transaction_status']?.toString().toLowerCase() ??
                    '';

            setState(() {
              penaltyPaymentStatus = transactionStatus;
            });

            // Check if payment is successful
            if (transactionStatus == 'settlement' ||
                transactionStatus == 'capture' ||
                transactionStatus == 'success') {
              _statusCheckTimer?.cancel();

              // Update penalty payment status in database
              try {
                final updateResponse = await http.put(
                  Uri.parse(
                      '${Config.baseUrl}/rentals/${widget.rental['id']}/penalty/payment/status'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                  body: json.encode({
                    'penalty_payment_status': 'paid',
                    'transaction_status': transactionStatus
                  }),
                );

                if (updateResponse.statusCode == 200) {
                  debugPrint('Successfully updated penalty payment status');
                } else {
                  debugPrint(
                      'Failed to update penalty payment status: ${updateResponse.body}');
                }
              } catch (updateError) {
                debugPrint(
                    'Error updating penalty payment status: $updateError');
              }

              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pembayaran denda berhasil!')),
                );
                // Refresh the page or navigate back
                Navigator.pop(context, true);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
    }
  }

  void startStatusCheck() {
    // Check status every 5 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkPenaltyPaymentStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final penaltyStatus = widget.rental['penalty_payment_status'] ?? '-';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Report',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      productData?['name'] ?? 'Sepeda Gunung',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      '( Denda )',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Circular Container with Bike Icon or Thumbs Up
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                      ),
                      child: Center(
                        child: widget.rental['penalty_amount'] > 0
                            ? Image.network(
                                productData?['image_url'] ?? '',
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.directions_bike,
                                    size: 80,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6),
                                    width: 3,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.thumb_up,
                                    size: 60,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Tampilkan total_amount
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Detail Pembayaran',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rental Time Details
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildTimeInfoRow(
                                    'Waktu Mulai',
                                    widget.rental['start_time'] != null
                                        ? DateFormat('dd MMM yyyy, HH:mm')
                                            .format(DateTime.parse(
                                                widget.rental['start_time']))
                                        : '-'),
                                const SizedBox(height: 8),
                                _buildTimeInfoRow(
                                    'Waktu Selesai',
                                    widget.rental['return_time'] != null
                                        ? DateFormat('dd MMM yyyy, HH:mm')
                                            .format(DateTime.parse(
                                                widget.rental['return_time']))
                                        : widget.rental['end_time'] != null
                                            ? DateFormat('dd MMM yyyy, HH:mm')
                                                .format(DateTime.parse(
                                                    widget.rental['end_time']))
                                            : '-'),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(thickness: 1),
                                ),
                                // Cost Details
                                _buildReceiptRow('Biaya Sewa',
                                    'IDR ${NumberFormat('#,###').format(widget.rental['total_amount'] ?? 0)}',
                                    isTotal: false),
                                const SizedBox(height: 8),
                                _buildReceiptRow('Denda',
                                    'IDR ${NumberFormat('#,###').format(widget.rental['penalty_amount'] ?? 0)}',
                                    textColor: Colors.red, isTotal: false),
                                if (widget.rental['penalty_amount'] > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Rincian Denda:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Keterlambatan: ${lateMinutes} menit',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Biaya per menit: Rp1.000',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Total: ${lateMinutes} x Rp1.000 = Rp${NumberFormat('#,###').format(lateMinutes * 1000)}',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(thickness: 1),
                                ),
                                _buildReceiptRow('Total',
                                    'IDR ${NumberFormat('#,###').format((widget.rental['total_amount'] ?? 0) + (widget.rental['penalty_amount'] ?? 0))}',
                                    isTotal: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.rental['penalty_amount'] > 0) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimeButton(
                              '${widget.rental['rental_duration'] ?? 60} Min',
                              'Durasi Waktu'),
                          _buildTimeButton(
                              '${lateMinutes > 0 ? "-$lateMinutes" : "0"} Min',
                              'Keterlambatan'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isProcessingPayment
                              ? null
                              : _createPenaltyPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isProcessingPayment
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Bayar Denda',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 32),
                      const Text(
                        'Status Rental',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimeButton(
                              '${widget.rental['rental_hours'] * 60} Min',
                              'Durasi Waktu'),
                          _buildTimeButton('0 Min', 'Keterlambatan'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Selesai',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReceiptRow(String label, String amount,
      {Color? textColor, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? Colors.black87,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String time, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
