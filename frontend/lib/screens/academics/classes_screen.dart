import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_academic_provider.dart';
import '../../widgets/confirm_dialog.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AcademicProvider>(context, listen: false).fetchClasses();
    });
  }

  void _showAddClassDialog() {
    final nameCtrl = TextEditingController();
    final divCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2025-2026');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Class & Division'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Class / Grade * (e.g. 10)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Class required' : null,
              ),
              TextFormField(
                controller: divCtrl,
                decoration: const InputDecoration(labelText: 'Division / Section * (e.g. A)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Division required' : null,
              ),
              TextFormField(
                controller: yearCtrl,
                decoration: const InputDecoration(labelText: 'Academic Year * (e.g. 2025-2026)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Year required' : null,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await Provider.of<AcademicProvider>(context, listen: false).createClass(
                  nameCtrl.text.trim(),
                  divCtrl.text.trim(),
                  yearCtrl.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create Class'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academic = Provider.of<AcademicProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classes & Divisions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage standard grades, sections, and academic year allocations',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (auth.isAdmin)
                    ElevatedButton.icon(
                      onPressed: _showAddClassDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Add Class'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),

            if (academic.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (academic.classes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No classes found.', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Class Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Division', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Academic Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Enrolled Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: academic.classes.map((c) {
                  return DataRow(
                    cells: [
                      DataCell(Text('Class ${c.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      DataCell(Text('Section ${c.division}', style: const TextStyle(fontSize: 12))),
                      DataCell(Text(c.academicYear, style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${c.studentCount} Students', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold))),
                      DataCell(Text('${c.subjectCount} Subjects', style: const TextStyle(fontSize: 12))),
                      DataCell(
                        auth.isAdmin
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                tooltip: 'Delete Class',
                                onPressed: () async {
                                  final confirmed = await ConfirmDialog.show(
                                    context,
                                    title: 'Delete Class',
                                    message: 'Are you sure you want to delete Class ${c.name}-${c.division}? (Class must not have active students)',
                                  );
                                  if (confirmed) {
                                    await academic.deleteClass(c.id);
                                  }
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
