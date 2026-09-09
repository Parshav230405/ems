import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/fees_exam_settings_provider.dart';
import '../../providers/teacher_academic_provider.dart';

class ExaminationMarksScreen extends StatefulWidget {
  const ExaminationMarksScreen({super.key});

  @override
  State<ExaminationMarksScreen> createState() => _ExaminationMarksScreenState();
}

class _ExaminationMarksScreenState extends State<ExaminationMarksScreen> {
  String? _selectedExamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ep = Provider.of<ExamProvider>(context, listen: false);
      await ep.fetchExams();
      if (ep.exams.isNotEmpty) {
        setState(() {
          _selectedExamId = ep.exams.first['id'];
        });
        ep.fetchExamMarks(_selectedExamId!);
      }
    });
  }

  void _saveMarks() async {
    if (_selectedExamId == null) return;
    final ep = Provider.of<ExamProvider>(context, listen: false);
    final success = await ep.saveExamMarks(_selectedExamId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Marks saved successfully!' : 'Failed to save marks'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = Provider.of<ExamProvider>(context);
    final data = ep.currentExamMarksData;
    final students = (data != null && data['students'] is List) ? (data['students'] as List) : [];
    final exam = data?['exam'];

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
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Examination & Marks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage term exams, enter student marks, and auto-compute grades',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: ep.isLoading ? null : _saveMarks,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save Marks'),
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
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Exam selector toolbar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      value: _selectedExamId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        isDense: true,
                      ),
                      items: ep.exams.map((e) => DropdownMenuItem<String>(
                        value: e['id'] as String,
                        child: Text('${e['name']} - ${e['subject']?['name'] ?? ""}', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedExamId = val);
                          ep.fetchExamMarks(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (ep.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No student marks available for this examination.', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('Roll No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Marks (Max 100)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: List.generate(students.length, (index) {
                    final s = students[index];
                    final pct = s['percentage'] ?? 0.0;
                    final grade = s['grade'] ?? 'F';
                    final isPassed = s['isPassed'] ?? false;

                    return DataRow(
                      cells: [
                        DataCell(Text(s['rollNo'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  (s['studentName'] as String).isNotEmpty
                                      ? (s['studentName'] as String).substring(0, 1)
                                      : 'S',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(s['studentName'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 80,
                            height: 34,
                            child: TextFormField(
                              initialValue: s['marksObtained'].toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  ep.updateStudentMark(index, parsed);
                                }
                              },
                            ),
                          ),
                        ),
                        DataCell(Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPassed ? AppColors.successBg : AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              grade,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPassed ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            isPassed ? 'Passed' : 'Failed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
