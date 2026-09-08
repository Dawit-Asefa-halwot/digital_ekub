import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Interactive Profile & Settings Screen with Role Authorization Management & Logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAccountInfoModal(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_outline, color: Color(0xFF006C4C)),
              SizedBox(width: 8),
              Text('Account Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('User ID', user.id),
              _buildInfoRow('Full Name', user.name),
              _buildInfoRow('Phone Number', user.phone),
              _buildInfoRow('Email Address', user.email),
              _buildInfoRow('Assigned Role', user.roleName),
              _buildInfoRow('KYC Status', user.isVerified ? 'Verified Member ✅' : 'Pending Verification'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Log Out'),
            ],
          ),
          content: const Text('Are you sure you want to log out of Digital Ekub? You will need to sign in again to access your account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                AuthService.instance.signOut(); // Triggers main.dart auth guard -> displays SignInScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔒 Signed out successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Confirm Logout'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, child) {
        final user = AuthService.instance.currentUser;
        if (user == null) return const SizedBox.shrink();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // User Info Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            user.name.split(" ").map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                user.phone,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: user.isAdmin ? Colors.purple.shade100 : Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  user.roleName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: user.isAdmin ? Colors.purple.shade900 : Theme.of(context).colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Role Switcher Test Card (Demonstrates Authorization Concept)
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_outlined, color: Colors.brown),
                            SizedBox(width: 8),
                            Text(
                              'Role Authorization Tester',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toggle user role to test Member vs. Admin permissions for creating & managing Ekubs.',
                          style: TextStyle(fontSize: 12, color: Colors.brown),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ChoiceChip(
                              label: const Text('Member Role'),
                              selected: user.isMember,
                              onSelected: (_) => AuthService.instance.switchRole(UserRole.member),
                            ),
                            ChoiceChip(
                              label: const Text('Admin (Organizer)'),
                              selected: user.isAdmin,
                              selectedColor: Colors.purple.shade200,
                              onSelected: (_) => AuthService.instance.switchRole(UserRole.admin),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Settings Card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Account Information'),
                        subtitle: const Text('Personal details and KYC verification'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showAccountInfoModal(context, user),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined),
                        title: const Text('Push Notifications'),
                        subtitle: const Text('Round reminders and draw alerts'),
                        value: user.notificationsEnabled,
                        onChanged: (val) {
                          AuthService.instance.toggleNotifications(val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? '🔔 Notifications enabled' : '🔕 Notifications disabled'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Security & Biometrics'),
                        subtitle: const Text('PIN code & fingerprint settings'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Security Settings'),
                              content: const Text('Biometric authentication & PIN code verification are active for local transactions.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
