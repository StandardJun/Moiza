import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moiza/config/constants.dart';
import 'package:moiza/config/theme.dart';
import 'package:moiza/providers/auth_provider.dart';
import 'package:moiza/providers/attendance_provider.dart';
import 'package:moiza/providers/study_provider.dart';
import 'package:moiza/services/ad_service.dart';
import 'package:moiza/widgets/common/banner_ad_widget.dart';
import 'package:moiza/widgets/common/loading_widget.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final String studyGroupId;

  const AttendanceScreen({super.key, required this.studyGroupId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AdService _adService = AdService();
  final _wordController = TextEditingController();
  final _lateGraceController = TextEditingController();
  int _selectedDuration = 5; // 기본 5분
  bool _saveAsDefault = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final attendanceProvider = context.read<AttendanceProvider>();
      final studyProvider = context.read<StudyProvider>();

      if (authProvider.user != null) {
        attendanceProvider.loadUserAttendance(
          studyGroupId: widget.studyGroupId,
          userId: authProvider.user!.id,
        );
      }

      // 기본 지각 유예 시간 로드
      final study = studyProvider.selectedStudyGroup;
      if (study != null) {
        _lateGraceController.text = study.penaltyRule.lateGracePeriodMinutes.toString();
      }
    });

    // 1초마다 UI 갱신 (남은 시간 표시용)
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _wordController.dispose();
    _lateGraceController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _startAttendanceSession() async {
    final authProvider = context.read<AuthProvider>();
    final studyProvider = context.read<StudyProvider>();

    if (authProvider.user == null) return;

    final lateGraceMinutes = int.tryParse(_lateGraceController.text) ?? 10;

    // 기본값으로 저장 옵션이 선택된 경우
    if (_saveAsDefault) {
      final study = studyProvider.selectedStudyGroup;
      if (study != null && study.penaltyRule.lateGracePeriodMinutes != lateGraceMinutes) {
        await studyProvider.updatePenaltyRule(
          studyGroupId: widget.studyGroupId,
          modifiedBy: authProvider.user!.id,
          oldRule: study.penaltyRule,
          newRule: study.penaltyRule.copyWith(lateGracePeriodMinutes: lateGraceMinutes),
        );
      }
    }

    final session = await studyProvider.startAttendanceSession(
      studyGroupId: widget.studyGroupId,
      startedBy: authProvider.user!.id,
      durationMinutes: _selectedDuration,
      lateGracePeriodMinutes: lateGraceMinutes,
    );

    if (session != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('출석이 시작되었습니다. 인증 단어: ${session.verificationWord}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _finishAttendanceSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출석 마감'),
        content: const Text('출석을 마감하시겠습니까?\n미출석자는 결석 처리됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('마감', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final studyProvider = context.read<StudyProvider>();
      final success = await studyProvider.finishAttendanceSession(widget.studyGroupId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출석이 마감되었습니다. 잠시 후 기록이 업데이트됩니다.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Firestore 데이터 전파를 위해 잠시 대기 후 새로고침
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          await _refreshData();
        }
      }
    }
  }

  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    if (authProvider.user != null) {
      attendanceProvider.loadUserAttendance(
        studyGroupId: widget.studyGroupId,
        userId: authProvider.user!.id,
      );
    }
  }

  Future<void> _cancelAttendanceSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출석 취소'),
        content: const Text('출석을 취소하시겠습니까?\n출석 기록이 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('취소하기', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final studyProvider = context.read<StudyProvider>();
      final success = await studyProvider.cancelAttendanceSession(widget.studyGroupId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출석이 취소되었습니다.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _lateCheckIn() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 단어를 입력해주세요'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final studyProvider = context.read<StudyProvider>();

    if (authProvider.user == null) return;

    final success = await studyProvider.lateCheckIn(
      studyGroupId: widget.studyGroupId,
      userId: authProvider.user!.id,
      word: word,
    );

    if (success && mounted) {
      _wordController.clear();
      _adService.showInterstitialAd(
        onAdClosed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('지각 처리되었습니다'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          // 출석 기록 새로고침
          context.read<AttendanceProvider>().loadUserAttendance(
            studyGroupId: widget.studyGroupId,
            userId: authProvider.user!.id,
          );
        },
      );
    } else if (studyProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(studyProvider.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      studyProvider.clearError();
    }
  }

  void _showExtendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출석 시간 연장'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('연장할 시간을 선택하세요'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [3, 5, 10].map((minutes) {
                return ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final studyProvider = context.read<StudyProvider>();
                    final success = await studyProvider.extendAttendanceSession(
                      studyGroupId: widget.studyGroupId,
                      additionalMinutes: minutes,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$minutes분 연장되었습니다'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                  child: Text('+$minutes분'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkIn() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 단어를 입력해주세요'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final studyProvider = context.read<StudyProvider>();

    if (authProvider.user == null) return;

    final status = await studyProvider.checkInWithWord(
      studyGroupId: widget.studyGroupId,
      userId: authProvider.user!.id,
      word: word,
    );

    if (status != null && mounted) {
      _wordController.clear();
      // 출석 체크 후 전면 광고 표시
      _adService.showInterstitialAd(
        onAdClosed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == AttendanceStatus.present ? '출석 완료!' : '지각 처리되었습니다'),
              backgroundColor: status == AttendanceStatus.present
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
          );
        },
      );
    } else if (studyProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(studyProvider.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      studyProvider.clearError();
    }
  }

  String _formatRemainingTime(DateTime endsAt) {
    final remaining = endsAt.difference(DateTime.now());
    if (remaining.isNegative) return '종료됨';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes}분 ${seconds}초';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출석 체크'),
      ),
      body: Consumer3<AuthProvider, StudyProvider, AttendanceProvider>(
        builder: (context, authProvider, studyProvider, attendanceProvider, child) {
          final study = studyProvider.selectedStudyGroup;
          final session = study?.activeAttendanceSession;
          final userId = authProvider.user?.id;
          final isAdmin = study != null && userId != null && study.isAdmin(userId);
          final hasCheckedIn = session?.checkedInUsers.contains(userId) ?? false;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 오늘 날짜
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('yyyy년 M월 d일').format(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE', 'ko_KR').format(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 출석 세션 상태에 따른 UI
                      Builder(
                        builder: (context) {
                          if (session != null && session.isActive) {
                            // 활성 세션이 있을 때
                            final isSessionStarter = session.startedBy == userId;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ActiveSessionCard(
                                  session: session,
                                  isSessionStarter: isSessionStarter,
                                  hasCheckedIn: hasCheckedIn,
                                  formatRemainingTime: _formatRemainingTime,
                                  onFinishSession: _finishAttendanceSession,
                                  onCancelSession: _cancelAttendanceSession,
                                  onExtendSession: _showExtendDialog,
                                ),
                                const SizedBox(height: 16),
                                if (hasCheckedIn)
                                  _CheckedInCard()
                                else
                                  _CheckInCard(
                                    controller: _wordController,
                                    isLoading: studyProvider.isLoading,
                                    onCheckIn: _checkIn,
                                  ),
                              ],
                            );
                          } else {
                            // 지각 유예 기간 체크
                            final lastSession = study?.lastFinishedSession;
                            final isInLateGracePeriod = lastSession != null && lastSession.isInLateGracePeriod;
                            final alreadyCheckedIn = lastSession?.checkedInUsers.contains(userId) ?? false;

                            if (isInLateGracePeriod && !alreadyCheckedIn) {
                              // 지각 유예 기간 내 - 지각 체크인 가능
                              return _LateCheckInCard(
                                lastSession: lastSession!,
                                controller: _wordController,
                                isLoading: studyProvider.isLoading,
                                onLateCheckIn: _lateCheckIn,
                                formatRemainingTime: _formatRemainingTime,
                              );
                            } else if (isAdmin) {
                              // 관리자: 출석 시작 UI
                              return _StartSessionCard(
                                selectedDuration: _selectedDuration,
                                onDurationChanged: (value) {
                                  setState(() => _selectedDuration = value);
                                },
                                lateGraceController: _lateGraceController,
                                saveAsDefault: _saveAsDefault,
                                onSaveAsDefaultChanged: (value) {
                                  setState(() => _saveAsDefault = value);
                                },
                                isLoading: studyProvider.isLoading,
                                onStart: _startAttendanceSession,
                              );
                            } else {
                              // 일반 멤버: 세션 없음
                              return _NoSessionCard();
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // 출석 기록
                      const Text(
                        '내 출석 기록',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (attendanceProvider.attendances.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              '아직 출석 기록이 없습니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...attendanceProvider.attendances.map((attendance) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _StatusIcon(status: attendance.status),
                              title: Text(
                                DateFormat('M월 d일 (E)', 'ko_KR').format(attendance.date),
                              ),
                              subtitle: attendance.checkInTime != null
                                  ? Text(
                                      DateFormat('HH:mm').format(attendance.checkInTime!),
                                    )
                                  : null,
                              trailing: _StatusBadge(status: attendance.status),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                ),
              ),
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final dynamic session;
  final bool isSessionStarter; // 출석 시작한 사람인지
  final bool hasCheckedIn;
  final String Function(DateTime) formatRemainingTime;
  final VoidCallback onFinishSession;
  final VoidCallback onCancelSession;
  final VoidCallback onExtendSession;

  const _ActiveSessionCard({
    required this.session,
    required this.isSessionStarter,
    required this.hasCheckedIn,
    required this.formatRemainingTime,
    required this.onFinishSession,
    required this.onCancelSession,
    required this.onExtendSession,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '출석 진행 중',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '남은 시간: ${formatRemainingTime(session.endsAt)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '출석 인원: ${session.checkedInUsers.length}명',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            // 출석 시작한 사람만 인증 단어를 볼 수 있음
            if (isSessionStarter) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '인증 단어 (시작자만 볼 수 있음)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.verificationWord,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 시간 연장 버튼
              OutlinedButton.icon(
                onPressed: onExtendSession,
                icon: const Icon(Icons.add_alarm),
                label: const Text('시간 연장'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              // 출석 마감 / 취소 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onFinishSession,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.successColor,
                        side: const BorderSide(color: AppTheme.successColor),
                      ),
                      child: const Text('출석 마감'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancelSession,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      child: const Text('출석 취소'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCheckIn;

  const _CheckInCard({
    required this.controller,
    required this.isLoading,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '인증 단어를 입력하세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: '단어 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onCheckIn,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '출석 체크',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartSessionCard extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onDurationChanged;
  final TextEditingController lateGraceController;
  final bool saveAsDefault;
  final ValueChanged<bool> onSaveAsDefaultChanged;
  final bool isLoading;
  final VoidCallback onStart;

  const _StartSessionCard({
    required this.selectedDuration,
    required this.onDurationChanged,
    required this.lateGraceController,
    required this.saveAsDefault,
    required this.onSaveAsDefaultChanged,
    required this.isLoading,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.timer,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              '출석을 시작하세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '랜덤 인증 단어가 생성됩니다',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '출석 시간',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 3, label: Text('3분')),
                ButtonSegment(value: 5, label: Text('5분')),
                ButtonSegment(value: 10, label: Text('10분')),
                ButtonSegment(value: 15, label: Text('15분')),
              ],
              selected: {selectedDuration},
              onSelectionChanged: (selected) {
                onDurationChanged(selected.first);
              },
            ),
            const SizedBox(height: 20),
            // 지각 인정 시간 설정
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: lateGraceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '지각 인정 시간',
                      suffixText: '분',
                      helperText: '출석 마감 후 지각 체크인 허용 시간',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 기본값 저장 체크박스
            Row(
              children: [
                Checkbox(
                  value: saveAsDefault,
                  onChanged: (value) => onSaveAsDefaultChanged(value ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const Text(
                  '이 시간을 기본으로 사용',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onStart,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '출석 시작',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '진행 중인 출석이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '방장 또는 관리자가 출석을 시작하면\n여기서 출석 체크를 할 수 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LateCheckInCard extends StatelessWidget {
  final dynamic lastSession;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onLateCheckIn;
  final String Function(DateTime) formatRemainingTime;

  const _LateCheckInCard({
    required this.lastSession,
    required this.controller,
    required this.isLoading,
    required this.onLateCheckIn,
    required this.formatRemainingTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: AppTheme.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '지각 체크인 가능',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '남은 시간: ${formatRemainingTime(lastSession.lateGracePeriodEndsAt)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '출석 마감 후 지각 유예 시간입니다.\n인증 단어를 입력하면 지각 처리됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: '인증 단어 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLateCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '지각 체크인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckedInCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: AppTheme.successColor,
            ),
            SizedBox(height: 16),
            Text(
              '출석 완료!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case AttendanceStatus.present:
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
      case AttendanceStatus.late:
        icon = Icons.schedule;
        color = AppTheme.warningColor;
        break;
      case AttendanceStatus.absent:
        icon = Icons.cancel;
        color = AppTheme.errorColor;
        break;
      default:
        icon = Icons.help;
        color = AppTheme.textSecondary;
    }

    return Icon(icon, color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case AttendanceStatus.present:
        label = '출석';
        color = AppTheme.successColor;
        break;
      case AttendanceStatus.late:
        label = '지각';
        color = AppTheme.warningColor;
        break;
      case AttendanceStatus.absent:
        label = '결석';
        color = AppTheme.errorColor;
        break;
      default:
        label = '알 수 없음';
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
