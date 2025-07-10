import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  DateTime? startDate;
  DateTime? endDate;
  double totalIncome = 0;
  int totalUsers = 0;
  double totalPenaltyIncome = 0;
  double totalDamageIncome = 0;
  double totalLostIncome = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
    fetchRentals();
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

  void _calculateSummary() {
    Set<String> uniqueUsers = {};
    double income = 0;
    double penaltyIncome = 0;
    double damageIncome = 0;
    double lostIncome = 0;

    for (var rental in rentals) {
      // Add user to unique users set
      uniqueUsers.add(rental['customer_name'] ?? '');

      // Calculate total income (including penalties)
      income += (rental['total_amount'] ?? 0);
      penaltyIncome += (rental['penalty_amount'] ?? 0);
      damageIncome += (rental['damage_penalty'] ?? 0);
      lostIncome += (rental['lost_penalty'] ?? 0);
    }

    setState(() {
      totalUsers = uniqueUsers.length;
      totalIncome = income;
      totalPenaltyIncome = penaltyIncome;
      totalDamageIncome = damageIncome;
      totalLostIncome = lostIncome;
    });
  }

  Future<void> fetchRentals() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          List<Map<String, dynamic>> allRentals =
              List<Map<String, dynamic>>.from(responseData['data']);

          // Filter rentals if date range is selected
          if (startDate != null && endDate != null) {
            final startDateTime =
                DateTime(startDate!.year, startDate!.month, startDate!.day)
                    .toUtc();
            final endDateTime = DateTime(
                    endDate!.year, endDate!.month, endDate!.day, 23, 59, 59)
                .toUtc();

            debugPrint('📅 Filtering reports between:');
            debugPrint('Start: ${startDateTime.toIso8601String()}');
            debugPrint('End: ${endDateTime.toIso8601String()}');

            allRentals = allRentals.where((rental) {
              DateTime rentalStartTime = DateTime.parse(rental['start_time']);
              bool isInRange = rentalStartTime.isAfter(startDateTime) &&
                  rentalStartTime.isBefore(endDateTime);

              debugPrint(
                  '🔍 Report date ${rental['start_time']} in range: $isInRange');

              return isInRange;
            }).toList();
          }

          setState(() {
            rentals = allRentals;
            isLoading = false;
          });
          _calculateSummary();
          debugPrint('📊 Number of reports after filtering: ${rentals.length}');
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

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      fetchRentals();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          if (startDate != null && endDate != null)
            Text(
              '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                startDate = null;
                endDate = null;
              });
              fetchRentals();
            },
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildIncomeCard(
                  'Total Pendapatan',
                  totalIncome,
                  Icons.account_balance_wallet,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIncomeCard(
                  'Total Pengguna',
                  totalUsers.toDouble(),
                  Icons.people,
                  const Color(0xFF8B5CF6),
                  isCount: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIncomeCard(
                  'Denda Terlambat',
                  totalPenaltyIncome,
                  Icons.timer_off,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIncomeCard(
                  'Denda Rusak',
                  totalDamageIncome,
                  Icons.build,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIncomeCard(
                  'Denda Hilang',
                  totalLostIncome,
                  Icons.report_problem,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIncomeCard(
                  'Total Denda',
                  totalPenaltyIncome + totalDamageIncome + totalLostIncome,
                  Icons.warning,
                  Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(
      String title, double amount, IconData icon, Color color,
      {bool isCount = false}) {
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
            isCount
                ? amount.toInt().toString()
                : NumberFormat.currency(
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

              // Report section header with date filter
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
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _showDateRangePicker,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          startDate != null && endDate != null
                              ? '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'
                              : 'Filter Date',
                        ),
                      ),
                      if (startDate != null && endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              startDate = null;
                              endDate = null;
                            });
                            fetchRentals();
                          },
                        ),
                    ],
                  ),
                ],
              ),

              // Summary Cards
              if (!isLoading) _buildSummaryCards(),

              // Report list
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : rentals.isEmpty
                        ? _buildEmptyState()
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

                              return _buildReportItem(
                                rental['product_name'] ?? 'Unknown',
                                status,
                                amount,
                                time,
                                rental['status'] == 'playing' ? '🚲' : '✅',
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

  Widget _buildReportItem(
      String name, String status, String price, String time, String emoji) {
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
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
