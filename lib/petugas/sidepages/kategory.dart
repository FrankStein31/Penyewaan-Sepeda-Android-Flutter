import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class KategoryPage extends StatefulWidget {
  const KategoryPage({super.key});

  @override
  State<KategoryPage> createState() => _KategoryPageState();
}

class _KategoryPageState extends State<KategoryPage> {
  final TextEditingController _categoryController = TextEditingController();
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response =
          await http.get(Uri.parse('${Config.baseUrl}/categories'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/categories'),
        body: {'name': _categoryController.text},
      );

      if (response.statusCode == 201) {
        _categoryController.clear();
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('${Config.baseUrl}/categories/$id'));
      if (response.statusCode == 200) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  Future<void> _editCategory(int id, String currentName) async {
    final TextEditingController editController =
        TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (editController.text.isNotEmpty) {
                try {
                  final response = await http.put(
                    Uri.parse('${Config.baseUrl}/categories/$id'),
                    body: {'name': editController.text},
                  );
                  if (response.statusCode == 200) {
                    _loadCategories();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Category updated successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input field untuk kategori baru
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Tambah Kategori'),
            ),
            const SizedBox(height: 24),
            // List kategori yang sudah ada
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(categories[index]['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCategory(
                            categories[index]['id'],
                            categories[index]['name'],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _deleteCategory(categories[index]['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}
