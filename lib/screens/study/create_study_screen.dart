import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:study_penalty/config/theme.dart';
import 'package:study_penalty/models/study_group_model.dart';
import 'package:study_penalty/providers/auth_provider.dart';
import 'package:study_penalty/providers/study_provider.dart';
import 'package:study_penalty/widgets/common/loading_widget.dart';

class CreateStudyScreen extends StatefulWidget {
  const CreateStudyScreen({super.key});

  @override
  State<CreateStudyScreen> createState() => _CreateStudyScreenState();
}

class _CreateStudyScreenState extends State<CreateStudyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _latePenaltyController = TextEditingController(text: '1000');
  final _absentPenaltyController = TextEditingController(text: '3000');
  final _taskPenaltyController = TextEditingController(text: '2000');
  bool _noTask = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nicknameController.dispose();
    _latePenaltyController.dispose();
    _absentPenaltyController.dispose();
    _taskPenaltyController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final studyProvider = context.read<StudyProvider>();

    if (authProvider.user == null) return;

    final penaltyRule = PenaltyRule(
      latePenalty: int.tryParse(_latePenaltyController.text) ?? 1000,
      absentPenalty: int.tryParse(_absentPenaltyController.text) ?? 3000,
      taskNotDonePenalty: _noTask ? 0 : (int.tryParse(_taskPenaltyController.text) ?? 2000),
    );

    final study = await studyProvider.createStudyGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      ownerId: authProvider.user!.id,
      ownerNickname: _nicknameController.text.trim(),
      penaltyRule: penaltyRule,
    );

    if (study != null && mounted) {
      _showInviteCodeDialog(study.inviteCode!);
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

  void _showInviteCodeDialog(String inviteCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('스터디 생성 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('아래 초대 코드를 멤버들에게 공유하세요'),
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
                    inviteCode,
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
                      Clipboard.setData(ClipboardData(text: inviteCode));
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
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 스터디 만들기'),
      ),
      body: Consumer<StudyProvider>(
        builder: (context, studyProvider, child) {
          return LoadingOverlay(
            isLoading: studyProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 스터디 이름
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '스터디 이름',
                        hintText: '예: 알고리즘 스터디',
                        prefixIcon: Icon(Icons.groups),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '스터디 이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 설명
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '설명 (선택)',
                        hintText: '스터디에 대한 간단한 설명',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 닉네임
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '내 닉네임',
                        hintText: '이 스터디에서 사용할 닉네임',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // 벌금 규칙 섹션
                    const Text(
                      '벌금 규칙',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '각 항목별 벌금 금액을 설정하세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 지각 벌금
                    _PenaltyInputField(
                      controller: _latePenaltyController,
                      label: '지각 벌금',
                      icon: Icons.schedule,
                    ),
                    const SizedBox(height: 12),

                    // 결석 벌금
                    _PenaltyInputField(
                      controller: _absentPenaltyController,
                      label: '결석 벌금',
                      icon: Icons.event_busy,
                    ),
                    const SizedBox(height: 12),

                    // 과제 미제출 벌금
                    Row(
                      children: [
                        Checkbox(
                          value: _noTask,
                          onChanged: (value) {
                            setState(() {
                              _noTask = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          '과제 없음',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    _PenaltyInputField(
                      controller: _taskPenaltyController,
                      label: '과제 미제출 벌금',
                      icon: Icons.assignment_late,
                      enabled: !_noTask,
                    ),
                    const SizedBox(height: 32),

                    // 생성 버튼
                    ElevatedButton(
                      onPressed: _handleCreate,
                      child: const Text(
                        '스터디 생성',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PenaltyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;

  const _PenaltyInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: '원',
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade200 : null,
      ),
      validator: enabled
          ? (value) {
              if (value == null || value.isEmpty) {
                return '금액을 입력해주세요';
              }
              return null;
            }
          : null,
    );
  }
}
