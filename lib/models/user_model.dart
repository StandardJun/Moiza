import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> studyGroupIds;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.studyGroupIds = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      studyGroupIds: List<String>.from(data['studyGroupIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'studyGroupIds': studyGroupIds,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    List<String>? studyGroupIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      studyGroupIds: studyGroupIds ?? this.studyGroupIds,
    );
  }
}
