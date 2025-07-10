import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class DetailReportAdminPage extends StatefulWidget {
  final Map<String, dynamic> rental;
  const DetailReportAdminPage({super.key, required this.rental});

  @override
  State<DetailReportAdminPage> createState() => _DetailReportAdminPageState();
}

class _DetailReportAdminPageState extends State<DetailReportAdminPage> {
  Map<String, dynamic>? detail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    final id = widget.rental['id'];
    final url = Uri.parse('${Config.baseUrl}/rentals/$id');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint('DETAIL RENTAL ADMIN: ' + data.toString());
        setState(() {
          detail = data['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('ERROR DETAIL RENTAL ADMIN: ' + e.toString());
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final d = detail ?? widget.rental;
    final penyewa =
        d['user_name'] ?? d['username'] ?? d['customer_name'] ?? '-';
    final phone = d['user_phone'] ?? d['phone'] ?? '-';
    final nik = d['user_nik'] ?? d['nik'] ?? '-';
    final address = d['user_address'] ?? d['address'] ?? '-';
    final ktp = d['user_ktp_image'] ?? d['ktp_image'];
    final product = d['product_name'] ?? '-';
    String _toJakarta(String? dt) {
      if (dt == null) return '-';
      final utc = DateTime.parse(dt).toUtc();
      final jakarta = utc.add(const Duration(hours: 7));
      return DateFormat('dd MMM yyyy, HH:mm').format(jakarta) + ' WIB';
    }

    final start = d['start_time'] != null ? _toJakarta(d['start_time']) : '-';
    final end = d['end_time'] != null ? _toJakarta(d['end_time']) : '-';
    final returnTime =
        d['return_time'] != null ? _toJakarta(d['return_time']) : '-';
    final status = d['status'] == 'playing'
        ? 'Disewa'
        : d['status'] == 'returned'
            ? 'Selesai'
            : d['status'] ?? '-';
    final total = d['total_amount'] ?? 0;
    final penalty = d['penalty_amount'] ?? 0;
    final damage = d['damage_penalty'] ?? 0;
    final lost = d['lost_penalty'] ?? 0;
    final totalAll = total + penalty + damage + lost;
    final paymentStatus = d['payment_status'] ?? '-';
    final penaltyStatus = d['penalty_payment_status'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
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
                      '${Config.baseUrl.replaceAll('/api', '')}/' + ktp,
                      width: 80,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.broken_image)),
                ],
              ),
            ],
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Waktu Mulai:'),
                Text(start),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Waktu Selesai:'),
                Text(end),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Waktu Pengembalian:'),
                Text(returnTime),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:'),
                Text(status,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            _buildRow('Biaya Sewa', total),
            _buildRow(
                'Denda Terlambat',
                penalty == 0
                    ? 'Tidak Ada Denda'
                    : 'IDR ' + NumberFormat('#,###').format(penalty),
                color: Colors.orange),
            _buildRow('Denda Rusak', damage, color: Colors.red),
            _buildRow('Denda Hilang', lost, color: Colors.purple),
            const Divider(height: 32),
            _buildRow('Total Pembayaran', totalAll, bold: true),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status Pembayaran Sewa:'),
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
                    paymentStatus == 'paid' ? 'Lunas' : 'Belum Lunas',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status Pembayaran Denda:'),
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
                    penaltyStatus == 'paid' ? 'Lunas' : 'Belum Lunas',
                    style: TextStyle(
                      color: penaltyStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          value is String
              ? Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal))
              : Text('IDR ${NumberFormat('#,###').format(value)}',
                  style: TextStyle(
                      color: color,
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
