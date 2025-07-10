import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/users'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = (data['data'] as List)
              .where((u) => u['level'] == 'user')
              .toList();
          _filteredUsers = _users;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  void _filterUsers(String value) {
    setState(() {
      _search = value;
      _filteredUsers = _users.where((u) {
        final q = value.toLowerCase();
        return (u['username'] ?? '').toLowerCase().contains(q) ||
            (u['phone'] ?? '').toLowerCase().contains(q) ||
            (u['nik'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _blacklistUser(int userId) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blacklist User'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan blacklist',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Blacklist'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        final response = await http.put(
          Uri.parse('${Config.baseUrl}/users/$userId/blacklist'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'reason': result}),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User berhasil di-blacklist')),
          );
          _loadUsers();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _unblacklistUser(int userId) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/users/$userId/unblacklist'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User berhasil dihapus dari blacklist')),
        );
        _loadUsers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Cari user (username, telepon, NIK)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user['is_blacklisted'] == 1
                                  ? Colors.red
                                  : Colors.purple,
                              child: Icon(
                                user['is_blacklisted'] == 1
                                    ? Icons.block
                                    : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(user['username'] ?? '-'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user['phone'] != null)
                                  Text('Telepon: ${user['phone']}'),
                                if (user['nik'] != null)
                                  Text('NIK: ${user['nik']}'),
                                if (user['address'] != null)
                                  Text('Alamat: ${user['address']}'),
                                if (user['is_blacklisted'] == 1)
                                  Text(
                                    'BLACKLIST: ${user['blacklist_reason'] ?? ''}',
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            trailing: user['is_blacklisted'] == 1
                                ? IconButton(
                                    icon: const Icon(Icons.undo,
                                        color: Colors.green),
                                    tooltip: 'Unblacklist',
                                    onPressed: () =>
                                        _unblacklistUser(user['id']),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.block,
                                        color: Colors.red),
                                    tooltip: 'Blacklist',
                                    onPressed: () => _blacklistUser(user['id']),
                                  ),
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
