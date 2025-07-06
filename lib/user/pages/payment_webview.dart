import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  final int? rentalId;
  final bool isPenaltyPayment;

  const PaymentWebView({
    super.key, 
    required this.url, 
    this.rentalId,
    this.isPenaltyPayment = false,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              isLoading = false;
            });
            debugPrint('Page finished loading: $url');
            
            debugPrint('Checking URL: $url');
            
            // Handle GoPay specific URLs
            if (url.contains('gopay-finish-deeplink')) {
              debugPrint('Detected GoPay finish deeplink');
              // Tunggu sebentar untuk memastikan status sudah diupdate di Midtrans
              await Future.delayed(const Duration(seconds: 2));
              await _updatePaymentStatus('paid');
              Navigator.pop(context, 'success');
              return;
            }
            
            // Handle transaction success page
            if (url.contains('Transaction is successful') || 
                url.contains('status=200')) {
              debugPrint('Transaction successful detected');
              await _updatePaymentStatus('paid');
              Navigator.pop(context, 'success');
              return;
            }
            
            // Handle payment completion based on redirect URL
            if (url.contains('payment_status=success') || 
                url.contains('transaction_status=capture') || 
                url.contains('transaction_status=settlement')) {
              debugPrint('Payment success detected');
              await _updatePaymentStatus('paid');
              Navigator.pop(context, 'success');
            } else if (url.contains('payment_status=failed') || 
                     url.contains('transaction_status=cancel') || 
                     url.contains('transaction_status=deny') || 
                     url.contains('transaction_status=expire')) {
              debugPrint('Payment failed detected');
              await _updatePaymentStatus('failed');
              Navigator.pop(context, 'failed');
            } else if (url.contains('transaction_status=pending')) {
              debugPrint('Payment pending detected');
              await _updatePaymentStatus('pending');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _updatePaymentStatus(String status) async {
    if (widget.rentalId == null) return;

    try {
      debugPrint('Updating payment status to: $status for rental: ${widget.rentalId}');

      if (widget.isPenaltyPayment) {
        // Add delay to ensure Midtrans has processed the payment
        await Future.delayed(const Duration(seconds: 2));

        // Update penalty payment status
        final penaltyResponse = await http.put(
          Uri.parse('${Config.baseUrl}/rentals/${widget.rentalId}/penalty/payment/status'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'penalty_payment_status': 'paid'
          }),
        );

        debugPrint('Response status code: ${penaltyResponse.statusCode}');
        debugPrint('Response headers: ${penaltyResponse.headers}');
        debugPrint('Response body: ${penaltyResponse.body}');

        if (penaltyResponse.statusCode != 200) {
          debugPrint('Failed to update penalty status: ${penaltyResponse.body}');
          return;
        }

        // Try to parse response as JSON
        try {
          final penaltyData = jsonDecode(penaltyResponse.body);
          debugPrint('Penalty status update response: ${penaltyResponse.statusCode} - ${penaltyData['message']}');
        } catch (e) {
          debugPrint('Warning: Could not parse response as JSON: $e');
          // Continue anyway since status code was 200
        }
      } else {
        // Update regular rental payment status
        final statusResponse = await http.put(
          Uri.parse('${Config.baseUrl}/rentals/${widget.rentalId}/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'payment_status': status
          }),
        );

        final statusData = jsonDecode(statusResponse.body);
        debugPrint('Status update response: ${statusResponse.statusCode} - ${statusData['message']}');

        if (statusResponse.statusCode != 200) {
          debugPrint('Failed to update rental status: ${statusResponse.body}');
          return;
        }
      }

     
      final notifResponse = await http.post(
        Uri.parse('${Config.baseUrl}/payment/notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': 'RENTAL-${widget.rentalId}',
          'transaction_status': status == 'paid' ? 'settlement' : 
                              status == 'failed' ? 'expire' : 'pending',
          'fraud_status': 'accept',
          'status_code': '200',
          'transaction_id': DateTime.now().millisecondsSinceEpoch.toString()
        }),
      );

      final notifData = jsonDecode(notifResponse.body);
      debugPrint('Notification response: ${notifResponse.statusCode} - ${notifData['message']}');

      if (notifResponse.statusCode != 200) {
        debugPrint('Failed to send payment notification: ${notifResponse.body}');
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
