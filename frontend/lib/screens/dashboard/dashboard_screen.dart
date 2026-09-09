import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_model.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final dashboard = Provider.of<DashboardProvider>(context);

    if (dashboard.isLoading && dashboard.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = dashboard.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, ${auth.currentUser?.name ?? "Admin"}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Here's what's happening at your school today.",
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => dashboard.fetchDashboardData(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4 Stat Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: StatCard(
                      title: 'Total Students',
                      value: summary != null ? summary.totalStudents.toString() : '0',
                      trend: '+5%',
                      icon: Icons.people_alt_rounded,
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      onTap: () => AppShell.selectTab(context, 1),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: StatCard(
                      title: 'Total Teachers',
                      value: summary != null ? summary.totalTeachers.toString() : '0',
                      trend: '+2%',
                      icon: Icons.school_rounded,
                      iconBgColor: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF7C3AED),
                      onTap: () => AppShell.selectTab(context, 2),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: StatCard(
                      title: 'Total Classes',
                      value: summary != null ? summary.totalClasses.toString() : '0',
                      trend: '+1%',
                      icon: Icons.meeting_room_rounded,
                      iconBgColor: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      onTap: () => AppShell.selectTab(context, 3),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    child: StatCard(
                      title: 'Total Fees Collected',
                      value: summary != null
                          ? '₹ ${(summary.totalFeesCollected / 1000).toStringAsFixed(0)}K'
                          : '₹ 0',
                      trend: '+8%',
                      icon: Icons.account_balance_wallet_rounded,
                      iconBgColor: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      onTap: () => AppShell.selectTab(context, 7),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Middle Row: Today's Attendance + Pending Fees + Recent Admissions
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 950;
              return isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's Attendance Card
                        Expanded(
                          flex: 4,
                          child: _buildAttendanceCard(summary),
                        ),
                        const SizedBox(width: 16),
                        // Pending Fees Card
                        Expanded(
                          flex: 3,
                          child: _buildPendingFeesCard(summary),
                        ),
                        const SizedBox(width: 16),
                        // Recent Admissions
                        Expanded(
                          flex: 5,
                          child: _buildRecentAdmissionsCard(dashboard.recentAdmissions),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildAttendanceCard(summary),
                        const SizedBox(height: 16),
                        _buildPendingFeesCard(summary),
                        const SizedBox(height: 16),
                        _buildRecentAdmissionsCard(dashboard.recentAdmissions),
                      ],
                    );
            },
          ),

          const SizedBox(height: 24),

          // Bottom Row: Fee Collection Overview (Monthly Chart) + Notice Board
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 950;
              return isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _buildFeeOverviewCard(dashboard.monthlyFees),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _buildNoticeBoardCard(dashboard.recentNotices),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFeeOverviewCard(dashboard.monthlyFees),
                        const SizedBox(height: 16),
                        _buildNoticeBoardCard(dashboard.recentNotices),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(DashboardSummary? summary) {
    final pct = summary?.attendancePercentage ?? 100;
    final present = summary?.presentCount ?? 0;
    final absent = summary?.absentCount ?? 0;
    final leave = summary?.leaveCount ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AppShell.selectTab(context, 5),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Attendance",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Circular Donut Progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: pct / 100,
                          strokeWidth: 9,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendRow('Present', present.toString(), AppColors.accent),
                        const SizedBox(height: 8),
                        _buildLegendRow('Absent', absent.toString(), AppColors.danger),
                        const SizedBox(height: 8),
                        _buildLegendRow('On Leave', leave.toString(), AppColors.warning),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPendingFeesCard(DashboardSummary? summary) {
    final pending = summary?.pendingFees ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pending Fees',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 18),
          Text(
            '₹ ${pending.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.danger),
          ),
          const SizedBox(height: 8),
          const Text(
            'Across all academic classes',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => AppShell.selectTab(context, 7),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent),
                foregroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Fee Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAdmissionsCard(List<RecentAdmissionItem> admissions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Admissions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton(
                onPressed: () => AppShell.selectTab(context, 1),
                child: const Text('View All', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (admissions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No recent admissions', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: admissions.take(4).length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder, height: 16),
              itemBuilder: (context, index) {
                final item = admissions[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        item.name.isNotEmpty ? item.name.substring(0, 1) : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('Class ${item.className}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.admissionNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(item.date, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeeOverviewCard(List<MonthlyFeeItem> monthlyFees) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fee Collection Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  _buildLegendRow('Collected', '', AppColors.accent),
                  const SizedBox(width: 16),
                  _buildLegendRow('Pending', '', const Color(0xFFC7D2FE)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar visualization
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyFees.map((fee) {
                final collectedHeight = (fee.collected / 300000) * 120;
                final pendingHeight = (fee.pending / 300000) * 120;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 16,
                          height: collectedHeight.clamp(15.0, 120.0),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 16,
                          height: pendingHeight.clamp(10.0, 120.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7D2FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fee.month,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBoardCard(List<NoticeItem> notices) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Notice Board',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => AppShell.selectTab(context, 9),
                child: const Text('View All', style: TextStyle(fontSize: 12, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notices.take(3).length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder, height: 16),
            itemBuilder: (context, index) {
              final n = notices[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(n.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
