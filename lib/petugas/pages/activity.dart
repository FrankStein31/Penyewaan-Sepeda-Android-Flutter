import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'detail-activity.dart';
import 'package:intl/intl.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<dynamic> rentals = [];
  bool isLoading = true;
  String userName = 'Guest';
  String userRole = 'User';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchRentals();
    getUserData();
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
      String url = '${Config.baseUrl}/rentals';

      // Log base URL request first
      debugPrint('🌐 Initial API Request URL: $url');

      final response = await http.get(Uri.parse(url));

      // Log the response status and headers
      debugPrint('📥 API Response Status: ${response.statusCode}');
      debugPrint('📝 API Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> allRentals = data['data'];

        // If date filter is active, filter the rentals locally
        if (startDate != null && endDate != null) {
          // Convert filter dates to UTC for comparison
          final startDateTime =
              DateTime(startDate!.year, startDate!.month, startDate!.day)
                  .toUtc();
          final endDateTime =
              DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59)
                  .toUtc();

          debugPrint('📅 Filtering rentals between:');
          debugPrint('Start: ${startDateTime.toIso8601String()}');
          debugPrint('End: ${endDateTime.toIso8601String()}');

          // Filter rentals based on start_time
          allRentals = allRentals.where((rental) {
            DateTime rentalStartTime = DateTime.parse(rental['start_time']);
            bool isInRange = rentalStartTime.isAfter(startDateTime) &&
                rentalStartTime.isBefore(endDateTime);

            // Debug log for each rental's date comparison
            debugPrint(
                '🔍 Rental date ${rental['start_time']} in range: $isInRange');

            return isInRange;
          }).toList();
        }

        setState(() {
          rentals = allRentals;
          isLoading = false;
        });

        debugPrint('📊 Number of rentals after filtering: ${rentals.length}');
      } else {
        // Log error response
        debugPrint('❌ API Error Response: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Log any errors
      debugPrint('⚠️ API Error: $e');
      setState(() {
        isLoading = false;
      });
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
      fetchRentals(); // Refresh data with new date filter
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
            'No activities found',
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity',
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

            // Admin info card
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
                        child: const Text('Activity'),
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
            const SizedBox(height: 20),

            // Date Filter and Activities Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Date filter button
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
            const SizedBox(height: 10),

            // Activities list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rentals.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: fetchRentals,
                          child: ListView.builder(
                            itemCount: rentals.length,
                            itemBuilder: (context, index) {
                              final rental = rentals[index];
                              return _buildActivityItem(rental);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> rental) {
    final name = rental['product_name'] ?? '';
    final price = 'IDR ${rental['total_amount']}';
    final time = '${rental['remaining_minutes']} Min';
    final status =
        rental['status'] == 'playing' ? 'Disewa' : rental['status'] ?? '-';
    final isLate = (rental['remaining_minutes'] ?? 0) < 0;
    final lateMinutes = (rental['remaining_minutes'] ?? 0) < 0
        ? -(rental['remaining_minutes'] ?? 0)
        : 0;
    final penalty = lateMinutes * 1000;
    final paymentStatus = rental['payment_status'] ?? '-';
    final penaltyStatus = rental['penalty_payment_status'] ?? '-';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailActivityPage(
              rentalId: rental['id'].toString(),
              customerName: name,
              remainingMinutes: rental['remaining_minutes'] ?? 0,
              imageUrl: rental['image_url'] ?? '',
              totalAmount: (rental['total_amount'] ?? 0).toDouble(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
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
                      ),
                      Text(
                        '$price • $time',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (isLate) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Denda: Rp${NumberFormat('#,###').format(penalty)} (${lateMinutes} menit x Rp1.000)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Disewa'
                        ? const Color(0xFF8B5CF6).withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Disewa'
                          ? const Color(0xFF8B5CF6)
                          : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'paid'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentStatus == 'paid' ? 'Sewa Lunas' : 'Sewa Belum Lunas',
                    style: TextStyle(
                      color: paymentStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: penaltyStatus == 'paid'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    penaltyStatus == 'paid'
                        ? 'Denda Lunas'
                        : 'Denda Belum Lunas',
                    style: TextStyle(
                      color: penaltyStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'playing':
        return Colors.green;
      case 'berlangsung':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }
}
