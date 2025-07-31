import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _addressController = TextEditingController();
  File? _ktpImage;
  String? _existingKtpImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userId = '1'; // Ganti dengan user ID yang sesuai
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/users/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _phoneController.text = data['phone'] ?? '';
          _nikController.text = data['nik'] ?? '';
          _addressController.text = data['address'] ?? '';
          _existingKtpImage = data['ktp_image'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = '1'; // Ganti dengan user ID yang sesuai
      final uri = Uri.parse('${Config.baseUrl}/users/$userId/profile');

      var request = http.MultipartRequest('PUT', uri)
        ..fields['phone'] = _phoneController.text
        ..fields['nik'] = _nikController.text
        ..fields['address'] = _addressController.text;

      if (_ktpImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'ktp_image',
          _ktpImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diupdate')),
        );
        Navigator.pop(context);
      } else {
        throw jsonDecode(responseData)['message'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = _existingKtpImage ?? '';
    if (imageUrl.isNotEmpty) {
      if (!imageUrl.startsWith('http')) {
        // Hapus 'uploads/ktp/' jika sudah ada di path
        if (imageUrl.startsWith('uploads/ktp/')) {
          imageUrl = imageUrl.replaceFirst('uploads/ktp/', '');
        }
        imageUrl = '${Config.baseUrl}/uploads/ktp/$imageUrl';
      }
      print('KTP Image URL: $imageUrl'); // Debug URL
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KTP Image Preview
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _ktpImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _ktpImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          color: Colors.purple,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return const Icon(
                                        Icons.person,
                                        color: Colors.purple,
                                        size: 40,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.purple,
                                  size: 40,
                                ),
                    ),
                    const SizedBox(height: 16),
                    // Upload Button
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: Text(_ktpImage != null
                          ? 'Ganti Foto KTP'
                          : 'Upload Foto KTP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
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
                    // NIK Field
                    TextFormField(
                      controller: _nikController,
                      decoration: const InputDecoration(
                        labelText: 'NIK',
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
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
                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
