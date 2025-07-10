import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detail-report.dart';
import 'package:intl/intl.dart';
import '../../config.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String userName = 'Guest';
  String userRole = 'User';
  List<Map<String, dynamic>> rentals = [];
  bool isLoading = true;
  Map<int, String> penaltyStatuses = {};
  double totalSpent = 0;
  double totalPenalty = 0;
  double totalDamage = 0;
  double totalLost = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
    fetchRentals();
  }

  void _calculateSummary() {
    double spent = 0;
    double penalty = 0;
    double damage = 0;
    double lost = 0;

    for (var rental in rentals) {
      spent += rental['total_amount'] ?? 0;
      penalty += rental['penalty_amount'] ?? 0;
      damage += rental['damage_penalty'] ?? 0;
      lost += rental['lost_penalty'] ?? 0;
    }

    setState(() {
      totalSpent = spent;
      totalPenalty = penalty;
      totalDamage = damage;
      totalLost = lost;
    });
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Pembayaran',
                  totalSpent,
                  Icons.account_balance_wallet,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Denda',
                  totalPenalty + totalDamage + totalLost,
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
          if (totalPenalty > 0 || totalDamage > 0 || totalLost > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (totalPenalty > 0)
                  Expanded(
                    child: _buildSummaryCard(
                      'Denda Terlambat',
                      totalPenalty,
                      Icons.timer_off,
                      Colors.orange,
                    ),
                  ),
                if (totalDamage > 0) ...[
                  if (totalPenalty > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Denda Rusak',
                      totalDamage,
                      Icons.build,
                      Colors.red,
                    ),
                  ),
                ],
              ],
            ),
            if (totalLost > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Denda Hilang',
                      totalLost,
                      Icons.report_problem,
                      Colors.purple,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(amount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getUserData() async {
    try {
      const storage = FlutterSecureStorage();
      final username = await storage.read(key: 'username');
      final level = await storage.read(key: 'level');

      setState(() {
        userName = username ?? 'Guest';
        userRole = level ?? 'User';
      });

      debugPrint('userName: $userName, userRole: $userRole');
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> fetchRentals() async {
    try {
      const storage = FlutterSecureStorage();
      final userId = await storage.read(key: 'userId');
      if (userId == null) {
        setState(() {
          rentals = [];
          isLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          setState(() {
            rentals = List<Map<String, dynamic>>.from(responseData['data']);
            isLoading = false;
          });
          // Check penalty status for each rental
          for (var rental in rentals) {
            if (rental['penalty_amount'] != null &&
                rental['penalty_amount'] > 0) {
              await checkPenaltyStatus(rental['id']);
            }
          }
          _calculateSummary(); // Calculate summary after fetching rentals
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load rentals');
      }
    } catch (e) {
      debugPrint('Error fetching rentals: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> checkPenaltyStatus(int rentalId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals/$rentalId/penalty/payment/status'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          setState(() {
            penaltyStatuses[rentalId] =
                responseData['data']['penalty_payment_status'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking penalty status for rental $rentalId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with notification icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sewa Sepeda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Purple card with admin info
              Container(
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
                          child: const Text('Report'),
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
              ),
              const SizedBox(height: 24),

              // Add summary cards after the purple card
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),

              // Report section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),

              // Report list
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : rentals.isEmpty
                        ? const Center(child: Text('No rentals found'))
                        : ListView.builder(
                            itemCount: rentals.length,
                            itemBuilder: (context, index) {
                              final rental = rentals[index];
                              final status = rental['status'] == 'playing'
                                  ? '(Disewa)'
                                  : rental['status'] == 'returned'
                                      ? '(Selesai)'
                                      : '';

                              final amount = rental['penalty_amount'] > 0
                                  ? 'IDR ${NumberFormat('#,###').format(rental['penalty_amount'])}'
                                  : 'IDR ${NumberFormat('#,###').format(rental['total_amount'])}';

                              final time = '${rental['rental_hours']} Jam';
                              final penaltyStatus =
                                  rental['penalty_payment_status'] ?? '-';
                              final rawStatus = rental['status'] ?? '';

                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailReportPage(rental: rental),
                                    ),
                                  );
                                  if (result == true) {
                                    fetchRentals();
                                  }
                                },
                                child: _buildReportItem(
                                  rental['product_name'] ?? 'Unknown',
                                  status,
                                  amount,
                                  time,
                                  rental['status'] == 'playing' ? '🚲' : '✅',
                                  penaltyStatus,
                                  rawStatus,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(String name, String status, String price, String time,
      String emoji, String penaltyStatus, String rawStatus) {
    final isPenaltyPaid = penaltyStatus == 'paid';
    debugPrint(
        'report.dart | penalty_payment_status: ${penaltyStatus} | isPenaltyPaid: ${isPenaltyPaid}');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPenaltyPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPenaltyPaid ? 'Denda Lunas' : 'Denda Belum Lunas',
                  style: TextStyle(
                    color: isPenaltyPaid ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
