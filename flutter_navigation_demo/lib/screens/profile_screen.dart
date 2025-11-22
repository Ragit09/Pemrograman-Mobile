import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ragit Dwi Saputra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ragit.dwi@example.com',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Pengguna Aktif',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: '45',
                    label: 'Postingan',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: '890',
                    label: 'Pengikut',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    value: '127',
                    label: 'Mengikuti',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Menu List
            Card(
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.edit,
                    title: 'Edit Profil',
                    onTap: () {},
                  ),
                  _buildListTile(
                    icon: Icons.notifications,
                    title: 'Notifikasi',
                    onTap: () {},
                  ),
                  _buildListTile(
                    icon: Icons.security,
                    title: 'Keamanan',
                    onTap: () {},
                  ),
                  _buildListTile(
                    icon: Icons.help,
                    title: 'Bantuan',
                    onTap: () {},
                  ),
                  _buildListTile(
                    icon: Icons.logout,
                    title: 'Keluar',
                    onTap: () {},
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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