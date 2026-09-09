import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/student_model.dart';

class StudentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<StudentModel> _students = [];
  int _totalStudents = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  String _searchQuery = '';
  String? _selectedClassId;
  String? _selectedStatus;

  // Selected student for profile view
  Map<String, dynamic>? _currentStudentProfile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StudentModel> get students => _students;
  int get totalStudents => _totalStudents;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String get searchQuery => _searchQuery;
  String? get selectedClassId => _selectedClassId;
  String? get selectedStatus => _selectedStatus;
  Map<String, dynamic>? get currentStudentProfile => _currentStudentProfile;

  Future<void> fetchStudents({int page = 1}) async {
    _isLoading = true;
    _currentPage = page;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': _limit.toString(),
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
        queryParams['classId'] = _selectedClassId!;
      }
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        queryParams['status'] = _selectedStatus!;
      }

      final res = await _api.get('/students', queryParams: queryParams);

      final List<dynamic> data = res['data'] ?? [];
      _students = data.map((item) => StudentModel.fromJson(item)).toList();
      _totalStudents = res['meta']?['total'] ?? 0;
      _totalPages = res['meta']?['totalPages'] ?? 1;

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
    fetchStudents(page: 1);
  }

  void setClassFilter(String? classId) {
    _selectedClassId = classId;
    fetchStudents(page: 1);
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    fetchStudents(page: 1);
  }

  Future<bool> createStudent(Map<String, dynamic> data) async {
    try {
      await _api.post('/students', data);
      await fetchStudents(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      await _api.put('/students/$id', data);
      await fetchStudents(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await _api.delete('/students/$id');
      await fetchStudents(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchStudentProfile(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/students/$studentId');
      _currentStudentProfile = res;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
