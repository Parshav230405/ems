import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/teacher_academic_provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final academic = Provider.of<AcademicProvider>(context, listen: false);
      await academic.fetchClasses();
      if (academic.classes.isNotEmpty) {
        setState(() {
          _selectedClassId = academic.classes.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final academic = Provider.of<AcademicProvider>(context);

    // Mock weekly grid matching template
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final schedule = {
      'Monday': ['Maths', 'Science', 'English', 'Hindi', 'SST'],
      'Tuesday': ['Science', 'Maths', 'Computer', 'English', 'Maths'],
      'Wednesday': ['English', 'SST', 'Maths', 'Science', 'Hindi'],
      'Thursday': ['SST', 'Hindi', 'English', 'Science', 'Maths'],
      'Friday': ['Maths', 'Science', 'SST', 'English', 'Hindi'],
    };

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
                        'Timetable',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Class-wise weekly schedule and period allocation',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 180,
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            isDense: true,
                          ),
                          items: academic.classes.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('Class ${c.name}-${c.division}', style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedClassId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Timetable updated for selected class'),
                              duration: Duration(seconds: 1),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
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

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Period 1\n8:00 - 8:45', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Period 2\n8:45 - 9:30', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Period 3\n9:50 - 10:35', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Period 4\n10:35 - 11:20', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  DataColumn(label: Text('Period 5\n11:20 - 12:05', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                ],
                rows: days.map((day) {
                  final periods = schedule[day] ?? [];
                  return DataRow(
                    cells: [
                      DataCell(Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      ...periods.map((p) => DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      )),
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
