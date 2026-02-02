import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:study_penalty/config/constants.dart';
import 'package:study_penalty/models/study_group_model.dart';
import 'package:study_penalty/models/user_model.dart';
import 'package:study_penalty/models/attendance_model.dart';

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
      throw '이미 참여 중인 스터디입니다.';
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
    final now = DateTime.now();
    final session = AttendanceSession(
      sessionId: _uuid.v4(),
      startedAt: now,
      endsAt: now.add(Duration(minutes: durationMinutes)),
      verificationWord: AttendanceSession.generateVerificationWord(),
      lateThresholdSeconds: lateThresholdSeconds,
      startedBy: startedBy,
      checkedInUsers: [startedBy], // 시작한 사람 자동 출석
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

    if (!doc.exists) throw '스터디를 찾을 수 없습니다.';

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

  // 출석 세션 종료
  Future<void> endAttendanceSession(String studyGroupId) async {
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'activeAttendanceSession': FieldValue.delete(),
    });
  }

  // 출석 체크 (단어 인증)
  Future<String> checkInWithWord({
    required String studyGroupId,
    required String userId,
    required String word,
  }) async {
    final doc = await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .get();

    if (!doc.exists) throw '스터디를 찾을 수 없습니다.';

    final study = StudyGroupModel.fromFirestore(doc);
    final session = study.activeAttendanceSession;

    if (session == null) throw '진행 중인 출석이 없습니다.';
    if (!session.isActive) throw '출석 시간이 종료되었습니다.';
    if (session.checkedInUsers.contains(userId)) throw '이미 출석했습니다.';
    if (word != session.verificationWord) throw '인증 단어가 일치하지 않습니다.';

    // 출석 상태 결정 (지각 여부)
    final status = session.isLateNow ? AttendanceStatus.late : AttendanceStatus.present;

    // 출석 기록 저장
    await _firestore
        .collection(AppConstants.studyGroupsCollection)
        .doc(studyGroupId)
        .update({
      'activeAttendanceSession.checkedInUsers': FieldValue.arrayUnion([userId]),
    });

    return status;
  }
}
