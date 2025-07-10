import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key});

  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  List<dynamic> _blacklistedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlacklistedUsers();
  }

  Future<void> _loadBlacklistedUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/users/blacklisted'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _blacklistedUsers = data['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _removeFromBlacklist(int userId) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/users/$userId/unblacklist'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User berhasil dihapus dari blacklist'),
          ),
        );
        _loadBlacklistedUsers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showBlacklistDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Blacklist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${user['username']}'),
            if (user['phone'] != null) Text('Telepon: ${user['phone']}'),
            if (user['nik'] != null) Text('NIK: ${user['nik']}'),
            if (user['address'] != null) Text('Alamat: ${user['address']}'),
            const SizedBox(height: 8),
            Text('Alasan: ${user['blacklist_reason']}'),
            Text(
              'Tanggal: ${user['blacklist_date'].substring(0, 16)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromBlacklist(user['id']);
            },
            child: const Text(
              'Hapus dari Blacklist',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Blacklist'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBlacklistedUsers,
              child: _blacklistedUsers.isEmpty
                  ? const Center(
                      child: Text('Tidak ada user dalam blacklist'),
                    )
                  : ListView.builder(
                      itemCount: _blacklistedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _blacklistedUsers[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.block,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(user['username']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user['phone'] != null)
                                  Text('Telepon: ${user['phone']}'),
                                Text(
                                  'Tanggal: ${user['blacklist_date'].substring(0, 16)}',
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _showBlacklistDetails(user),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
