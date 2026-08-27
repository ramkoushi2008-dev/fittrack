import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../privacy_policy_screen/privacy_policy_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _supabase = SupabaseService.instance;

  // Profile state
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  Map<String, dynamic>? _profile;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _selectedGender = '';
  String _selectedGoal = '';

  // Password state
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingPassword = false;

  // Devices state
  bool _isLoadingDevices = true;
  List<Map<String, dynamic>> _devices = [];

  // Health apps state
  bool _isLoadingApps = true;
  final List<Map<String, dynamic>> _healthAppDefs = [
    {'name': 'Apple Health', 'icon': Icons.favorite_rounded},
    {'name': 'Google Fit', 'icon': Icons.directions_run_rounded},
    {'name': 'Strava', 'icon': Icons.directions_bike_rounded},
    {'name': 'MyFitnessPal', 'icon': Icons.restaurant_rounded},
    {'name': 'Garmin Connect', 'icon': Icons.watch_rounded},
    {'name': 'Fitbit', 'icon': Icons.monitor_heart_rounded},
  ];
  Map<String, bool> _healthAppConnected = {};

  static const List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];
  static const List<String> _goals = [
    'Lose Weight',
    'Build Muscle',
    'Improve Endurance',
    'Stay Active',
    'Increase Flexibility',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadDevices(), _loadHealthApps()]);
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    final profile = await _supabase.fetchUserProfile();
    final user = Supabase.instance.client.auth.currentUser;
    if (mounted) {
      setState(() {
        _profile = profile;
        _nameCtrl.text =
            profile?['display_name'] ?? profile?['full_name'] ?? '';
        _emailCtrl.text = user?.email ?? profile?['email'] ?? '';
        _heightCtrl.text = profile?['height_cm']?.toString() ?? '';
        _weightCtrl.text = profile?['weight_kg']?.toString() ?? '';
        _selectedGender = profile?['gender'] ?? '';
        _selectedGoal = profile?['fitness_goal'] ?? '';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoadingDevices = true);
    final devices = await _supabase.fetchLinkedDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _isLoadingDevices = false;
      });
    }
  }

  Future<void> _loadHealthApps() async {
    setState(() => _isLoadingApps = true);
    final apps = await _supabase.fetchConnectedHealthApps();
    final Map<String, bool> map = {};
    for (final def in _healthAppDefs) {
      map[def['name'] as String] = false;
    }
    for (final app in apps) {
      map[app['app_name'] as String] = app['is_connected'] == true;
    }
    if (mounted) {
      setState(() {
        _healthAppConnected = map;
        _isLoadingApps = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    final success = await _supabase.updateUserProfile({
      'display_name': _nameCtrl.text.trim(),
      'gender': _selectedGender,
      'fitness_goal': _selectedGoal,
      'height_cm': double.tryParse(_heightCtrl.text.trim()),
      'weight_kg': double.tryParse(_weightCtrl.text.trim()),
    });
    if (mounted) {
      setState(() => _isSavingProfile = false);
      _showSnack(
        success ? 'Profile updated!' : 'Failed to update profile.',
        success,
      );
    }
  }

  Future<void> _savePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showSnack('Passwords do not match.', false);
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      _showSnack('Password must be at least 6 characters.', false);
      return;
    }
    setState(() => _isSavingPassword = true);
    final error = await _supabase.updatePassword(_newPassCtrl.text);
    if (mounted) {
      setState(() => _isSavingPassword = false);
      if (error == null) {
        _showSnack('Password updated successfully!', true);
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      } else {
        _showSnack('Failed to update password.', false);
      }
    }
  }

  Future<void> _addDevice() async {
    final nameCtrl = TextEditingController();
    String selectedType = 'wearable';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceVariantDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            'Add Device',
            style: GoogleFonts.manrope(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.manrope(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'e.g. Apple Watch Series 9',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: AppTheme.surfaceVariantDark,
                style: GoogleFonts.manrope(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Device Type'),
                items: ['wearable', 'phone', 'tablet', 'scale', 'other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedType = v ?? 'wearable'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  await _supabase.addLinkedDevice(
                    deviceName: nameCtrl.text.trim(),
                    deviceType: selectedType,
                  );
                  await _loadDevices();
                }
              },
              child: Text(
                'Add',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeDevice(String deviceId, String deviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariantDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          'Remove Device',
          style: GoogleFonts.manrope(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove "$deviceName" from your linked devices?',
          style: GoogleFonts.manrope(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _supabase.removeLinkedDevice(deviceId);
      await _loadDevices();
    }
  }

  void _showSnack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(color: const Color(0xFF1A1A1A)),
        ),
        backgroundColor: success ? AppTheme.primary : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildProfileSection(),
                    const SizedBox(height: 28),
                    _buildLinkedDevicesSection(),
                    const SizedBox(height: 28),
                    _buildHealthAppsSection(),
                    const SizedBox(height: 28),
                    _buildPasswordSection(),
                    const SizedBox(height: 28),
                    _buildLegalSection(),
                    const SizedBox(height: 28),
                    _buildDangerZoneSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantDark,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Account',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account Details', Icons.manage_accounts_rounded),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.all(20),
          child: _isLoadingProfile
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Avatar row
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _nameCtrl.text.isNotEmpty
                                  ? _nameCtrl.text[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.manrope(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text
                                    : 'Your Name',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _emailCtrl.text,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'Display Name',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      readOnly: true,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _heightCtrl,
                            label: 'Height (cm)',
                            icon: Icons.height_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _weightCtrl,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField(
                      label: 'Gender',
                      value: _selectedGender.isEmpty ? null : _selectedGender,
                      items: _genders,
                      icon: Icons.wc_rounded,
                      onChanged: (v) =>
                          setState(() => _selectedGender = v ?? ''),
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField(
                      label: 'Fitness Goal',
                      value: _selectedGoal.isEmpty ? null : _selectedGoal,
                      items: _goals,
                      icon: Icons.flag_outlined,
                      onChanged: (v) => setState(() => _selectedGoal = v ?? ''),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingProfile ? null : _saveProfile,
                        child: _isSavingProfile
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1A1A1A),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildLinkedDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Linked Devices', Icons.devices_rounded),
            GestureDetector(
              onTap: _addDevice,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: _isLoadingDevices
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        color: AppTheme.textMuted,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No devices linked yet',
                        style: GoogleFonts.manrope(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppTheme.surfaceVariantDark,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (_, i) {
                    final device = _devices[i];
                    final isConnected = device['is_connected'] == true;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? AppTheme.primaryContainer
                                  : AppTheme.surfaceVariantDark,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              _deviceIcon(
                                device['device_type'] as String? ?? 'wearable',
                              ),
                              color: isConnected
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device['device_name'] as String? ?? '',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isConnected ? 'Connected' : 'Disconnected',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: isConnected
                                        ? AppTheme.primary
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isConnected,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) async {
                              await _supabase.toggleDeviceConnection(
                                device['id'] as String,
                                val,
                              );
                              await _loadDevices();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            onPressed: () => _removeDevice(
                              device['id'] as String,
                              device['device_name'] as String? ?? '',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHealthAppsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Connected Health Apps',
          Icons.health_and_safety_rounded,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: _isLoadingApps
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _healthAppDefs.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppTheme.surfaceVariantDark,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (_, i) {
                    final appDef = _healthAppDefs[i];
                    final appName = appDef['name'] as String;
                    final isConnected = _healthAppConnected[appName] ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? AppTheme.primaryContainer
                                  : AppTheme.surfaceVariantDark,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              appDef['icon'] as IconData,
                              color: isConnected
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appName,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isConnected ? 'Connected' : 'Not connected',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: isConnected
                                        ? AppTheme.primary
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isConnected,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) async {
                              setState(
                                () => _healthAppConnected[appName] = val,
                              );
                              await _supabase.upsertHealthApp(
                                appName: appName,
                                isConnected: val,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Password', Icons.lock_outline_rounded),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildPasswordField(
                controller: _newPassCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 14),
              _buildPasswordField(
                controller: _confirmPassCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSavingPassword ? null : _savePassword,
                  child: _isSavingPassword
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Legal', Icons.gavel_rounded),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Privacy Policy',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              'How we collect and use your data',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Danger Zone',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppTheme.error.withAlpha(60), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(30),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppTheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Account',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Permanently remove your account and all data',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This action is irreversible. All your workouts, nutrition logs, sleep data, and account information will be permanently deleted from our servers.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: Text(
                    'Delete My Account',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _confirmDeleteAccount(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariantDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          'Delete Account?',
          style: GoogleFonts.manrope(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: GoogleFonts.manrope(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            ...[
              'All workout logs',
              'All nutrition entries',
              'All sleep records',
              'Linked devices & health apps',
              'Your profile & account',
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppTheme.error,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item,
                      style: GoogleFonts.manrope(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: GoogleFonts.manrope(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete Forever',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _showDeletingDialog();
      final error = await _supabase.deleteAccount();
      if (mounted) Navigator.of(context).pop(); // close deleting dialog
      if (error == null) {
        if (mounted) {
          context.go('/');
        }
      } else {
        if (mounted) {
          _showSnack('Failed to delete account. Please try again.', false);
        }
      }
    }
  }

  void _showDeletingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariantDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(
              color: AppTheme.error,
              strokeWidth: 2,
            ),
            const SizedBox(width: 20),
            Text(
              'Deleting account...',
              style: GoogleFonts.manrope(color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: GoogleFonts.manrope(
        color: readOnly ? AppTheme.textSecondary : AppTheme.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
        filled: true,
        fillColor: AppTheme.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppTheme.surfaceVariantDark,
      style: GoogleFonts.manrope(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
        filled: true,
        fillColor: AppTheme.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.manrope(color: AppTheme.textPrimary),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.manrope(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppTheme.textMuted,
          size: 18,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppTheme.textMuted,
            size: 18,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'phone':
        return Icons.smartphone_rounded;
      case 'tablet':
        return Icons.tablet_rounded;
      case 'scale':
        return Icons.monitor_weight_rounded;
      case 'wearable':
      default:
        return Icons.watch_rounded;
    }
  }
}
