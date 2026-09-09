class DashboardSummary {
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final double totalFeesCollected;
  final double pendingFees;
  final int attendancePercentage;
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final String attendanceDate;

  DashboardSummary({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.totalFeesCollected,
    required this.pendingFees,
    required this.attendancePercentage,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.attendanceDate,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final att = json['attendance'] ?? {};
    return DashboardSummary(
      totalStudents: json['totalStudents'] ?? 0,
      totalTeachers: json['totalTeachers'] ?? 0,
      totalClasses: json['totalClasses'] ?? 0,
      totalFeesCollected: (json['totalFeesCollected'] as num?)?.toDouble() ?? 0.0,
      pendingFees: (json['pendingFees'] as num?)?.toDouble() ?? 0.0,
      attendancePercentage: att['percentage'] ?? 100,
      presentCount: att['present'] ?? 0,
      absentCount: att['absent'] ?? 0,
      leaveCount: att['leave'] ?? 0,
      attendanceDate: att['date'] ?? '',
    );
  }
}

class RecentAdmissionItem {
  final String id;
  final String name;
  final String admissionNumber;
  final String className;
  final String date;

  RecentAdmissionItem({
    required this.id,
    required this.name,
    required this.admissionNumber,
    required this.className,
    required this.date,
  });

  factory RecentAdmissionItem.fromJson(Map<String, dynamic> json) {
    return RecentAdmissionItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      className: json['class'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class NoticeItem {
  final String id;
  final String title;
  final String body;
  final String date;

  NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class MonthlyFeeItem {
  final String month;
  final double collected;
  final double pending;

  MonthlyFeeItem({
    required this.month,
    required this.collected,
    required this.pending,
  });

  factory MonthlyFeeItem.fromJson(Map<String, dynamic> json) {
    return MonthlyFeeItem(
      month: json['month'] ?? '',
      collected: (json['collected'] as num?)?.toDouble() ?? 0.0,
      pending: (json['pending'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
