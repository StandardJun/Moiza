import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:moiza/config/theme.dart';
import 'package:moiza/providers/auth_provider.dart';
import 'package:moiza/providers/study_provider.dart';
import 'package:moiza/widgets/common/loading_widget.dart';

class JoinStudyScreen extends StatefulWidget {
  const JoinStudyScreen({super.key});

  @override
  State<JoinStudyScreen> createState() => _JoinStudyScreenState();
}

class _JoinStudyScreenState extends State<JoinStudyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final studyProvider = context.read<StudyProvider>();

    if (authProvider.user == null) return;

    final success = await studyProvider.joinStudyByInviteCode(
      inviteCode: _codeController.text.trim().toUpperCase(),
      userId: authProvider.user!.id,
      nickname: _nicknameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('스터디에 참여했습니다!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스터디 참여'),
      ),
      body: Consumer<StudyProvider>(
        builder: (context, studyProvider, child) {
          return LoadingOverlay(
            isLoading: studyProvider.isLoading,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.group_add,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '초대 코드 입력',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '스터디 관리자에게 받은 초대 코드를 입력하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'XXXXXXXX',
                        hintStyle: TextStyle(
                          letterSpacing: 4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '초대 코드를 입력해주세요';
                        }
                        if (value.length < 8) {
                          return '올바른 초대 코드를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nicknameController,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        hintText: '스터디에서 사용할 닉네임',
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
                    ElevatedButton(
                      onPressed: _handleJoin,
                      child: const Text(
                        '참여하기',
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
