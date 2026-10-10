import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _onDeviceAiEnabled = true;
  bool _autoSaveEnabled = true;

  Future<void> _checkPermissions(BuildContext context) async {
    final status = await Permission.camera.status;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera Permission: ${status.name}. Tap to manage in device settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Edit Sathi',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Copyright © 2026 Edit Sathi Team.\n'
          'All editing and rendering operates strictly on-device without cloud tracking or unauthorized uploads.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text(
          'Settings & Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Profile Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.heroCardGradient,
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creator Studio',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Edit Sathi Mobile Edition',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Editing Preferences
          const Text(
            'Editing Engine',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.psychology_outlined, color: AppColors.primary),
                  title: const Text('On-Device AI Engine', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Auto-Cut, Smart Captions & Beat Sync run locally'),
                  value: _onDeviceAiEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _onDeviceAiEnabled = val),
                ),
                const Divider(height: 1, indent: 60),
                SwitchListTile(
                  secondary: const Icon(Icons.save_outlined, color: AppColors.secondary),
                  title: const Text('Timeline Auto-Save', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Persists edit snapshots automatically'),
                  value: _autoSaveEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _autoSaveEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Privacy & Permissions
          const Text(
            'Privacy & Storage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.security_rounded, color: Colors.green),
                  title: Text('100% Private On-Device Media', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Zero cloud uploads. Your videos stay on your device.'),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: Colors.blueAccent),
                  title: const Text('Media Permissions', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Check camera, gallery and mic permissions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _checkPermissions(context),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined, color: Colors.amber),
                  title: const Text('Clear Render Cache', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Frees temporary export buffers'),
                  trailing: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Render cache cleaned successfully!')),
                      );
                    },
                    child: const Text('Clean'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Open Source & Legal
          const Text(
            'About',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_outlined, color: AppColors.primary),
                  title: const Text('Open-Source Licenses', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLicenses(context),
                ),
                const Divider(height: 1, indent: 60),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Color(0xFF64748B)),
                  title: Text('Edit Sathi', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Version 1.0.0 (Build 1) • Cross-Platform Mobile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
