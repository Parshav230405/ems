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
    final nameCtrl = TextEditingController(text: '10');
    final divCtrl = TextEditingController(text: 'A');
    final yearCtrl = TextEditingController(text: '2025-2026');
    final formKey = GlobalKey<FormState>();

    Widget buildFormField({
      required String label,
      required TextEditingController controller,
      required String hint,
      String? Function(String?)? validator,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
            validator: validator,
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Class & Division',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Configure class grade, division section, and academic year', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Divider(height: 24, color: AppColors.cardBorder),
                  buildFormField(
                    label: 'Class / Grade *',
                    controller: nameCtrl,
                    hint: 'e.g. 10 or 9',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Class required' : null,
                  ),
                  const SizedBox(height: 14),
                  buildFormField(
                    label: 'Division / Section *',
                    controller: divCtrl,
                    hint: 'e.g. A or B',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Division required' : null,
                  ),
                  const SizedBox(height: 14),
                  buildFormField(
                    label: 'Academic Year *',
                    controller: yearCtrl,
                    hint: 'e.g. 2025-2026',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Year required' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Create Class'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
                      label: const Text('Add Class'),
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
