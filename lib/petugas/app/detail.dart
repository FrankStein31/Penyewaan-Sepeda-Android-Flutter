import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'dart:async';
import '../../config.dart';

class CustomerDetailPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final double totalAmount;
  final int remainingMinutes;

  const CustomerDetailPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.remainingMinutes,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> with SingleTickerProviderStateMixin {
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

  String formatRupiah(dynamic number) {
    if (number == null) return 'IDR 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  Future<void> _fetchRentalDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals/${widget.customerId}'),
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
        }
      }
    } catch (e) {
      debugPrint('Error fetching rental details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateProgress() {
    final totalMinutes = (rentalDetails?['rental_hours'] ?? 1) * 60;
    progressValue = remainingMinutes / totalMinutes;
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Customer Name
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
                        const SizedBox(height: 40),

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
                              rentalDetails?['image_url'] ?? '',
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
                      ],
                    ),
                  ),
                ),

                // Bottom Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // User Image
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // User Info
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
                                  formatRupiah(widget.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Time Remaining
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$remainingMinutes Min',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }


}
