import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfilePage({super.key, this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      // Get user ID from storage
      final userId = await _storage.read(key: 'userId');
      if (userId == null) throw Exception('User ID not found');

      // Get user data from API
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/$userId'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        setState(() {
          _userData = data['data'];
          _userId = _userData!['id'].toString();
          _errorMessage = null;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to get user data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_userId == null) {
        await _getUserData();
        if (_userId == null) throw Exception('User ID not found');
      }

      final response = await http.put(
        Uri.parse('${Config.apiUrl}/users/$_userId/password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui')),
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Terjadi kesalahan';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Password'),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            constraints: const BoxConstraints(maxWidth: 300),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title Section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pedal_bike,
                            size: 48,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Ubah Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Masukkan password lama dan password baru Anda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFDC3545), fontSize: 14),
                  ),
                ),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Lama',
                  labelStyle: const TextStyle(color: Color(0xFF8B5CF6)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8B5CF6)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password lama harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  labelStyle: const TextStyle(color: Color(0xFF8B5CF6)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8B5CF6)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password baru harus diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Password',
                        style: TextStyle(fontSize: 16),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
