import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_lib;
import 'package:async/async.dart';
import 'package:http_parser/http_parser.dart';

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
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nikController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  Map<String, dynamic>? _userData;
  File? _ktpImage;
  bool _isPasswordMode = false;

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
          _phoneController.text = _userData!['phone'] ?? '';
          _addressController.text = _userData!['address'] ?? '';
          _nikController.text = _userData!['nik'] ?? '';
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _ktpImage = File(image.path);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diperbarui')),
        );
        setState(() => _isPasswordMode = false);
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

  Future<void> _updateProfile() async {
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

      var uri = Uri.parse('${Config.apiUrl}/users/$_userId/profile');
      var request = http.MultipartRequest('PUT', uri);

      request.fields['phone'] = _phoneController.text;
      request.fields['address'] = _addressController.text;
      request.fields['nik'] = _nikController.text;

      if (_ktpImage != null) {
        var stream =
            http.ByteStream(DelegatingStream.typed(_ktpImage!.openRead()));
        var length = await _ktpImage!.length();
        var multipartFile = http.MultipartFile('ktp_image', stream, length,
            filename: path_lib.basename(_ktpImage!.path),
            contentType: MediaType('image', 'jpeg'));
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var data = json.decode(responseBody);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile berhasil diperbarui')),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
        title: Text(_isPasswordMode ? 'Edit Password' : 'Edit Profile'),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPasswordMode ? Icons.person : Icons.lock,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _isPasswordMode = !_isPasswordMode;
                _errorMessage = null;
              });
            },
          ),
        ],
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
                        Text(
                          _isPasswordMode ? 'Ubah Password' : 'Edit Profile',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isPasswordMode
                              ? 'Masukkan password lama dan password baru Anda'
                              : 'Update informasi profile Anda',
                          style: const TextStyle(
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
                        style: const TextStyle(
                            color: Color(0xFFDC3545), fontSize: 14),
                      ),
                    ),
                  if (_isPasswordMode) ...[
                    // Password Form Fields
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Password Lama',
                        labelStyle: const TextStyle(color: Color(0xFF8B5CF6)),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF8B5CF6)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF8B5CF6)),
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
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF8B5CF6)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF8B5CF6)),
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
                  ] else ...[
                    // Profile Form Fields
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Nomor HP',
                        labelStyle: const TextStyle(color: Color(0xFF8B5CF6)),
                        prefixIcon:
                            const Icon(Icons.phone, color: Color(0xFF8B5CF6)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor HP harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nikController,
                      decoration: InputDecoration(
                        labelText: 'NIK',
                        labelStyle: const TextStyle(color: Color(0xFF8B5CF6)),
                        prefixIcon: const Icon(Icons.credit_card,
                            color: Color(0xFF8B5CF6)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIK harus diisi';
                        }
                        if (value.length != 16) {
                          return 'NIK harus 16 digit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Alamat',
                        labelStyle: const TextStyle(color: Color(0xFF8B5CF6)),
                        prefixIcon: const Icon(Icons.location_on,
                            color: Color(0xFF8B5CF6)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foto KTP',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFDEE2E6)),
                            ),
                            child: _ktpImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_ktpImage!,
                                        fit: BoxFit.cover),
                                  )
                                : _userData != null &&
                                        _userData!['ktp_image'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          '${Config.baseUrl}/${_userData!['ktp_image']}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error),
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.add_photo_alternate,
                                              size: 40,
                                              color: Color(0xFF8B5CF6)),
                                          SizedBox(height: 8),
                                          Text(
                                            'Upload Foto KTP',
                                            style: TextStyle(
                                              color: Color(0xFF8B5CF6),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                      onPressed: _isLoading
                          ? null
                          : _isPasswordMode
                              ? _updatePassword
                              : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isPasswordMode
                                  ? 'Update Password'
                                  : 'Update Profile',
                              style: const TextStyle(fontSize: 16),
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
    _phoneController.dispose();
    _addressController.dispose();
    _nikController.dispose();
    super.dispose();
  }
}
