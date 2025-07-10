import 'package:flutter/material.dart';
import '../pages/product_status_page.dart';
import '../pages/rental_monitoring_page.dart';
import '../pages/penalty_report_page.dart';
import '../pages/blacklist_page.dart';

class AdminDrawer extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const AdminDrawer({
    super.key,
    required this.username,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username),
            accountEmail: const Text('Admin'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  size: 40, color: Colors.purple),
            ),
            decoration: const BoxDecoration(
              color: Colors.purple,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.pedal_bike),
            title: const Text('Status Sepeda'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductStatusPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor),
            title: const Text('Monitoring Rental'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RentalMonitoringPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Laporan Denda'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PenaltyReportPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Kelola User Blacklist'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/user-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Kategori'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/category');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Produk'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/product');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}
