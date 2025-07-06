import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config.dart';

class DetailActivityPage extends StatefulWidget {
  final Map<String, dynamic>? rentalData;

  const DetailActivityPage({super.key, this.rentalData});

  @override
  State<DetailActivityPage> createState() => _DetailActivityPageState();
}

class _DetailActivityPageState extends State<DetailActivityPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? rentalDetail;
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  String? userName;
  String? userId;
  
  // Timer variables
  int totalMinutes = 0;
  int remainingMinutes = 0;
  Timer? _timer;
  DateTime? _rentalEndTime;
  int? penaltyAmount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _fetchRentalDetail();
    _getUserData();
    _fetchPenaltyAmount(); // Fetch penalty amount on init
  }

  Future<void> _getUserData() async {
    try {
      const storage = FlutterSecureStorage();
      final username = await storage.read(key: 'username');
      final id = await storage.read(key: 'id');

      setState(() {
        userName = username;
        userId = id;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _createPenaltyPayment(int penaltyAmount) async {
    try {
      setState(() => isLoading = true);

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/rentals/${rentalDetail!['id']}/penalty-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': int.parse(userId!),
          'customer_name': userName,
          'penalty_amount': penaltyAmount,
          'payment_method': 'gopay'
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          final paymentUrl = responseData['data']['payment_url'];
          if (paymentUrl != null) {
            final Uri url = Uri.parse(paymentUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen
            } else {
              throw Exception('Could not launch $paymentUrl');
            }
          }
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to create payment');
      }
    } catch (e) {
      debugPrint('Error creating payment: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showPenaltyDialog(int penaltyAmount) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pemberitahuan Denda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Anda terkena denda keterlambatan!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Nominal denda: ${NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(penaltyAmount)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Klik tombol di bawah untuk melakukan pembayaran denda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to previous screen
              },
              child: const Text('Nanti'),
            ),
            TextButton(
              onPressed: () => _createPenaltyPayment(penaltyAmount),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Bayar Sekarang'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _stopRental() async {
    if (rentalDetail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data rental tidak ditemukan')),
      );
      return;
    }

    try {
      // First stop the rental
      final stopResponse = await http.put(
        Uri.parse('${Config.baseUrl}/rentals/${rentalDetail!['id']}/stop'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (stopResponse.statusCode == 200) {
        final stopData = jsonDecode(stopResponse.body);
        if (stopData['status'] == true) {
          // After successful stop, call the return endpoint
          try {
            final now = DateTime.now();
            final returnResponse = await http.put(
              Uri.parse('${Config.baseUrl}/rentals/${rentalDetail!['id']}/return'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'return_time': now.toIso8601String(),
              }),
            );

            if (returnResponse.statusCode != 200) {
              debugPrint('Return endpoint failed: ${returnResponse.statusCode}');
            }
          } catch (returnError) {
            debugPrint('Error calling return endpoint: $returnError');
          }

          if (mounted) {
            // Check if rental has penalty in item_details
            final rentalData = stopData['data'];
            final itemDetails = rentalData['item_details'] as List<dynamic>?;
            final penaltyItem = itemDetails?.firstWhere(
              (item) => item['id'].toString().startsWith('PENALTY-'),
              orElse: () => null,
            );

            final penaltyAmount = penaltyItem?['price'] ?? rentalData['penalty_amount'] ?? 0;
            
            if (penaltyAmount > 0) {
              await _showPenaltyDialog(penaltyAmount);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rental berhasil dihentikan')),
              );
              Navigator.pop(context, true);
            }
          }
        } else {
          throw Exception(stopData['message'] ?? 'Gagal menghentikan rental');
        }
      } else {
        throw Exception('Server error on stop: ${stopResponse.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showStopConfirmation() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin mengakhiri rental ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _stopRental();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Ya, Akhiri'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchRentalDetail() async {
    if (widget.rentalData == null || widget.rentalData!['id'] == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals/${widget.rentalData!['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            rentalDetail = data['data'];
            isLoading = false;
            
            // Calculate total and remaining minutes
            totalMinutes = rentalDetail?['rental_duration']?.toInt() ?? 0;
            remainingMinutes = rentalDetail?['remaining_minutes']?.toInt() ?? 0;
            
            // Ensure valid values
            totalMinutes = totalMinutes > 0 ? totalMinutes : 60; // Default to 60 if invalid
            remainingMinutes = remainingMinutes >= 0 ? remainingMinutes : totalMinutes; // Default to total if invalid
            
            // Calculate rental end time
            if (rentalDetail?['status']?.toString().toLowerCase() == 'playing') {
              _rentalEndTime = DateTime.now().add(Duration(minutes: remainingMinutes));
              _startTimer();
            }
            
            // Start the animation
            _controller.forward();
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rental detail: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Title
            Text(
              rentalDetail?['product_name'] ?? 'Sepeda Lipat\n( Berlangsung )',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Animated Circle Progress
            Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 15,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: totalMinutes > 0 ? _animation.value * (remainingMinutes / totalMinutes) : 0,
                          strokeWidth: 15,
                          backgroundColor: Colors.transparent,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const Icon(
                        Icons.directions_bike,
                        size: 80,
                        color: Colors.black54,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Price Display
            Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(rentalDetail?['total_amount'] ?? 0),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Time Display Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeButton('$totalMinutes', 'Total'),
                const SizedBox(width: 16),
                _buildTimeButton('$remainingMinutes', 'Remaining'),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Details Container
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                  // Cost Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildReceiptRow(
                          'Biaya Sewa',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(rentalDetail?['total_amount'] ?? 0),
                          isTotal: false
                        ),
                        const SizedBox(height: 8),
                        _buildReceiptRow(
                          'Denda',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(penaltyAmount ?? rentalDetail?['penalty_amount'] ?? 0),
                          textColor: Colors.red,
                          isTotal: false
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(thickness: 1),
                        ),
                        _buildReceiptRow(
                          'Total',
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format((rentalDetail?['total_amount'] ?? 0) + (penaltyAmount ?? rentalDetail?['penalty_amount'] ?? 0)),
                          isTotal: true
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selesai Button
            ElevatedButton(
              onPressed: () {
                final status = rentalDetail?['status']?.toString().toLowerCase() ?? '';
                if (status == 'returned') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Info'),
                        content: const Text('Rental ini sudah selesai'),
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
                } else if (status == 'playing') {
                  _showStopConfirmation();
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Info'),
                        content: const Text('Rental tidak dalam status bermain'),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: rentalDetail?['status']?.toString().toLowerCase() == 'playing'
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildTimeButton(String minutes, String label) {
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
            '$minutes Min',
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

  Widget _buildReceiptRow(String label, String amount, {Color? textColor, bool isTotal = false}) {
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

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_rentalEndTime == null) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final difference = _rentalEndTime!.difference(now);
      
      if (difference.inSeconds <= 0) {
        setState(() {
          remainingMinutes = -((-difference.inSeconds) / 60).ceil(); // Convert to negative minutes
        });
        // Fetch penalty amount when overtime
        _fetchPenaltyAmount();
      } else {
        setState(() {
          remainingMinutes = (difference.inSeconds / 60).ceil();
        });
      }
    });
  }

  Future<void> _fetchPenaltyAmount() async {
    if (rentalDetail == null || !mounted) return;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/rentals/${rentalDetail!['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          if (mounted) {
            setState(() {
              // Get penalty from item_details if exists, otherwise use penalty_amount
              final itemDetails = data['data']['item_details'] as List<dynamic>?;
              final penaltyItem = itemDetails?.firstWhere(
                (item) => item['id'].toString().startsWith('PENALTY-'),
                orElse: () => null,
              );
              
              penaltyAmount = penaltyItem?['price'] ?? data['data']['penalty_amount'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching penalty amount: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
