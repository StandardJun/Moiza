import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moiza/models/attendance_model.dart';

class PenaltyRule {
  final int latePenalty;
  final int absentPenalty;
  final int taskNotDonePenalty;
  final int lateGracePeriodMinutes; // 출석 마감 후 지각 유예 시간 (분)

  PenaltyRule({
    this.latePenalty = 1000,
    this.absentPenalty = 3000,
    this.taskNotDonePenalty = 2000,
    this.lateGracePeriodMinutes = 10, // 기본 10분
  });

  factory PenaltyRule.fromMap(Map<String, dynamic> map) {
    return PenaltyRule(
      latePenalty: map['latePenalty'] ?? 1000,
      absentPenalty: map['absentPenalty'] ?? 3000,
      taskNotDonePenalty: map['taskNotDonePenalty'] ?? 2000,
      lateGracePeriodMinutes: map['lateGracePeriodMinutes'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latePenalty': latePenalty,
      'absentPenalty': absentPenalty,
      'taskNotDonePenalty': taskNotDonePenalty,
      'lateGracePeriodMinutes': lateGracePeriodMinutes,
    };
  }
}

// 벌금 규칙 수정 로그
class PenaltyRuleLog {
  final String modifiedBy;
  final DateTime modifiedAt;
  final PenaltyRule oldRule;
  final PenaltyRule newRule;

  PenaltyRuleLog({
    required this.modifiedBy,
    required this.modifiedAt,
    required this.oldRule,
    required this.newRule,
  });

  factory PenaltyRuleLog.fromMap(Map<String, dynamic> map) {
    return PenaltyRuleLog(
      modifiedBy: map['modifiedBy'] ?? '',
      modifiedAt: (map['modifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      oldRule: PenaltyRule.fromMap(map['oldRule'] ?? {}),
      newRule: PenaltyRule.fromMap(map['newRule'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modifiedBy': modifiedBy,
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'oldRule': oldRule.toMap(),
      'newRule': newRule.toMap(),
    };
  }
}

class StudyGroupModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final Map<String, String> memberNicknames;
  final PenaltyRule penaltyRule;
  final List<PenaltyRuleLog> penaltyRuleLogs;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime? nextMeetingAt;
  final AttendanceSession? activeAttendanceSession;
  final AttendanceSession? lastFinishedSession; // 지각 체크인용

  StudyGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    this.adminIds = const [],
    this.memberIds = const [],
    this.memberNicknames = const {},
    required this.penaltyRule,
    this.penaltyRuleLogs = const [],
    this.inviteCode,
    required this.createdAt,
    this.nextMeetingAt,
    this.activeAttendanceSession,
    this.lastFinishedSession,
  });

  factory StudyGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyGroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNicknames: Map<String, String>.from(data['memberNicknames'] ?? {}),
      penaltyRule: PenaltyRule.fromMap(data['penaltyRule'] ?? {}),
      penaltyRuleLogs: (data['penaltyRuleLogs'] as List<dynamic>?)
              ?.map((e) => PenaltyRuleLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      inviteCode: data['inviteCode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextMeetingAt: (data['nextMeetingAt'] as Timestamp?)?.toDate(),
      activeAttendanceSession: data['activeAttendanceSession'] != null
          ? AttendanceSession.fromMap(data['activeAttendanceSession'])
          : null,
      lastFinishedSession: data['lastFinishedSession'] != null
          ? AttendanceSession.fromMap(data['lastFinishedSession'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'memberNicknames': memberNicknames,
      'penaltyRule': penaltyRule.toMap(),
      'penaltyRuleLogs': penaltyRuleLogs.map((e) => e.toMap()).toList(),
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'nextMeetingAt': nextMeetingAt != null ? Timestamp.fromDate(nextMeetingAt!) : null,
      'activeAttendanceSession': activeAttendanceSession?.toMap(),
      'lastFinishedSession': lastFinishedSession?.toMap(),
    };
  }

  StudyGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<String>? adminIds,
    List<String>? memberIds,
    Map<String, String>? memberNicknames,
    PenaltyRule? penaltyRule,
    List<PenaltyRuleLog>? penaltyRuleLogs,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? nextMeetingAt,
    AttendanceSession? activeAttendanceSession,
    AttendanceSession? lastFinishedSession,
  }) {
    return StudyGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      memberNicknames: memberNicknames ?? this.memberNicknames,
      penaltyRule: penaltyRule ?? this.penaltyRule,
      penaltyRuleLogs: penaltyRuleLogs ?? this.penaltyRuleLogs,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      nextMeetingAt: nextMeetingAt ?? this.nextMeetingAt,
      activeAttendanceSession: activeAttendanceSession ?? this.activeAttendanceSession,
      lastFinishedSession: lastFinishedSession ?? this.lastFinishedSession,
    );
  }

  int get memberCount => memberIds.length;

  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || ownerId == userId;
  String? getNickname(String userId) => memberNicknames[userId];
}
