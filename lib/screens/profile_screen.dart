import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ApiService>().currentUser;
    final userName = user?['name'] ?? 'Guest User';
    final userEmail = user?['email'] ?? 'No email';
    final status = user?['status'] ?? 'active';
    
    final primaryBlue = const Color(0xFF1E3A8A);
    final accentBlue = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // PROFILE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: accentBlue,
                      child: Text(userName.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(userEmail, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'active' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: status == 'active' ? Colors.green : Colors.red, width: 1),
                    ),
                    child: Text(
                      status == 'active' ? 'Active Account' : 'Blocked',
                      style: TextStyle(color: status == 'active' ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // MENU OPTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildProfileItem(Icons.person_outline_rounded, 'Edit Profile'),
                  _buildProfileItem(Icons.notifications_none_rounded, 'Notifications'),
                  _buildProfileItem(Icons.security_rounded, 'Security'),
                  _buildProfileItem(Icons.help_outline_rounded, 'Help & Support'),
                  const Divider(height: 40),
                  _buildProfileItem(Icons.logout_rounded, 'Logout', color: Colors.red, onTap: () {
                    context.read<ApiService>().logout();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (color ?? const Color(0xFF1E3A8A)).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color ?? const Color(0xFF1E3A8A)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        trailing: const Icon(Icons.chevron_right_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.white,
      ),
    );
  }
}
