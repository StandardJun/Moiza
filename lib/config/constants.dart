class AppConstants {
  // App Info
  static const String appName = '스터디 벌금';
  static const String appVersion = '1.0.0';

  // AdMob IDs (Test IDs - 배포 시 실제 ID로 교체 필요)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String studyGroupsCollection = 'study_groups';
  static const String attendancesCollection = 'attendances';
  static const String penaltiesCollection = 'penalties';

  // Default Penalty Rules
  static const int defaultLatePenalty = 1000; // 지각 벌금
  static const int defaultAbsentPenalty = 3000; // 결석 벌금
  static const int defaultTaskPenalty = 2000; // 과제 미제출 벌금
}

class PenaltyType {
  static const String late = 'late';
  static const String absent = 'absent';
  static const String taskNotDone = 'task_not_done';
}

class AttendanceStatus {
  static const String present = 'present';
  static const String late = 'late';
  static const String absent = 'absent';
}
