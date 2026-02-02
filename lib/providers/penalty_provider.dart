import 'dart:async';
import 'package:flutter/material.dart';
import 'package:study_penalty/models/penalty_model.dart';
import 'package:study_penalty/models/user_model.dart';
import 'package:study_penalty/services/penalty_service.dart';

class PenaltyProvider extends ChangeNotifier {
  final PenaltyService _penaltyService = PenaltyService();

  List<PenaltyModel> _penalties = [];
  List<PenaltySummary> _penaltySummaries = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _penaltySubscription;

  List<PenaltyModel> get penalties => _penalties;
  List<PenaltySummary> get penaltySummaries => _penaltySummaries;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadStudyGroupPenalties(String studyGroupId) {
    _penaltySubscription?.cancel();
    _penaltySubscription = _penaltyService
        .getStudyGroupPenalties(studyGroupId)
        .listen((penalties) {
      _penalties = penalties;
      notifyListeners();
    });

    // 통계 로드
    loadStats(studyGroupId);
  }

  Future<void> loadStats(String studyGroupId) async {
    _stats = await _penaltyService.getStudyGroupPenaltyStats(studyGroupId);
    notifyListeners();
  }

  Future<void> loadPenaltySummaries({
    required String studyGroupId,
    required List<UserModel> members,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _penaltySummaries = await _penaltyService.getPenaltySummaries(
        studyGroupId: studyGroupId,
        members: members,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPenalty({
    required String studyGroupId,
    required String userId,
    required String type,
    required int amount,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _penaltyService.addPenalty(
        studyGroupId: studyGroupId,
        userId: userId,
        type: type,
        amount: amount,
        note: note,
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

  Future<void> markAsPaid(String penaltyId) async {
    try {
      await _penaltyService.markAsPaid(penaltyId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePenalty(String penaltyId) async {
    try {
      await _penaltyService.deletePenalty(penaltyId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _penaltySubscription?.cancel();
    super.dispose();
  }
}
