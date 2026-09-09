import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/academic_models.dart';

class TeacherProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<TeacherModel> _teachers = [];
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TeacherModel> get teachers => _teachers;
  String get searchQuery => _searchQuery;

  Future<void> fetchTeachers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;

      final res = await _api.get('/teachers', queryParams: queryParams);
      final List<dynamic> data = res['data'] ?? [];
      _teachers = data.map((t) => TeacherModel.fromJson(t)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchTeachers();
  }

  Future<bool> createTeacher(Map<String, dynamic> data) async {
    try {
      await _api.post('/teachers', data);
      await fetchTeachers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTeacher(String id, Map<String, dynamic> data) async {
    try {
      await _api.put('/teachers/$id', data);
      await fetchTeachers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTeacher(String id) async {
    try {
      await _api.delete('/teachers/$id');
      await fetchTeachers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class AcademicProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];

  // Attendance state
  List<dynamic> _attendanceList = [];
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ClassModel> get classes => _classes;
  List<SubjectModel> get subjects => _subjects;
  List<dynamic> get attendanceList => _attendanceList;
  DateTime get selectedDate => _selectedDate;
  String? get selectedClassId => _selectedClassId;

  Future<void> fetchClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/classes');
      final List<dynamic> data = res['data'] ?? [];
      _classes = data.map((c) => ClassModel.fromJson(c)).toList();
      if (_classes.isNotEmpty && _selectedClassId == null) {
        _selectedClassId = _classes.first.id;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchSubjects({String? classId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = classId != null ? {'classId': classId} : null;
      final res = await _api.get('/subjects', queryParams: queryParams);
      final List<dynamic> data = res['data'] ?? [];
      _subjects = data.map((s) => SubjectModel.fromJson(s)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createClass(String name, String division, String academicYear) async {
    try {
      await _api.post('/classes', {
        'name': name,
        'division': division,
        'academicYear': academicYear,
      });
      await fetchClasses();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    try {
      await _api.delete('/classes/$id');
      await fetchClasses();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createSubject(String name, String? code, String classId, String? teacherId) async {
    try {
      await _api.post('/subjects', {
        'name': name,
        'code': code,
        'classId': classId,
        'teacherId': teacherId,
      });
      await fetchSubjects(classId: classId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Attendance methods
  void setAttendanceDate(DateTime date) {
    _selectedDate = date;
    fetchAttendance();
  }

  void setAttendanceClass(String classId) {
    _selectedClassId = classId;
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    if (_selectedClassId == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final res = await _api.get('/attendance', queryParams: {
        'classId': _selectedClassId!,
        'date': dateStr,
      });
      _attendanceList = res['data'] ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void updateStudentAttendanceStatus(int index, String status) {
    if (index >= 0 && index < _attendanceList.length) {
      _attendanceList[index]['status'] = status;
      notifyListeners();
    }
  }

  Future<bool> saveAttendance() async {
    if (_selectedClassId == null || _attendanceList.isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final records = _attendanceList.map((item) => {
        'studentId': item['studentId'],
        'status': item['status'],
      }).toList();

      await _api.post('/attendance', {
        'classId': _selectedClassId,
        'date': dateStr,
        'records': records,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
