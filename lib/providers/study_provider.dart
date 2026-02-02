import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moiza/models/study_group_model.dart';
import 'package:moiza/models/user_model.dart';
import 'package:moiza/models/attendance_model.dart';
import 'package:moiza/services/study_service.dart';

class StudyProvider extends ChangeNotifier {
  final StudyService _studyService = StudyService();

  List<StudyGroupModel> _studyGroups = [];
  StudyGroupModel? _selectedStudyGroup;
  List<UserModel> _members = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _studyGroupsSubscription;
  StreamSubscription? _selectedGroupSubscription;

  List<StudyGroupModel> get studyGroups => _studyGroups;
  StudyGroupModel? get selectedStudyGroup => _selectedStudyGroup;
  List<UserModel> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadUserStudyGroups(String userId) {
    _studyGroupsSubscription?.cancel();
    _studyGroupsSubscription = _studyService
        .getUserStudyGroups(userId)
        .listen((groups) {
      _studyGroups = groups;
      notifyListeners();
    });
  }

  Future<StudyGroupModel?> createStudyGroup({
    required String name,
    required String description,
    required String ownerId,
    required String ownerNickname,
    PenaltyRule? penaltyRule,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final studyGroup = await _studyService.createStudyGroup(
        name: name,
        description: description,
        ownerId: ownerId,
        ownerNickname: ownerNickname,
        penaltyRule: penaltyRule,
      );
      _isLoading = false;
      notifyListeners();
      return studyGroup;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinStudyByInviteCode({
    required String inviteCode,
    required String userId,
    required String nickname,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _studyService.joinStudyByInviteCode(
        inviteCode: inviteCode,
        userId: userId,
        nickname: nickname,
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

  Future<bool> updateNickname({
    required String studyGroupId,
    required String userId,
    required String nickname,
  }) async {
    try {
      await _studyService.updateNickname(
        studyGroupId: studyGroupId,
        userId: userId,
        nickname: nickname,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectStudyGroup(String studyGroupId) {
    _selectedGroupSubscription?.cancel();
    _selectedGroupSubscription = _studyService
        .getStudyGroupStream(studyGroupId)
        .listen((group) async {
      _selectedStudyGroup = group;
      if (group != null) {
        _members = await _studyService.getStudyGroupMembers(group.memberIds);
      }
      notifyListeners();
    });
  }

  void clearSelectedStudyGroup() {
    _selectedGroupSubscription?.cancel();
    _selectedStudyGroup = null;
    _members = [];
    notifyListeners();
  }

  Future<void> leaveStudyGroup({
    required String studyGroupId,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _studyService.leaveStudyGroup(
        studyGroupId: studyGroupId,
        userId: userId,
      );
      clearSelectedStudyGroup();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 벌금 규칙 수정
  Future<bool> updatePenaltyRule({
    required String studyGroupId,
    required String modifiedBy,
    required PenaltyRule oldRule,
    required PenaltyRule newRule,
  }) async {
    try {
      await _studyService.updatePenaltyRule(
        studyGroupId: studyGroupId,
        modifiedBy: modifiedBy,
        oldRule: oldRule,
        newRule: newRule,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 방장 위임
  Future<bool> transferOwnership({
    required String studyGroupId,
    required String newOwnerId,
  }) async {
    try {
      await _studyService.transferOwnership(
        studyGroupId: studyGroupId,
        newOwnerId: newOwnerId,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 관리자 추가
  Future<bool> addAdmin({
    required String studyGroupId,
    required String userId,
  }) async {
    try {
      await _studyService.addAdmin(
        studyGroupId: studyGroupId,
        userId: userId,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 관리자 제거
  Future<bool> removeAdmin({
    required String studyGroupId,
    required String userId,
  }) async {
    try {
      await _studyService.removeAdmin(
        studyGroupId: studyGroupId,
        userId: userId,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 출석 시간 연장
  Future<bool> extendAttendanceSession({
    required String studyGroupId,
    required int additionalMinutes,
  }) async {
    try {
      await _studyService.extendAttendanceSession(
        studyGroupId: studyGroupId,
        additionalMinutes: additionalMinutes,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 출석 세션 시작
  Future<AttendanceSession?> startAttendanceSession({
    required String studyGroupId,
    required String startedBy,
    required int durationMinutes,
    int lateThresholdSeconds = 300,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _studyService.startAttendanceSession(
        studyGroupId: studyGroupId,
        startedBy: startedBy,
        durationMinutes: durationMinutes,
        lateThresholdSeconds: lateThresholdSeconds,
      );
      _isLoading = false;
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // 출석 세션 종료
  Future<bool> endAttendanceSession(String studyGroupId) async {
    try {
      await _studyService.endAttendanceSession(studyGroupId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 출석 체크
  Future<String?> checkInWithWord({
    required String studyGroupId,
    required String userId,
    required String word,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await _studyService.checkInWithWord(
        studyGroupId: studyGroupId,
        userId: userId,
        word: word,
      );
      _isLoading = false;
      notifyListeners();
      return status;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _studyGroupsSubscription?.cancel();
    _selectedGroupSubscription?.cancel();
    super.dispose();
  }
}
