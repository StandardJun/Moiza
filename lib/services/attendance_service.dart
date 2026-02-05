import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moiza/config/constants.dart';
import 'package:moiza/models/attendance_model.dart';
import 'package:moiza/models/penalty_model.dart';
import 'package:moiza/models/study_group_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 출석 체크
  Future<AttendanceModel> checkIn({
    required String studyGroupId,
    required String userId,
    required String status,
    String? note,
  }) async {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);

    // 오늘 이미 출석했는지 확인
    final existing = await _firestore
        .collection(AppConstants.attendancesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw '오늘 이미 출석 체크를 완료했습니다.';
    }

    final docRef = _firestore.collection(AppConstants.attendancesCollection).doc();

    final attendance = AttendanceModel(
      id: docRef.id,
      studyGroupId: studyGroupId,
      userId: userId,
      status: status,
      date: dateOnly,
      checkInTime: now,
      note: note,
    );

    await docRef.set(attendance.toFirestore());

    // 지각/결석인 경우 벌금 자동 생성
    if (status == AttendanceStatus.late || status == AttendanceStatus.absent) {
      await _createPenaltyForAttendance(
        studyGroupId: studyGroupId,
        userId: userId,
        status: status,
        date: dateOnly,
      );
    }

    return attendance;
  }

  // 출석 상태에 따른 벌금 생성
  Future<void> _createPenaltyForAttendance({
    required String studyGroupId,
    required String userId,
    required String status,
    required DateTime date,
  }) async {
    // 스터디 그룹의 벌금 규칙 가져오기
    final studyDoc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (!studyDoc.exists) return;

    final studyGroup = StudyGroupModel.fromFirestore(studyDoc);
    final penaltyRule = studyGroup.penaltyRule;

    String penaltyType;
    int amount;

    if (status == AttendanceStatus.late) {
      penaltyType = PenaltyType.late;
      amount = penaltyRule.latePenalty;
    } else {
      penaltyType = PenaltyType.absent;
      amount = penaltyRule.absentPenalty;
    }

    final penaltyDocRef = _firestore.collection(AppConstants.penaltiesCollection).doc();

    final penalty = PenaltyModel(
      id: penaltyDocRef.id,
      studyGroupId: studyGroupId,
      userId: userId,
      type: penaltyType,
      amount: amount,
      date: date,
    );

    await penaltyDocRef.set(penalty.toFirestore());
  }

  // 특정 날짜의 출석 기록 가져오기
  Future<List<AttendanceModel>> getAttendanceByDate({
    required String studyGroupId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final querySnapshot = await _firestore
        .collection(AppConstants.attendancesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .get();

    return querySnapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();
  }

  // 사용자의 출석 기록 가져오기
  Stream<List<AttendanceModel>> getUserAttendanceStream({
    required String studyGroupId,
    required String userId,
  }) {
    return _firestore
        .collection(AppConstants.attendancesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList());
  }

  // 출석 상태 수동 변경 (관리자/방장 전용)
  Future<void> updateAttendanceStatus({
    required String attendanceId,
    required String studyGroupId,
    required String userId,
    required String oldStatus,
    required String newStatus,
    required DateTime date,
  }) async {
    // 출석 기록 상태 업데이트
    await _firestore
        .collection(AppConstants.attendancesCollection)
        .doc(attendanceId)
        .update({'status': newStatus});

    // 기존 벌금 삭제 (해당 날짜, 사용자, 출석 관련 벌금)
    final oldPenalties = await _firestore
        .collection(AppConstants.penaltiesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .where('type', whereIn: [PenaltyType.late, PenaltyType.absent])
        .get();

    for (final doc in oldPenalties.docs) {
      await doc.reference.delete();
    }

    // 새 상태에 따라 벌금 생성
    if (newStatus == AttendanceStatus.late || newStatus == AttendanceStatus.absent) {
      await _createPenaltyForAttendance(
        studyGroupId: studyGroupId,
        userId: userId,
        status: newStatus,
        date: date,
      );
    }
  }

  // 오늘 출석 여부 확인
  Future<bool> hasCheckedInToday({
    required String studyGroupId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);

    final querySnapshot = await _firestore
        .collection(AppConstants.attendancesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
