import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moiza/config/constants.dart';

// 출석 세션 모델 (방장/관리자가 시작하는 출석 체크)
class AttendanceSession {
  final String sessionId;
  final DateTime startedAt;
  final DateTime endsAt;
  final DateTime? finishedAt; // 실제 마감 시간 (조기 마감 시 사용)
  final String verificationWord;
  final int lateThresholdSeconds; // 정시 출석 임계 (초)
  final int lateGracePeriodMinutes; // 출석 마감 후 지각 허용 시간 (분)
  final String startedBy;
  final List<String> checkedInUsers;
  final Map<String, String> userStatuses; // userId -> status (present/late)

  AttendanceSession({
    required this.sessionId,
    required this.startedAt,
    required this.endsAt,
    this.finishedAt,
    required this.verificationWord,
    this.lateThresholdSeconds = 300, // 기본 5분
    this.lateGracePeriodMinutes = 10, // 기본 10분 지각 유예
    required this.startedBy,
    this.checkedInUsers = const [],
    this.userStatuses = const {},
  });

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      sessionId: map['sessionId'] ?? '',
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (map['endsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      finishedAt: (map['finishedAt'] as Timestamp?)?.toDate(),
      verificationWord: map['verificationWord'] ?? '',
      lateThresholdSeconds: map['lateThresholdSeconds'] ?? 300,
      lateGracePeriodMinutes: map['lateGracePeriodMinutes'] ?? 10,
      startedBy: map['startedBy'] ?? '',
      checkedInUsers: List<String>.from(map['checkedInUsers'] ?? []),
      userStatuses: Map<String, String>.from(map['userStatuses'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'startedAt': Timestamp.fromDate(startedAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'finishedAt': finishedAt != null ? Timestamp.fromDate(finishedAt!) : null,
      'verificationWord': verificationWord,
      'lateThresholdSeconds': lateThresholdSeconds,
      'lateGracePeriodMinutes': lateGracePeriodMinutes,
      'startedBy': startedBy,
      'checkedInUsers': checkedInUsers,
      'userStatuses': userStatuses,
    };
  }

  bool get isActive => DateTime.now().isBefore(endsAt);
  bool get isLateNow => DateTime.now().isAfter(startedAt.add(Duration(seconds: lateThresholdSeconds)));

  // 실제 마감 시간 (finishedAt이 있으면 사용, 없으면 endsAt 사용)
  DateTime get effectiveEndTime => finishedAt ?? endsAt;

  // 지각 유예 기간 내인지 확인 (마감 후 ~ 마감 + 지각유예시간)
  bool get isInLateGracePeriod {
    final now = DateTime.now();
    final gracePeriodEnd = effectiveEndTime.add(Duration(minutes: lateGracePeriodMinutes));
    return now.isAfter(effectiveEndTime) && now.isBefore(gracePeriodEnd);
  }

  // 지각 유예 기간 종료 시간
  DateTime get lateGracePeriodEndsAt => effectiveEndTime.add(Duration(minutes: lateGracePeriodMinutes));

  // 랜덤 한글 단어 생성 (3-4글자)
  static String generateVerificationWord() {
    final words = [
      '사과', '바나나', '포도', '딸기', '수박', '참외',
      '호랑이', '사자', '코끼리', '기린', '원숭이',
      '바다', '산', '강', '하늘', '구름', '별',
      '커피', '녹차', '우유', '주스', '콜라',
      '피자', '치킨', '햄버거', '파스타', '라면',
      '축구', '야구', '농구', '배구', '테니스',
      '음악', '영화', '책', '게임', '여행',
      '봄', '여름', '가을', '겨울',
      '행복', '사랑', '희망', '꿈', '미래',
      '태양', '달빛', '무지개', '눈꽃', '벚꽃',
    ];
    final random = Random();
    return words[random.nextInt(words.length)];
  }
}

class AttendanceModel {
  final String id;
  final String studyGroupId;
  final String sessionId; // 출석 세션 ID
  final String userId;
  final String status; // present, late, absent
  final DateTime date;
  final DateTime? checkInTime;
  final String? note;

  AttendanceModel({
    required this.id,
    required this.studyGroupId,
    this.sessionId = '',
    required this.userId,
    required this.status,
    required this.date,
    this.checkInTime,
    this.note,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studyGroupId: data['studyGroupId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      userId: data['userId'] ?? '',
      status: data['status'] ?? AttendanceStatus.absent,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studyGroupId': studyGroupId,
      'sessionId': sessionId,
      'userId': userId,
      'status': status,
      'date': Timestamp.fromDate(date),
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'note': note,
    };
  }

  bool get isPresent => status == AttendanceStatus.present;
  bool get isLate => status == AttendanceStatus.late;
  bool get isAbsent => status == AttendanceStatus.absent;
}
