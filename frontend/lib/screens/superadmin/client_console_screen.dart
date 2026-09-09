import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/client_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';

class ClientConsoleScreen extends StatefulWidget {
  const ClientConsoleScreen({super.key});

  @override
  State<ClientConsoleScreen> createState() => _ClientConsoleScreenState();
}

class _ClientConsoleScreenState extends State<ClientConsoleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientProvider>(context, listen: false).fetchClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final clientProvider = Provider.of<ClientProvider>(context);

    // Apply search and filter locally
    final query = _searchController.text.toLowerCase().trim();
    final filteredClients = clientProvider.clients.where((client) {
      final matchesSearch = query.isEmpty ||
          client.name.toLowerCase().contains(query) ||
          client.slug.toLowerCase().contains(query) ||
          client.adminEmail.toLowerCase().contains(query);

      final matchesStatus = _selectedStatusFilter == 'all' ||
          client.status.toLowerCase() == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Platform Header Bar
          _buildPlatformHeader(auth),

          // Main Content Body
          Expanded(
            child: clientProvider.isLoading && clientProvider.clients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Console Title & Overview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'School & College Accounts (Tenants)',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage provisioned educational institutions, configure tenant statuses, and onboard new clients.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddClientDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Onboard New School'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Metric Overview Cards
                        _buildMetricCards(clientProvider.stats),
                        const SizedBox(height: 24),

                        // Filter & Search Toolbar
                        _buildToolbar(),
                        const SizedBox(height: 16),

                        // Client Accounts Table
                        _buildClientTable(filteredClients, clientProvider),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformHeader(AuthProvider auth) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.domain_verification_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AURA EMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    'Platform Owner Console • Multi-Tenant Control',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      auth.currentUser?.name ?? 'Platform Super Admin',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  auth.logout();
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                tooltip: 'Logout of Platform Console',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              title: 'Total Onboarded Schools',
              value: stats['totalClients']?.toString() ?? '0',
              icon: Icons.school_outlined,
              color: AppColors.primary,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Active School Accounts',
              value: stats['activeClients']?.toString() ?? '0',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Suspended Accounts',
              value: stats['suspendedClients']?.toString() ?? '0',
              icon: Icons.pause_circle_outline,
              color: AppColors.danger,
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Total Enrolled Students',
              value: stats['totalStudents']?.toString() ?? '0',
              icon: Icons.people_outline,
              color: AppColors.accent,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Search input
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by school name, slug, or administrator email...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 16),

          // Status Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'active', child: Text('Active Only')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended Only')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatusFilter = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Refresh button
          IconButton(
            onPressed: () {
              Provider.of<ClientProvider>(context, listen: false).fetchClients();
            },
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Refresh Tenant List',
          ),
        ],
      ),
    );
  }

  Widget _buildClientTable(List<ClientModel> clients, ClientProvider provider) {
    if (clients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.domain_disabled, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No school accounts found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing your search query or click "+ Onboard New School" to create one.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('School / Institution Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Tenant Slug / Code', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Admin Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Students', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Teachers', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: clients.map((client) {
            final isActive = client.isActive;
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Onboarded: ${client.createdAt}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      client.slug,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataCell(Text(client.adminEmail)),
                DataCell(Text('${client.totalStudents}')),
                DataCell(Text('${client.totalTeachers}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Suspended',
                      style: TextStyle(
                        color: isActive ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Suspend / Reactivate button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final newStatus = isActive ? 'suspended' : 'active';
                          final success = await provider.updateStatus(client.id, newStatus);
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${client.name} status changed to $newStatus')),
                            );
                          }
                        },
                        icon: Icon(
                          isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          size: 16,
                          color: isActive ? AppColors.danger : AppColors.success,
                        ),
                        label: Text(
                          isActive ? 'Suspend' : 'Reactivate',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? AppColors.danger : AppColors.success,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isActive ? AppColors.danger.withOpacity(0.5) : AppColors.success.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Soft delete button
                      IconButton(
                        onPressed: () => _confirmDeactivateClient(context, client, provider),
                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                        tooltip: 'Deactivate School (Soft Delete)',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDeactivateClient(BuildContext context, ClientModel client, ClientProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate School Account?'),
        content: Text(
          'Are you sure you want to deactivate "${client.name}"? Users from this school will no longer be able to log in. School data will be preserved securely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.deleteClient(client.id);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deactivated school account for ${client.name}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Deactivate School', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddClientDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final adminEmailCtrl = TextEditingController();
    final adminPasswordCtrl = TextEditingController(text: 'Admin@123');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text('Onboard New School / Tenant', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This will provision an isolated database tenant, school administrator user, and default school settings.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'School / Institution Name *',
                          hintText: 'e.g. Oxford Cambridge International School',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        onChanged: (val) {
                          // Auto generate slug
                          final generatedSlug = val
                              .toLowerCase()
                              .trim()
                              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                              .replaceAll(RegExp(r'^-+|-+$'), '');
                          slugCtrl.text = generatedSlug;
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: slugCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tenant Slug (URL code) *',
                          hintText: 'e.g. oxford-cambridge',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: adminNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Initial Administrator Full Name *',
                          hintText: 'e.g. Principal Rajesh Sharma',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: adminEmailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Administrator Login Email *',
                          hintText: 'e.g. admin@oxfordcambridge.edu',
                        ),
                        validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: adminPasswordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Temporary Password *',
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final provider = Provider.of<ClientProvider>(context, listen: false);
                    final success = await provider.createClient(
                      name: nameCtrl.text.trim(),
                      slug: slugCtrl.text.trim(),
                      adminName: adminNameCtrl.text.trim(),
                      adminEmail: adminEmailCtrl.text.trim(),
                      adminPassword: adminPasswordCtrl.text.trim(),
                    );
                    if (context.mounted) {
                      if (success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New school client and administrator created successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.errorMessage ?? 'Failed to create school'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create School Account'),
              ),
            ],
          );
        },
      ),
    );
  }
}
