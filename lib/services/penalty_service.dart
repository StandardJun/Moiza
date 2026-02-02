import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_penalty/config/constants.dart';
import 'package:study_penalty/models/penalty_model.dart';
import 'package:study_penalty/models/user_model.dart';

class PenaltySummary {
  final String oderId;
  final String userName;
  final int totalPenalty;
  final int paidAmount;
  final int unpaidAmount;
  final List<PenaltyModel> penalties;

  PenaltySummary({
    required this.oderId,
    required this.userName,
    required this.totalPenalty,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.penalties,
  });
}

class PenaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 벌금 추가 (수동)
  Future<PenaltyModel> addPenalty({
    required String studyGroupId,
    required String userId,
    required String type,
    required int amount,
    String? note,
  }) async {
    final docRef = _firestore.collection(AppConstants.penaltiesCollection).doc();

    final penalty = PenaltyModel(
      id: docRef.id,
      studyGroupId: studyGroupId,
      userId: userId,
      type: type,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );

    await docRef.set(penalty.toFirestore());
    return penalty;
  }

  // 벌금 납부 처리
  Future<void> markAsPaid(String penaltyId) async {
    await _firestore
        .collection(AppConstants.penaltiesCollection)
        .doc(penaltyId)
        .update({'isPaid': true});
  }

  // 벌금 삭제
  Future<void> deletePenalty(String penaltyId) async {
    await _firestore
        .collection(AppConstants.penaltiesCollection)
        .doc(penaltyId)
        .delete();
  }

  // 스터디 그룹의 모든 벌금 가져오기
  Stream<List<PenaltyModel>> getStudyGroupPenalties(String studyGroupId) {
    return _firestore
        .collection(AppConstants.penaltiesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PenaltyModel.fromFirestore(doc))
            .toList());
  }

  // 사용자의 벌금 가져오기
  Stream<List<PenaltyModel>> getUserPenalties({
    required String studyGroupId,
    required String userId,
  }) {
    return _firestore
        .collection(AppConstants.penaltiesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PenaltyModel.fromFirestore(doc))
            .toList());
  }

  // 사용자별 벌금 요약 계산
  Future<List<PenaltySummary>> getPenaltySummaries({
    required String studyGroupId,
    required List<UserModel> members,
  }) async {
    final List<PenaltySummary> summaries = [];

    for (final member in members) {
      final querySnapshot = await _firestore
          .collection(AppConstants.penaltiesCollection)
          .where('studyGroupId', isEqualTo: studyGroupId)
          .where('userId', isEqualTo: member.id)
          .get();

      final penalties = querySnapshot.docs
          .map((doc) => PenaltyModel.fromFirestore(doc))
          .toList();

      int totalPenalty = 0;
      int paidAmount = 0;

      for (final penalty in penalties) {
        totalPenalty += penalty.amount;
        if (penalty.isPaid) {
          paidAmount += penalty.amount;
        }
      }

      summaries.add(PenaltySummary(
        oderId: member.id,
        userName: member.displayName,
        totalPenalty: totalPenalty,
        paidAmount: paidAmount,
        unpaidAmount: totalPenalty - paidAmount,
        penalties: penalties,
      ));
    }

    // 미납 금액 순으로 정렬
    summaries.sort((a, b) => b.unpaidAmount.compareTo(a.unpaidAmount));

    return summaries;
  }

  // 스터디 그룹 전체 벌금 통계
  Future<Map<String, int>> getStudyGroupPenaltyStats(String studyGroupId) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.penaltiesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .get();

    int total = 0;
    int paid = 0;
    int unpaid = 0;

    for (final doc in querySnapshot.docs) {
      final penalty = PenaltyModel.fromFirestore(doc);
      total += penalty.amount;
      if (penalty.isPaid) {
        paid += penalty.amount;
      } else {
        unpaid += penalty.amount;
      }
    }

    return {
      'total': total,
      'paid': paid,
      'unpaid': unpaid,
    };
  }
}
