import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class RentalMonitoringPage extends StatefulWidget {
  const RentalMonitoringPage({super.key});

  @override
  State<RentalMonitoringPage> createState() => _RentalMonitoringPageState();
}

class _RentalMonitoringPageState extends State<RentalMonitoringPage> {
  List<dynamic> _rentals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rentals = data['data'];
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
      case 'playing':
        return Colors.blue;
      case 'returned':
        return Colors.green;
      case 'damaged':
        return Colors.orange;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes menit';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours jam ${remainingMinutes > 0 ? '$remainingMinutes menit' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final activeRentals =
        _rentals.where((r) => r['status'] == 'playing').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Rental'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRentals,
              child: activeRentals.isEmpty
                  ? const Center(child: Text('Tidak ada rental aktif'))
                  : ListView.builder(
                      itemCount: activeRentals.length,
                      itemBuilder: (context, index) {
                        final rental = activeRentals[index];
                        final remainingMinutes =
                            rental['remaining_minutes'] ?? 0;
                        final isLate = remainingMinutes < 0;

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rental['product_name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _getStatusColor(rental['status']),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        rental['status'].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Penyewa: ${rental['user_name']}'),
                                Text('Telepon: ${rental['user_phone'] ?? '-'}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Mulai: ${rental['start_time'].substring(0, 16)}',
                                ),
                                Text(
                                  'Selesai: ${rental['end_time'].substring(0, 16)}',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: isLate ? Colors.red : Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isLate
                                          ? 'Terlambat: ${_formatDuration(remainingMinutes.abs())}'
                                          : 'Sisa waktu: ${_formatDuration(remainingMinutes)}',
                                      style: TextStyle(
                                        color:
                                            isLate ? Colors.red : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (rental['penalty_amount'] > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Denda: Rp${rental['penalty_amount']}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
