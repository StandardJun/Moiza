import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:moiza/config/theme.dart';
import 'package:moiza/models/study_group_model.dart';
import 'package:moiza/providers/auth_provider.dart';
import 'package:moiza/providers/study_provider.dart';
import 'package:moiza/providers/penalty_provider.dart';
import 'package:moiza/widgets/common/loading_widget.dart';
import 'package:intl/intl.dart';

class StudyDetailScreen extends StatefulWidget {
  final String studyGroupId;

  const StudyDetailScreen({super.key, required this.studyGroupId});

  @override
  State<StudyDetailScreen> createState() => _StudyDetailScreenState();
}

class _StudyDetailScreenState extends State<StudyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyProvider>().selectStudyGroup(widget.studyGroupId);
      context.read<PenaltyProvider>().loadStudyGroupPenalties(widget.studyGroupId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<StudyProvider>(
          builder: (context, provider, _) {
            return Text(provider.selectedStudyGroup?.name ?? '모임');
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'invite') {
                _showInviteCode();
              } else if (value == 'nickname') {
                _showEditNickname();
              } else if (value == 'leave') {
                _showLeaveConfirm();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'invite',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('초대 코드'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'nickname',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('닉네임 수정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 20, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('나가기', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<StudyProvider, PenaltyProvider>(
        builder: (context, studyProvider, penaltyProvider, child) {
          final study = studyProvider.selectedStudyGroup;

          if (study == null) {
            return const LoadingWidget();
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 벌금 현황 카드
                      _StatsCard(stats: penaltyProvider.stats),
                      const SizedBox(height: 16),

                      // 메뉴 버튼들
                      Row(
                        children: [
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.check_circle,
                              label: '출석 체크',
                              color: AppTheme.successColor,
                              onTap: () => context.push('/study/${study.id}/attendance'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.receipt_long,
                              label: '정산서',
                              color: AppTheme.warningColor,
                              onTap: () => context.push('/study/${study.id}/penalty-report'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 멤버 목록
                      const Text(
                        '멤버',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...studyProvider.members.map((member) {
                        final isOwner = member.id == study.ownerId;
                        final isAdmin = study.adminIds.contains(member.id);
                        final nickname = study.getNickname(member.id) ?? member.displayName;
                        final currentUserId = context.read<AuthProvider>().user?.id;
                        final amIOwner = study.isOwner(currentUserId ?? '');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: amIOwner && member.id != currentUserId
                                ? () => _showMemberActions(member, study)
                                : null,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(
                                nickname.isNotEmpty
                                    ? nickname[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(member.displayName),
                            subtitle: Text(
                              nickname,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOwner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '방장',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '관리자',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),

                      // 벌금 규칙
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '벌금 규칙',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              // 수정 내역은 모든 멤버가 볼 수 있음
                              if (study.penaltyRuleLogs.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.history, size: 20),
                                  onPressed: () => _showPenaltyRuleLogs(study),
                                  tooltip: '수정 내역',
                                ),
                              // 규칙 수정은 관리자/방장만 가능
                              if (study.isAdmin(context.read<AuthProvider>().user?.id ?? ''))
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showEditPenaltyRule(study),
                                  tooltip: '규칙 수정',
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _RuleItem(
                                icon: Icons.schedule,
                                label: '지각',
                                amount: study.penaltyRule.latePenalty,
                              ),
                              const Divider(),
                              _RuleItem(
                                icon: Icons.event_busy,
                                label: '결석',
                                amount: study.penaltyRule.absentPenalty,
                              ),
                              if (study.penaltyRule.taskNotDonePenalty > 0) ...[
                                const Divider(),
                                _RuleItem(
                                  icon: Icons.assignment_late,
                                  label: '과제 미제출',
                                  amount: study.penaltyRule.taskNotDonePenalty,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInviteCode() {
    final study = context.read<StudyProvider>().selectedStudyGroup;
    if (study?.inviteCode == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 코드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이 코드를 공유하여 멤버를 초대하세요'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    study!.inviteCode!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.primaryColor),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: study.inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대 코드가 복사되었습니다')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showEditNickname() {
    final study = context.read<StudyProvider>().selectedStudyGroup;
    final authProvider = context.read<AuthProvider>();
    if (study == null || authProvider.user == null) return;

    final currentNickname = study.getNickname(authProvider.user!.id) ?? '';
    final controller = TextEditingController(text: currentNickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('닉네임 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '닉네임',
            hintText: '모임에서 사용할 닉네임',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final newNickname = controller.text.trim();
              if (newNickname.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('닉네임을 입력해주세요'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final studyProvider = context.read<StudyProvider>();
              final success = await studyProvider.updateNickname(
                studyGroupId: study.id,
                userId: authProvider.user!.id,
                nickname: newNickname,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('닉네임이 변경되었습니다'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모임 나가기'),
        content: const Text('정말 이 모임을 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              final studyProvider = context.read<StudyProvider>();

              await studyProvider.leaveStudyGroup(
                studyGroupId: widget.studyGroupId,
                userId: authProvider.user!.id,
              );

              if (mounted) {
                context.pop();
              }
            },
            child: const Text(
              '나가기',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberActions(dynamic member, dynamic study) {
    final isAdmin = study.adminIds.contains(member.id);
    final nickname = study.getNickname(member.id) ?? member.displayName;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                nickname,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                isAdmin ? Icons.remove_moderator : Icons.add_moderator,
                color: isAdmin ? AppTheme.errorColor : AppTheme.successColor,
              ),
              title: Text(isAdmin ? '관리자 해제' : '관리자 지정'),
              onTap: () async {
                Navigator.pop(context);
                final studyProvider = context.read<StudyProvider>();
                if (isAdmin) {
                  await studyProvider.removeAdmin(
                    studyGroupId: study.id,
                    userId: member.id,
                  );
                } else {
                  await studyProvider.addAdmin(
                    studyGroupId: study.id,
                    userId: member.id,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppTheme.warningColor),
              title: const Text('방장 위임'),
              onTap: () => _confirmTransferOwnership(member, study),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTransferOwnership(dynamic member, dynamic study) {
    Navigator.pop(context);
    final nickname = study.getNickname(member.id) ?? member.displayName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('방장 위임'),
        content: Text('$nickname님에게 방장을 위임하시겠습니까?\n\n방장 권한이 이전됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final studyProvider = context.read<StudyProvider>();
              final success = await studyProvider.transferOwnership(
                studyGroupId: study.id,
                newOwnerId: member.id,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('방장이 위임되었습니다'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('위임'),
          ),
        ],
      ),
    );
  }

  void _showEditPenaltyRule(dynamic study) {
    final lateController = TextEditingController(
      text: study.penaltyRule.latePenalty.toString(),
    );
    final absentController = TextEditingController(
      text: study.penaltyRule.absentPenalty.toString(),
    );
    final taskController = TextEditingController(
      text: study.penaltyRule.taskNotDonePenalty.toString(),
    );
    final lateGraceController = TextEditingController(
      text: study.penaltyRule.lateGracePeriodMinutes.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('벌금 규칙 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '지각 벌금 (원)',
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: absentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '결석 벌금 (원)',
                  prefixIcon: Icon(Icons.event_busy),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taskController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '과제 미제출 벌금 (원)',
                  prefixIcon: Icon(Icons.assignment_late),
                  helperText: '0 입력 시 과제 벌금 없음',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lateGraceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '지각 유예 시간 (분)',
                  prefixIcon: Icon(Icons.timer),
                  helperText: '출석 마감 후 지각 체크인 허용 시간',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              final studyProvider = context.read<StudyProvider>();

              final newRule = PenaltyRule(
                latePenalty: int.tryParse(lateController.text) ?? 1000,
                absentPenalty: int.tryParse(absentController.text) ?? 3000,
                taskNotDonePenalty: int.tryParse(taskController.text) ?? 0,
                lateGracePeriodMinutes: int.tryParse(lateGraceController.text) ?? 10,
              );

              final success = await studyProvider.updatePenaltyRule(
                studyGroupId: study.id,
                modifiedBy: authProvider.user!.id,
                oldRule: study.penaltyRule,
                newRule: newRule,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('벌금 규칙이 수정되었습니다'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showPenaltyRuleLogs(dynamic study) {
    final studyProvider = context.read<StudyProvider>();
    final members = studyProvider.members;

    String getMemberName(String id) {
      final member = members.where((m) => m.id == id).firstOrNull;
      return study.getNickname(id) ?? member?.displayName ?? '알 수 없음';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('벌금 규칙 수정 내역'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: study.penaltyRuleLogs.length,
            itemBuilder: (context, index) {
              final log = study.penaltyRuleLogs[study.penaltyRuleLogs.length - 1 - index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getMemberName(log.modifiedBy),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat('M/d HH:mm').format(log.modifiedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRuleChange('지각', log.oldRule.latePenalty, log.newRule.latePenalty),
                      _buildRuleChange('결석', log.oldRule.absentPenalty, log.newRule.absentPenalty),
                      _buildRuleChange('과제', log.oldRule.taskNotDonePenalty, log.newRule.taskNotDonePenalty),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleChange(String label, int oldValue, int newValue) {
    if (oldValue == newValue) return const SizedBox.shrink();
    final formatter = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: ${formatter.format(oldValue)}원 → ${formatter.format(newValue)}원',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsCard({required this.stats});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '벌금 현황',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: '총 벌금',
                    value: _formatCurrency(stats['total'] ?? 0),
                    color: AppTheme.textPrimary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: '납부 완료',
                    value: _formatCurrency(stats['paid'] ?? 0),
                    color: AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: '미납',
                    value: _formatCurrency(stats['unpaid'] ?? 0),
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;

  const _RuleItem({
    required this.icon,
    required this.label,
    required this.amount,
  });

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }
}
