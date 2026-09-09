import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/fees_exam_settings_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/utils/url_helper.dart';

class FeesManagementScreen extends StatefulWidget {
  const FeesManagementScreen({super.key});

  @override
  State<FeesManagementScreen> createState() => _FeesManagementScreenState();
}

class _FeesManagementScreenState extends State<FeesManagementScreen> {
  final _searchController = TextEditingController(text: 'Rahul');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sp = Provider.of<StudentProvider>(context, listen: false);
      await sp.fetchStudents();
      if (sp.students.isNotEmpty) {
        Provider.of<FeesProvider>(context, listen: false).fetchStudentFeeStatus(sp.students.first.id);
      }
    });
  }

  void _showAddPaymentDialog(String studentId, double pendingAmount) {
    final amountCtrl = TextEditingController(text: pendingAmount > 0 ? pendingAmount.toStringAsFixed(0) : '5000');
    final notesCtrl = TextEditingController(text: 'Term Fee Installment');
    String mode = 'CASH';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Record Fee Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (INR) *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: ['CASH', 'UPI', 'CHEQUE', 'BANK_TRANSFER', 'ONLINE']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => mode = v ?? 'CASH'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Remarks'),
              ),
            ],
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (amt != null && amt > 0) {
                  final fp = Provider.of<FeesProvider>(context, listen: false);
                  final success = await fp.recordPayment(studentId: studentId, amountPaid: amt, mode: mode, notes: notesCtrl.text.trim());
                  if (mounted) {
                    Navigator.pop(ctx);
                    if (success) {
                      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Payment of ₹ ${amt.toStringAsFixed(0)} recorded successfully!' : 'Failed to record payment'),
                        backgroundColor: success ? AppColors.success : AppColors.danger,
                      ),
                    );
                  }
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadReceipt(String receiptNo) {
    UrlHelper.openUrl('http://localhost:5000/api/fees/receipts/$receiptNo/download');
  }

  @override
  Widget build(BuildContext context) {
    final fees = Provider.of<FeesProvider>(context);
    final sp = Provider.of<StudentProvider>(context);
    final studentData = fees.selectedStudentFeeStatus;

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
                        'Fees Management',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track tuition fee structures, record offline payments, and generate official receipts',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 250,
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: studentData?['student']?['id'],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            isDense: true,
                          ),
                          hint: const Text('Select Student', style: TextStyle(fontSize: 12)),
                          items: sp.students.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.admissionNumber})', style: const TextStyle(fontSize: 12)),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) fees.fetchStudentFeeStatus(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            if (fees.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (studentData == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('Please select a student to view fee details.', style: TextStyle(color: AppColors.textMuted))),
              )
            else ...[
              // Student Header & Highlights Card
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              (studentData['student']['name'] as String).substring(0, 1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accent),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentData['student']['name'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Class: ${studentData['student']['class']} • Adm No: ${studentData['student']['admissionNumber']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _showAddPaymentDialog(
                              studentData['student']['id'],
                              (studentData['pendingFee'] as num).toDouble(),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('+ Add Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeePill('Total Class Fee', '₹ ${(studentData['totalFee'] as num).toStringAsFixed(0)}', AppColors.textPrimary),
                          _buildFeePill('Amount Paid', '₹ ${(studentData['totalPaid'] as num).toStringAsFixed(0)}', AppColors.success),
                          _buildFeePill('Pending Fees', '₹ ${(studentData['pendingFee'] as num).toStringAsFixed(0)}', AppColors.danger),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Payment Installments History Table
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment History & Receipts',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    if ((studentData['payments'] as List).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No payment entries recorded yet.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('Receipt No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Receipt Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: (studentData['payments'] as List).map<DataRow>((p) {
                          final dateStr = (p['paymentDate'] as String).split('T')[0];
                          return DataRow(
                            cells: [
                              DataCell(Text(p['receiptNo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataCell(Text('₹ ${p['amountPaid']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success))),
                              DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(p['mode'], style: const TextStyle(fontSize: 12))),
                              DataCell(Text(p['notes'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(
                                OutlinedButton.icon(
                                  onPressed: () => _downloadReceipt(p['receiptNo']),
                                  icon: const Icon(Icons.download_rounded, size: 14),
                                  label: const Text('PDF Receipt', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primary),
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeePill(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
