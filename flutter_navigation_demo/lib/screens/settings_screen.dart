import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.dark_mode,
                  title: 'Mode Gelap',
                  trailing: Switch(value: false, onChanged: (value) {}),
                ),
                _buildSettingItem(
                  icon: Icons.notifications,
                  title: 'Notifikasi',
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
                _buildSettingItem(
                  icon: Icons.language,
                  title: 'Bahasa',
                  trailing: const Text('Indonesia'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.security,
                  title: 'Privasi & Keamanan',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.help,
                  title: 'Bantuan & Dukungan',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.info,
                  title: 'Tentang Aplikasi',
                  onTap: () {},
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: trailing,
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),
      ],
    );
  }
}