import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class EditProductPage extends StatefulWidget {
  final int productId;
  final Map<String, dynamic> productData;

  const EditProductPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final stockController = TextEditingController();
  int? selectedCategoryId;
  List<dynamic> categories = [];
  bool isLoading = true;
  File? _image;
  final _picker = ImagePicker();
  String? currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    initializeProductData();
  }

  void initializeProductData() {
    currentPhotoUrl = widget.productData['photo_url'];
    nameController.text = widget.productData['name'];
    priceController.text = widget.productData['price'].toString();
    descriptionController.text = widget.productData['description'] ?? '';
    stockController.text = widget.productData['stock'].toString();
    selectedCategoryId = widget.productData['category_id'];
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/categories'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            categories = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image quality
      );
      
      if (pickedFile != null) {
        // Validate file extension
        final ext = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          throw Exception('Hanya file gambar yang diperbolehkan (png, jpg, jpeg)');
        }
        
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    if (_image == null) return;

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/products/${widget.productId}/upload-photo'),
      );

      // Add file to request
      var stream = http.ByteStream(_image!.openRead());
      var length = await _image!.length();

      // Get file extension and determine MIME type
      final ext = _image!.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: _image!.path.split('/').last,
        contentType: MediaType.parse(mimeType)
      );

      request.files.add(multipartFile);

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print('Upload response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('Failed to upload photo: $responseData');
      }

      // Update current photo URL after successful upload
      final jsonResponse = json.decode(responseData);
      if (jsonResponse['data'] != null && jsonResponse['data']['image'] != null) {
        setState(() {
          currentPhotoUrl = jsonResponse['data']['image'];
        });
      }
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      rethrow;
    }
  }

  Future<void> updateProduct() async {
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    try {
      final data = {
        'name': nameController.text,
        'price': int.parse(priceController.text),
        'description': descriptionController.text,
        'stock': int.parse(stockController.text),
        'category_id': selectedCategoryId,
      };

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/products/${widget.productId}'),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (_image != null) {
          await _uploadPhoto();
        }
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Product',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : currentPhotoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    currentPhotoUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 40),
                                    SizedBox(height: 8),
                                    Text('Tap to add product photo'),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: categories.map<DropdownMenuItem<int>>((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Price per Hour',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: stockController,
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Product',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
