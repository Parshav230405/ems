import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/teacher_academic_provider.dart';
import '../../models/academic_models.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _selectedClassId;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  final List<Map<String, String>> _periodMeta = [
    {'period': '1', 'time': '08:00 - 08:45', 'start': '08:00 AM', 'end': '08:45 AM'},
    {'period': '2', 'time': '08:45 - 09:30', 'start': '08:45 AM', 'end': '09:30 AM'},
    {'period': '3', 'time': '09:50 - 10:35', 'start': '09:50 AM', 'end': '10:35 AM'},
    {'period': '4', 'time': '10:35 - 11:20', 'start': '10:35 AM', 'end': '11:20 AM'},
    {'period': '5', 'time': '11:20 - 12:05', 'start': '11:20 AM', 'end': '12:05 PM'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final academic = Provider.of<AcademicProvider>(context, listen: false);
      final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);

      await Future.wait([
        academic.fetchClasses(),
        teacherProvider.fetchTeachers(),
      ]);

      if (academic.classes.isNotEmpty) {
        final firstClassId = academic.classes.first.id;
        setState(() {
          _selectedClassId = firstClassId;
        });
        await Future.wait([
          academic.fetchSubjects(classId: firstClassId),
          academic.fetchTimetable(firstClassId),
        ]);
      }
    });
  }

  void _onClassChanged(String? classId) async {
    if (classId == null || classId == _selectedClassId) return;
    setState(() {
      _selectedClassId = classId;
    });
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    await Future.wait([
      academic.fetchSubjects(classId: classId),
      academic.fetchTimetable(classId),
    ]);
  }

  void _showAssignPeriodDialog({
    required String day,
    required int period,
    required String defaultStart,
    required String defaultEnd,
    dynamic existingEntry,
  }) {
    if (_selectedClassId == null) return;
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    final subjects = academic.subjects;

    String? selectedSubjectId = existingEntry?['subjectId'] ?? (subjects.isNotEmpty ? subjects.first.id : null);
    final startCtrl = TextEditingController(text: existingEntry?['startTime'] ?? defaultStart);
    final endCtrl = TextEditingController(text: existingEntry?['endTime'] ?? defaultEnd);
    final formKey = GlobalKey<FormState>();

    // Current class name
    final currentClass = academic.classes.firstWhere(
      (c) => c.id == _selectedClassId,
      orElse: () => ClassModel(id: '', name: '', division: '', academicYear: ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
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
                        Text(
                          existingEntry != null ? 'Edit Period $period ($day)' : 'Assign Period $period ($day)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Class ${currentClass.name} - ${currentClass.division} (${currentClass.academicYear})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 24, color: AppColors.cardBorder),

                    if (subjects.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No subjects created for this class yet. Please add subjects in the Subjects tab.',
                                style: TextStyle(fontSize: 12, color: Colors.brown),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const Text('Select Course / Subject *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                        items: subjects.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text((s.code != null && s.code!.isNotEmpty) ? '${s.name} (${s.code})' : s.name),
                        )).toList(),
                        onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                        validator: (v) => v == null ? 'Please select a subject' : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: startCtrl,
                                decoration: InputDecoration(
                                  hintText: '08:00 AM',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: endCtrl,
                                decoration: InputDecoration(
                                  hintText: '08:45 AM',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (existingEntry != null)
                          TextButton.icon(
                            onPressed: () async {
                              final id = existingEntry['id'];
                              if (id != null) {
                                await academic.deleteTimetableEntry(id, _selectedClassId!);
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Period schedule cleared'), backgroundColor: AppColors.textSecondary),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                            label: const Text('Clear Period', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                          )
                        else
                          const SizedBox.shrink(),

                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.cardBorder),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: subjects.isEmpty ? null : () async {
                                if (formKey.currentState!.validate() && selectedSubjectId != null) {
                                  final success = await academic.saveTimetableEntry(
                                    classId: _selectedClassId!,
                                    dayOfWeek: day,
                                    period: period,
                                    subjectId: selectedSubjectId!,
                                    startTime: startCtrl.text.trim(),
                                    endTime: endCtrl.text.trim(),
                                  );
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Period scheduled successfully' : 'Failed to update timetable'),
                                        backgroundColor: success ? AppColors.success : AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Save Period'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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
    final classes = academic.classes;
    final timetableEntries = academic.timetableEntries;

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
            // Top Toolbar Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timetable Management',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Class-wise weekly schedule and interactive period allocation',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (classes.isNotEmpty)
                        SizedBox(
                          width: 220,
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            value: _selectedClassId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              isDense: true,
                            ),
                            items: classes.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('Class ${c.name}-${c.division} (${c.academicYear})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            )).toList(),
                            onChanged: _onClassChanged,
                          ),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _selectedClassId != null
                            ? () async {
                                await academic.fetchTimetable(_selectedClassId!);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Timetable refreshed'),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.refresh, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            if (classes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: Text('No classes found. Please create a class first in Classes & Divisions.', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else if (academic.isTimetableLoading)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 72,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  border: TableBorder.all(color: AppColors.cardBorder.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                  columns: [
                    const DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ..._periodMeta.map((p) => DataColumn(
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Period ${p['period']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(p['time']!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    )),
                  ],
                  rows: _days.map((day) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          ),
                        ),
                        ..._periodMeta.map((pMeta) {
                          final periodNum = int.parse(pMeta['period']!);
                          // Find entry matching day and period
                          final match = timetableEntries.firstWhere(
                            (e) => e['dayOfWeek'] == day && e['period'] == periodNum,
                            orElse: () => null,
                          );

                          if (match != null) {
                            final subjectName = match['subject']?['name'] ?? 'Assigned';
                            final teacherName = match['subject']?['teacher']?['name'];
                            return DataCell(
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _showAssignPeriodDialog(
                                  day: day,
                                  period: periodNum,
                                  defaultStart: pMeta['start']!,
                                  defaultEnd: pMeta['end']!,
                                  existingEntry: match,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        subjectName,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (teacherName != null)
                                        Text(
                                          teacherName,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return DataCell(
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _showAssignPeriodDialog(
                                  day: day,
                                  period: periodNum,
                                  defaultStart: pMeta['start']!,
                                  defaultEnd: pMeta['end']!,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 14, color: AppColors.textMuted),
                                      SizedBox(width: 4),
                                      Text('Assign', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
