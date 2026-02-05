import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moiza/models/attendance_model.dart';
import 'package:moiza/services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  List<AttendanceModel> _attendances = [];
  bool _isLoading = false;
  bool _hasCheckedInToday = false;
  String? _error;

  StreamSubscription? _attendanceSubscription;

  List<AttendanceModel> get attendances => _attendances;
  bool get isLoading => _isLoading;
  bool get hasCheckedInToday => _hasCheckedInToday;
  String? get error => _error;

  void loadUserAttendance({
    required String studyGroupId,
    required String userId,
  }) {
    _attendanceSubscription?.cancel();
    _attendanceSubscription = _attendanceService
        .getUserAttendanceStream(
          studyGroupId: studyGroupId,
          userId: userId,
        )
        .listen((attendances) {
      _attendances = attendances;
      notifyListeners();
    });

    // 오늘 출석 여부 확인
    checkTodayAttendance(studyGroupId: studyGroupId, userId: userId);
  }

  Future<void> checkTodayAttendance({
    required String studyGroupId,
    required String userId,
  }) async {
    _hasCheckedInToday = await _attendanceService.hasCheckedInToday(
      studyGroupId: studyGroupId,
      userId: userId,
    );
    notifyListeners();
  }

  Future<bool> checkIn({
    required String studyGroupId,
    required String userId,
    required String status,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _attendanceService.checkIn(
        studyGroupId: studyGroupId,
        userId: userId,
        status: status,
        note: note,
      );
      _hasCheckedInToday = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<AttendanceModel>> getAttendanceByDate({
    required String studyGroupId,
    required DateTime date,
  }) async {
    return await _attendanceService.getAttendanceByDate(
      studyGroupId: studyGroupId,
      date: date,
    );
  }

  // 출석 상태 수동 변경 (관리자/방장 전용)
  Future<bool> updateAttendanceStatus({
    required String attendanceId,
    required String studyGroupId,
    required String userId,
    required String oldStatus,
    required String newStatus,
    required DateTime date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _attendanceService.updateAttendanceStatus(
        attendanceId: attendanceId,
        studyGroupId: studyGroupId,
        userId: userId,
        oldStatus: oldStatus,
        newStatus: newStatus,
        date: date,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    super.dispose();
  }
}
