import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class PenaltyReportPage extends StatefulWidget {
  const PenaltyReportPage({super.key});

  @override
  State<PenaltyReportPage> createState() => _PenaltyReportPageState();
}

class _PenaltyReportPageState extends State<PenaltyReportPage> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rental-reports'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reports = data['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Color _getReportTypeColor(String type) {
    switch (type) {
      case 'late':
        return Colors.orange;
      case 'damage':
        return Colors.red;
      case 'lost':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getReportTypeText(String type) {
    switch (type) {
      case 'late':
        return 'Keterlambatan';
      case 'damage':
        return 'Kerusakan';
      case 'lost':
        return 'Kehilangan';
      default:
        return type;
    }
  }

  void _showProofImage(String? imageUrl) {
    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Kerusakan'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            Image.network(
              '${Config.baseUrl}/$imageUrl',
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hitung total per jenis denda
    double totalLate = 0;
    double totalDamage = 0;
    double totalLost = 0;

    for (var report in _reports) {
      switch (report['report_type']) {
        case 'late':
          totalLate += double.parse(report['amount'].toString());
          break;
        case 'damage':
          totalDamage += double.parse(report['amount'].toString());
          break;
        case 'lost':
          totalLost += double.parse(report['amount'].toString());
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Denda'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      const Text(
                        'Ringkasan Denda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryCard(
                            title: 'Keterlambatan',
                            amount: totalLate,
                            color: Colors.orange,
                          ),
                          _SummaryCard(
                            title: 'Kerusakan',
                            amount: totalDamage,
                            color: Colors.red,
                          ),
                          _SummaryCard(
                            title: 'Kehilangan',
                            amount: totalLost,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReports,
                    child: ListView.builder(
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getReportTypeColor(
                                      report['report_type'],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getReportTypeText(report['report_type']),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(report['product_name']),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Penyewa: ${report['username']}'),
                                Text('Denda: Rp${report['amount']}'),
                                if (report['description'] != null)
                                  Text('Keterangan: ${report['description']}'),
                                Text(
                                  'Tanggal: ' +
                                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                                          .format(DateTime.parse(
                                                  report['created_at'])
                                              .add(const Duration(hours: 7))),
                                ),
                              ],
                            ),
                            trailing: report['proof_image'] != null
                                ? IconButton(
                                    icon: const Icon(Icons.image),
                                    onPressed: () => _showProofImage(
                                      report['proof_image'],
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 100,
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Rp${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
