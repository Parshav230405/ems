import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/student_provider.dart';
import '../providers/teacher_academic_provider.dart';
import '../providers/fees_exam_settings_provider.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/students/student_list_screen.dart';
import '../screens/teachers/teacher_list_screen.dart';
import '../screens/academics/classes_screen.dart';
import '../screens/academics/subjects_screen.dart';
import '../screens/academics/attendance_screen.dart';
import '../screens/examination/examination_marks_screen.dart';
import '../screens/fees/fees_management_screen.dart';
import '../screens/academics/timetable_screen.dart';
import '../screens/notices/notices_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/certificates/certificate_generator_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/superadmin/client_console_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void selectTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    state?.selectTab(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void selectTab(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
      _onTabChanged(index);
    }
  }

  void _onTabChanged(int index) {
    switch (index) {
      case 0:
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
        break;
      case 1:
        Provider.of<StudentProvider>(context, listen: false).fetchStudents();
        break;
      case 2:
        Provider.of<TeacherProvider>(context, listen: false).fetchTeachers();
        break;
      case 3:
      case 4:
      case 5:
      case 8:
        Provider.of<AcademicProvider>(context, listen: false).fetchClasses();
        break;
      case 6:
        Provider.of<ExamProvider>(context, listen: false).fetchExams();
        break;
      case 7:
        final sp = Provider.of<StudentProvider>(context, listen: false);
        sp.fetchStudents();
        if (sp.students.isNotEmpty) {
          Provider.of<FeesProvider>(context, listen: false).fetchStudentFeeStatus(sp.students.first.id);
        }
        break;
      case 12:
        final sp = Provider.of<SettingsProvider>(context, listen: false);
        sp.fetchSettings();
        sp.fetchBackups();
        break;
    }
  }

  final List<String> _navTitles = [
    'Dashboard',
    'Students',
    'Teachers',
    'Classes & Divisions',
    'Subjects',
    'Attendance',
    'Examinations',
    'Fees',
    'Timetable',
    'Notices',
    'Reports',
    'Certificates',
    'Settings',
  ];

  final List<IconData> _navIcons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.school_rounded,
    Icons.domain_rounded,
    Icons.menu_book_rounded,
    Icons.event_available_rounded,
    Icons.assignment_turned_in_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.calendar_today_rounded,
    Icons.campaign_rounded,
    Icons.assessment_rounded,
    Icons.workspace_premium_rounded,
    Icons.settings_rounded,
  ];

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const StudentListScreen();
      case 2:
        return const TeacherListScreen();
      case 3:
        return const ClassesScreen();
      case 4:
        return const SubjectsScreen();
      case 5:
        return const AttendanceScreen();
      case 6:
        return const ExaminationMarksScreen();
      case 7:
        return const FeesManagementScreen();
      case 8:
        return const TimetableScreen();
      case 9:
        return const NoticesScreen();
      case 10:
        return const ReportsScreen();
      case 11:
        return const CertificateGeneratorScreen();
      case 12:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: AppColors.sidebarBg,
              child: _buildSidebar(isDrawer: true),
            )
          : null,
      body: Row(
        children: [
          // Persistent Sidebar on Desktop
          if (isDesktop)
            SizedBox(
              width: 250,
              child: _buildSidebar(isDrawer: false),
            ),

          // Main Area
          Expanded(
            child: Column(
              children: [
                // TopBar
                _buildTopBar(context, isDesktop, user),
                // Page Content
                Expanded(
                  child: _buildScreen(_selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // School Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sidebarActive,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AURA EMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Learn • Grow • Succeed',
                        style: TextStyle(
                          color: AppColors.sidebarText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: _navTitles.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () {
                      selectTab(index);
                      if (isDrawer) {
                        Navigator.of(context).pop(); // close drawer
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.sidebarActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _navIcons[index],
                            size: 20,
                            color: isSelected ? Colors.white : AppColors.sidebarText,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            _navTitles[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.sidebarText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom School Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF162235),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<AuthProvider>(context).currentUser?.clientName ??
                      'Bright Future Public School',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AY: 2025 - 2026',
                      style: TextStyle(
                        color: AppColors.sidebarText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop, dynamic user) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          // Search Box
          if (isDesktop)
            Container(
              width: 320,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search here...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Current Date Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Notification Bell
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => selectTab(9),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textSecondary),
            ),
          ),

          if (user?.isSuperAdmin == true) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClientConsoleScreen()));
              },
              icon: const Icon(Icons.domain_verification_rounded, size: 16),
              label: const Text('Platform Console'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // User Profile Pill & Role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user != null && user.name.isNotEmpty ? user.name.substring(0, 2).toUpperCase() : 'AD',
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.name ?? 'Admin',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      user?.role == 'ADMIN' ? 'Super Admin' : 'Staff Member',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
