import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fees_exam_settings_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/url_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _academicYearController;
  late TextEditingController _principalController;

  List<dynamic> _usersList = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _nameController = TextEditingController(text: 'Bright Future Public School');
    _addressController = TextEditingController(text: '120 Education Road, Ahmedabad, Gujarat - 382115');
    _phoneController = TextEditingController(text: '+91 98765 43210');
    _emailController = TextEditingController(text: 'info@brightfuture.edu.in');
    _academicYearController = TextEditingController(text: '2025-2026');
    _principalController = TextEditingController(text: 'Dr. S. K. Mukherjee');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sp = Provider.of<SettingsProvider>(context, listen: false);
      await sp.fetchSettings();
      await sp.fetchBackups();
      _loadSettingsFromProvider();
      _fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _academicYearController.dispose();
    _principalController.dispose();
    super.dispose();
  }

  void _loadSettingsFromProvider() {
    final s = Provider.of<SettingsProvider>(context, listen: false).settings;
    if (s.containsKey('school_name')) _nameController.text = s['school_name']!;
    if (s.containsKey('school_address')) _addressController.text = s['school_address']!;
    if (s.containsKey('school_phone')) _phoneController.text = s['school_phone']!;
    if (s.containsKey('school_email')) _emailController.text = s['school_email']!;
    if (s.containsKey('academic_year')) _academicYearController.text = s['academic_year']!;
    if (s.containsKey('principal_name')) _principalController.text = s['principal_name']!;
  }

  void _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final res = await _api.get('/auth/users');
      setState(() {
        _usersList = res['users'] ?? [];
        _isLoadingUsers = false;
      });
    } catch (_) {
      setState(() => _isLoadingUsers = false);
    }
  }

  void _saveSettings() async {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final schoolName = _nameController.text.trim();
    final success = await sp.updateSettings({
      'school_name': schoolName,
      'school_address': _addressController.text.trim(),
      'school_phone': _phoneController.text.trim(),
      'school_email': _emailController.text.trim(),
      'academic_year': _academicYearController.text.trim(),
      'principal_name': _principalController.text.trim(),
    });

    if (mounted) {
      if (success) {
        Provider.of<AuthProvider>(context, listen: false).updateClientName(schoolName);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Settings updated successfully!' : 'Failed to update settings'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  void _triggerBackup() async {
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final success = await sp.triggerBackup();
    if (mounted) {
      if (success) {
        await sp.fetchBackups();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Database snapshot created and verified!' : 'Backup failed'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Staff@123');
    String role = 'STAFF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create User Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Name *')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Staff Email *')),
              const SizedBox(height: 8),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Temporary Password *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['STAFF', 'ADMIN'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => role = v ?? 'STAFF'),
              ),
            ],
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty && emailCtrl.text.trim().isNotEmpty) {
                  try {
                    await _api.post('/auth/users', {
                      'name': nameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'password': passCtrl.text.trim(),
                      'role': role,
                    });
                    if (mounted) Navigator.pop(ctx);
                    _fetchUsers();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
                      );
                    }
                  }
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final sp = Provider.of<SettingsProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings & Administration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('Configure school information, academic cycles, staff users, and automated continuous database backups', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),

            TabBar(
              controller: _tabController,
              onTap: (i) => setState(() {}),
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accent,
              tabs: const [
                Tab(text: 'School Information'),
                Tab(text: 'Academic Year'),
                Tab(text: 'User Management'),
                Tab(text: 'Database Backup'),
              ],
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 400),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: [
                  _buildSchoolInfoTab(auth.isAdmin),
                  _buildAcademicYearTab(auth.isAdmin),
                  _buildUserManagementTab(auth.isAdmin),
                  _buildBackupTab(sp, auth.isAdmin),
                ][_tabController.index],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolInfoTab(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField('School Name', _nameController, enabled: isAdmin),
        const SizedBox(height: 16),
        _buildFormField('Address', _addressController, enabled: isAdmin),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormField('Phone', _phoneController, enabled: isAdmin)),
            const SizedBox(width: 16),
            Expanded(child: _buildFormField('Email', _emailController, enabled: isAdmin)),
          ],
        ),
        const SizedBox(height: 16),
        _buildFormField('Principal Name', _principalController, enabled: isAdmin),
        const SizedBox(height: 24),
        if (isAdmin)
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes'),
          ),
      ],
    );
  }

  Widget _buildAcademicYearTab(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField('Current Academic Year', _academicYearController, enabled: isAdmin),
        const SizedBox(height: 16),
        const Text(
          'Academic year applies across admission numbering, class sessions, examination terms, and annual fee structures.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (isAdmin)
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update Academic Year'),
          ),
      ],
    );
  }

  Widget _buildUserManagementTab(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('System Users (Admin & Staff Accounts)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('+ Create Staff Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingUsers)
          const Center(child: CircularProgressIndicator())
        else
          DataTable(
            columns: const [
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _usersList.map<DataRow>((u) {
              return DataRow(
                cells: [
                  DataCell(Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(u['email'])),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: u['role'] == 'ADMIN' ? AppColors.accent.withOpacity(0.1) : AppColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        u['role'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: u['role'] == 'ADMIN' ? AppColors.accent : AppColors.success,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text((u['createdAt'] as String).split('T')[0])),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBackupTab(SettingsProvider sp, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continuous Database Backup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Exports entire database to JSON (universal database portability) and PostgreSQL SQL dumps', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: sp.isLoading ? null : _triggerBackup,
                icon: const Icon(Icons.backup_rounded, size: 16),
                label: sp.isLoading ? const Text('Creating Backup...') : const Text('Trigger Backup Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Stored Database Snapshots', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (sp.backups.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No database snapshots created yet.', style: TextStyle(color: AppColors.textMuted)),
          )
        else
          DataTable(
            columns: const [
              DataColumn(label: Text('Filename', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Size (KB)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Download Snapshot', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: sp.backups.map<DataRow>((b) {
              final dateStr = (b['createdAt'] as String).split('T')[0];
              return DataRow(
                cells: [
                  DataCell(Text(b['filename'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataCell(Text('${b['sizeKb']} KB', style: const TextStyle(fontSize: 12))),
                  DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    OutlinedButton.icon(
                      onPressed: () {
                        UrlHelper.openUrl(b['downloadUrl']);
                      },
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text('Download', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
