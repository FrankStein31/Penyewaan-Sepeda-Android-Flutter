import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../config.dart';

class DetailActivityPage extends StatefulWidget {
  final String rentalId;
  final String customerName;
  final int remainingMinutes;
  final String imageUrl;
  final double totalAmount;

  const DetailActivityPage({
    super.key,
    required this.rentalId,
    required this.customerName,
    required this.remainingMinutes,
    required this.imageUrl,
    required this.totalAmount,
  });

  @override
  State<DetailActivityPage> createState() => _DetailActivityPageState();
}

class _DetailActivityPageState extends State<DetailActivityPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? rentalDetails;
  bool isLoading = true;
  double progressValue = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;
  int remainingMinutes = 0;

  @override
  void initState() {
    super.initState();
    remainingMinutes = widget.remainingMinutes;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _fetchRentalDetails();

    // Start timer to update remaining time
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingMinutes > 0) {
            remainingMinutes--;
            _updateProgress();
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _updateProgress() {
    final totalMinutes = (rentalDetails?['rental_hours'] ?? 1) * 60;
    progressValue = remainingMinutes / totalMinutes;
  }

  Future<void> _fetchRentalDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals/${widget.rentalId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            rentalDetails = Map<String, dynamic>.from(data['data']);
            isLoading = false;
            _updateProgress();
            _controller.forward();
          });
          debugPrint('DETAIL ACTIVITY: ' + data['data'].toString());
        }
      }
    } catch (e) {
      debugPrint('Error fetching rental details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentStatus = rentalDetails?['payment_status'] ?? '-';
    final penaltyStatus = rentalDetails?['penalty_payment_status'] ?? '-';
    final penyewa = rentalDetails?['user_name'] ?? '-';
    final phone = rentalDetails?['user_phone'] ?? '-';
    final nik = rentalDetails?['user_nik'] ?? '-';
    final address = rentalDetails?['user_address'] ?? '-';
    final ktp = rentalDetails?['user_ktp_image'];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      widget.customerName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '( ${rentalDetails?['rental_hours'] ?? 1} Jam )',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Info Penyewa
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 18),
                              SizedBox(width: 6),
                              Text('Penyewa: $penyewa'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 18),
                              SizedBox(width: 6),
                              Text('No HP: $phone'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.credit_card, size: 18),
                              SizedBox(width: 6),
                              Text('NIK: $nik'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.home, size: 18),
                              SizedBox(width: 6),
                              Expanded(
                                  child: Text('Alamat: $address',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          if (ktp != null && ktp != '') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.image, size: 18),
                                SizedBox(width: 6),
                                Text('Foto KTP:'),
                                SizedBox(width: 8),
                                Image.network(
                                    '${Config.baseUrl.replaceAll('/api', '')}/' +
                                        ktp,
                                    width: 80,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.broken_image)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Circular Progress with Bike
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[100],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return SizedBox(
                              width: 240,
                              height: 240,
                              child: CircularProgressIndicator(
                                value: progressValue * _animation.value,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[200],
                                color: const Color(0xFF8B5CF6),
                              ),
                            );
                          },
                        ),
                        Image.network(
                          widget.imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.directions_bike,
                              size: 80,
                              color: Color(0xFF8B5CF6),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Product Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.customerName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'IDR ${widget.totalAmount}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$remainingMinutes Min',
                                  style: const TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Payment Details
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detail Pembayaran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Rental Start Time
                                if (rentalDetails?['start_time'] != null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Waktu Mulai'),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm').format(
                                          DateTime.parse(
                                              rentalDetails!['start_time']),
                                        ),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Rental End Time
                                if (rentalDetails?['end_time'] != null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Waktu Selesai'),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm').format(
                                          DateTime.parse(
                                              rentalDetails!['end_time']),
                                        ),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Return Time if available
                                if (rentalDetails?['return_time'] != null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Waktu Pengembalian'),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm').format(
                                          DateTime.parse(
                                              rentalDetails!['return_time']),
                                        ),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Payment Status
                                if (rentalDetails?['payment_status'] !=
                                    null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Status Pembayaran Sewa'),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: paymentStatus == 'paid'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          paymentStatus == 'paid'
                                              ? 'Lunas'
                                              : 'Belum Lunas',
                                          style: TextStyle(
                                            color: paymentStatus == 'paid'
                                                ? Colors.green
                                                : Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (rentalDetails?['penalty_payment_status'] !=
                                    null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Status Pembayaran Denda'),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (penaltyStatus == 'paid')
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (penaltyStatus == 'paid')
                                              ? 'Lunas'
                                              : 'Belum Lunas',
                                          style: TextStyle(
                                            color: (penaltyStatus == 'paid')
                                                ? Colors.green
                                                : Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(),
                                ),
                                // Rental Cost
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Biaya Sewa'),
                                    Text(
                                      'IDR ${NumberFormat('#,###').format(widget.totalAmount)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                if (rentalDetails != null &&
                                    (rentalDetails?['remaining_minutes'] ?? 0) <
                                        0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Denda (Keterlambatan)'),
                                      Text(
                                        'IDR ${NumberFormat('#,###').format((-(rentalDetails?['remaining_minutes'] ?? 0)) * 1000)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4, left: 8),
                                    child: Text(
                                      'Keterlambatan: ${-(rentalDetails?['remaining_minutes'] ?? 0)} menit x Rp1.000',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'IDR ${NumberFormat('#,###').format(widget.totalAmount + ((-(rentalDetails?['remaining_minutes'] ?? 0)) * 1000))}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
