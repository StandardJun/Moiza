import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:moiza/config/constants.dart';
import 'package:moiza/models/study_group_model.dart';
import 'package:moiza/models/user_model.dart';
import 'package:moiza/models/attendance_model.dart';

class StudyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // 스터디 그룹 생성
  Future<StudyGroupModel> createStudyGroup({
    required String name,
    required String description,
    required String ownerId,
    required String ownerNickname,
    PenaltyRule? penaltyRule,
  }) async {
    final inviteCode = _generateInviteCode();
    final docRef = _firestore.collection(AppConstants.studyGroupsCollection).doc();

    final studyGroup = StudyGroupModel(
      id: docRef.id,
      name: name,
      description: description,
      ownerId: ownerId,
      memberIds: [ownerId],
      memberNicknames: {ownerId: ownerNickname},
      penaltyRule: penaltyRule ?? PenaltyRule(),
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );

    await docRef.set(studyGroup.toFirestore());

    // 사용자의 studyGroupIds에 추가
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(ownerId)
        .update({
      'studyGroupIds': FieldValue.arrayUnion([docRef.id]),
    });

    return studyGroup;
  }

  // 초대 코드로 스터디 참가
  Future<StudyGroupModel?> joinStudyByInviteCode({
    required String inviteCode,
    required String userId,
    required String nickname,
  }) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw '유효하지 않은 초대 코드입니다.';
    }

    final doc = querySnapshot.docs.first;
    final studyGroup = StudyGroupModel.fromFirestore(doc);

    if (studyGroup.memberIds.contains(userId)) {
      throw '이미 참여 중인 모임입니다.';
    }

    // 스터디 그룹에 멤버 및 닉네임 추가
    await doc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberNicknames.$userId': nickname,
    });

    // 사용자의 studyGroupIds에 추가
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'studyGroupIds': FieldValue.arrayUnion([doc.id]),
    });

    return studyGroup.copyWith(
      memberIds: [...studyGroup.memberIds, userId],
      memberNicknames: {...studyGroup.memberNicknames, userId: nickname},
    );
  }

  // 닉네임 업데이트
  Future<void> updateNickname({
    required String studyGroupId,
    required String userId,
    required String nickname,
  }) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'memberNicknames.$userId': nickname,
    });
  }

  // 관리자 추가
  Future<void> addAdmin({
    required String studyGroupId,
    required String userId,
  }) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'adminIds': FieldValue.arrayUnion([userId]),
    });
  }

  // 관리자 제거
  Future<void> removeAdmin({
    required String studyGroupId,
    required String userId,
  }) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'adminIds': FieldValue.arrayRemove([userId]),
    });
  }

  // 사용자의 스터디 그룹 목록 가져오기
  Stream<List<StudyGroupModel>> getUserStudyGroups(String userId) {
    return _firestore
        .collection(AppConstants.studyGroupsCollection)
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyGroupModel.fromFirestore(doc))
            .toList());
  }

  // 스터디 그룹 상세 정보 가져오기
  Future<StudyGroupModel?> getStudyGroup(String studyGroupId) async {
    final doc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (doc.exists) {
      return StudyGroupModel.fromFirestore(doc);
    }
    return null;
  }

  // 스터디 그룹 스트림
  Stream<StudyGroupModel?> getStudyGroupStream(String studyGroupId) {
    return _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .snapshots()
        .map((doc) => doc.exists ? StudyGroupModel.fromFirestore(doc) : null);
  }

  // 스터디 그룹 멤버 정보 가져오기
  Future<List<UserModel>> getStudyGroupMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];

    final List<UserModel> members = [];
    for (final memberId in memberIds) {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(memberId)
          .get();
      if (doc.exists) {
        members.add(UserModel.fromFirestore(doc));
      }
    }
    return members;
  }

  // 스터디 그룹 수정
  Future<void> updateStudyGroup(StudyGroupModel studyGroup) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroup.id)
        .update(studyGroup.toFirestore());
  }

  // 스터디 나가기
  Future<void> leaveStudyGroup({
    required String studyGroupId,
    required String userId,
  }) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'studyGroupIds': FieldValue.arrayRemove([studyGroupId]),
    });
  }

  String _generateInviteCode() {
    return _uuid.v4().substring(0, 8).toUpperCase();
  }

  // 벌금 규칙 수정 (로그 포함)
  Future<void> updatePenaltyRule({
    required String studyGroupId,
    required String modifiedBy,
    required PenaltyRule oldRule,
    required PenaltyRule newRule,
  }) async {
    final log = PenaltyRuleLog(
      modifiedBy: modifiedBy,
      modifiedAt: DateTime.now(),
      oldRule: oldRule,
      newRule: newRule,
    );

    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'penaltyRule': newRule.toMap(),
      'penaltyRuleLogs': FieldValue.arrayUnion([log.toMap()]),
    });
  }

  // 방장 위임
  Future<void> transferOwnership({
    required String studyGroupId,
    required String newOwnerId,
  }) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'ownerId': newOwnerId,
    });
  }

  // 출석 세션 시작 (방장/관리자만) - 시작한 사람 자동 출석
  Future<AttendanceSession> startAttendanceSession({
    required String studyGroupId,
    required String startedBy,
    required int durationMinutes,
    int lateThresholdSeconds = 300,
  }) async {
    // 스터디 그룹에서 지각 유예 시간 가져오기
    final studyDoc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (!studyDoc.exists) throw '모임을 찾을 수 없습니다.';

    final study = StudyGroupModel.fromFirestore(studyDoc);
    final lateGracePeriodMinutes = study.penaltyRule.lateGracePeriodMinutes;

    final now = DateTime.now();
    final session = AttendanceSession(
      sessionId: _uuid.v4(),
      startedAt: now,
      endsAt: now.add(Duration(minutes: durationMinutes)),
      verificationWord: AttendanceSession.generateVerificationWord(),
      lateThresholdSeconds: lateThresholdSeconds,
      lateGracePeriodMinutes: lateGracePeriodMinutes,
      startedBy: startedBy,
      checkedInUsers: [startedBy], // 시작한 사람 자동 출석
      userStatuses: {startedBy: AttendanceStatus.present}, // 시작한 사람은 정시 출석
    );

    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'activeAttendanceSession': session.toMap(),
    });

    return session;
  }

  // 출석 시간 연장
  Future<void> extendAttendanceSession({
    required String studyGroupId,
    required int additionalMinutes,
  }) async {
    final doc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (!doc.exists) throw '모임을 찾을 수 없습니다.';

    final study = StudyGroupModel.fromFirestore(doc);
    final session = study.activeAttendanceSession;

    if (session == null) throw '진행 중인 출석이 없습니다.';

    final newEndsAt = session.endsAt.add(Duration(minutes: additionalMinutes));

    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'activeAttendanceSession.endsAt': Timestamp.fromDate(newEndsAt),
    });
  }

  // 출석 마감 - 출석 기록을 DB에 저장하고 미출석자는 결석 처리
  Future<void> finishAttendanceSession(String studyGroupId) async {
    final doc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (!doc.exists) throw '모임을 찾을 수 없습니다.';

    final study = StudyGroupModel.fromFirestore(doc);
    final session = study.activeAttendanceSession;

    if (session == null) throw '진행 중인 출석이 없습니다.';

    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    final batch = _firestore.batch();

    // 모든 멤버에 대해 출석 기록 생성
    for (final memberId in study.memberIds) {
      final isCheckedIn = session.checkedInUsers.contains(memberId);
      final userStatus = session.userStatuses[memberId];

      String status;
      if (isCheckedIn) {
        status = userStatus ?? AttendanceStatus.present;
      } else {
        // 지각 유예 기간 내 체크인 가능하도록 pending 상태로 두지 않고
        // 마감 시점에서 미출석이면 일단 absent로 기록 (나중에 지각 체크인 가능)
        status = AttendanceStatus.absent;
      }

      final attendanceDocRef = _firestore.collection(AppConstants.attendancesCollection).doc();
      final attendance = AttendanceModel(
        id: attendanceDocRef.id,
        studyGroupId: studyGroupId,
        sessionId: session.sessionId,
        userId: memberId,
        status: status,
        date: dateOnly,
        checkInTime: isCheckedIn ? session.startedAt : null,
      );

      batch.set(attendanceDocRef, attendance.toFirestore());

      // 지각/결석인 경우 벌금 생성
      if (status == AttendanceStatus.late || status == AttendanceStatus.absent) {
        final penaltyDocRef = _firestore.collection(AppConstants.penaltiesCollection).doc();
        batch.set(penaltyDocRef, {
          'studyGroupId': studyGroupId,
          'userId': memberId,
          'type': status == AttendanceStatus.late ? PenaltyType.late : PenaltyType.absent,
          'amount': status == AttendanceStatus.late
              ? study.penaltyRule.latePenalty
              : study.penaltyRule.absentPenalty,
          'date': Timestamp.fromDate(dateOnly),
          'isPaid': false,
          'sessionId': session.sessionId,
        });
      }
    }

    // 세션 정보를 finishedAttendanceSession으로 이동 (지각 체크인용)
    // finishedAt을 현재 시간으로 설정하여 조기 마감 시에도 지각 유예 기간이 올바르게 계산되도록 함
    final finishedSession = {
      ...session.toMap(),
      'finishedAt': Timestamp.fromDate(now),
    };
    batch.update(doc.reference, {
      'activeAttendanceSession': FieldValue.delete(),
      'lastFinishedSession': finishedSession,
    });

    await batch.commit();
  }

  // 출석 취소 - 세션만 삭제 (출석 기록 없이)
  Future<void> cancelAttendanceSession(String studyGroupId) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'activeAttendanceSession': FieldValue.delete(),
    });
  }

  // 지각 체크인 (마감 후 지각 유예 기간 내)
  Future<void> lateCheckIn({
    required String studyGroupId,
    required String userId,
    required String word,
  }) async {
    final doc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (!doc.exists) throw '모임을 찾을 수 없습니다.';

    final data = doc.data() as Map<String, dynamic>;
    final lastSessionData = data['lastFinishedSession'];

    if (lastSessionData == null) throw '최근 마감된 출석이 없습니다.';

    final lastSession = AttendanceSession.fromMap(lastSessionData);

    // 지각 유예 기간 확인
    final now = DateTime.now();
    if (now.isAfter(lastSession.lateGracePeriodEndsAt)) {
      throw '지각 체크인 시간이 지났습니다.';
    }

    // 단어 확인
    if (word != lastSession.verificationWord) {
      throw '인증 단어가 일치하지 않습니다.';
    }

    // 해당 사용자의 출석 기록 찾기
    final attendanceQuery = await _firestore
        .collection(AppConstants.attendancesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('sessionId', isEqualTo: lastSession.sessionId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (attendanceQuery.docs.isEmpty) {
      throw '출석 기록을 찾을 수 없습니다.';
    }

    final attendanceDoc = attendanceQuery.docs.first;
    final currentStatus = attendanceDoc.data()['status'];

    if (currentStatus != AttendanceStatus.absent) {
      throw '이미 출석 처리되었습니다.';
    }

    // 결석 -> 지각으로 변경
    await attendanceDoc.reference.update({
      'status': AttendanceStatus.late,
      'checkInTime': Timestamp.fromDate(now),
    });

    // 결석 벌금 -> 지각 벌금으로 변경
    final study = StudyGroupModel.fromFirestore(doc);
    final penaltyQuery = await _firestore
        .collection(AppConstants.penaltiesCollection)
        .where('studyGroupId', isEqualTo: studyGroupId)
        .where('sessionId', isEqualTo: lastSession.sessionId)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: PenaltyType.absent)
        .limit(1)
        .get();

    if (penaltyQuery.docs.isNotEmpty) {
      await penaltyQuery.docs.first.reference.update({
        'type': PenaltyType.late,
        'amount': study.penaltyRule.latePenalty,
      });
    }
  }

  // 출석 체크 (단어 인증) - 출석 진행 중일 때
  Future<String> checkInWithWord({
    required String studyGroupId,
    required String userId,
    required String word,
  }) async {
    final doc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (!doc.exists) throw '모임을 찾을 수 없습니다.';

    final study = StudyGroupModel.fromFirestore(doc);
    final session = study.activeAttendanceSession;

    if (session == null) throw '진행 중인 출석이 없습니다.';
    if (!session.isActive) throw '출석 시간이 종료되었습니다.';
    if (session.checkedInUsers.contains(userId)) throw '이미 출석했습니다.';
    if (word != session.verificationWord) throw '인증 단어가 일치하지 않습니다.';

    // 출석 상태 결정 (지각 여부)
    final status = session.isLateNow ? AttendanceStatus.late : AttendanceStatus.present;

    // 세션에 출석 기록 저장
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'activeAttendanceSession.checkedInUsers': FieldValue.arrayUnion([userId]),
      'activeAttendanceSession.userStatuses.$userId': status,
    });

    return status;
  }
}
