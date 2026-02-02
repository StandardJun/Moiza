import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_penalty/config/constants.dart';

class PenaltyModel {
  final String id;
  final String studyGroupId;
  final String userId;
  final String type; // late, absent, task_not_done
  final int amount;
  final DateTime date;
  final bool isPaid;
  final String? note;

  PenaltyModel({
    required this.id,
    required this.studyGroupId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.date,
    this.isPaid = false,
    this.note,
  });

  factory PenaltyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PenaltyModel(
      id: doc.id,
      studyGroupId: data['studyGroupId'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? PenaltyType.absent,
      amount: data['amount'] ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: data['isPaid'] ?? false,
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studyGroupId': studyGroupId,
      'userId': userId,
      'type': type,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'isPaid': isPaid,
      'note': note,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case PenaltyType.late:
        return '지각';
      case PenaltyType.absent:
        return '결석';
      case PenaltyType.taskNotDone:
        return '과제 미제출';
      default:
        return '기타';
    }
  }

  PenaltyModel copyWith({
    String? id,
    String? studyGroupId,
    String? userId,
    String? type,
    int? amount,
    DateTime? date,
    bool? isPaid,
    String? note,
  }) {
    return PenaltyModel(
      id: id ?? this.id,
      studyGroupId: studyGroupId ?? this.studyGroupId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      note: note ?? this.note,
    );
  }
}
