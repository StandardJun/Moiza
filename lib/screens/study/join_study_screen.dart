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
  final _codeFocus = FocusNode();
  final _nicknameFocus = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    _codeFocus.dispose();
    _nicknameFocus.dispose();
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
          content: Text('모임에 참여했습니다!'),
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
        title: const Text('모임 참여'),
      ),
      body: Consumer<StudyProvider>(
        builder: (context, studyProvider, child) {
          return LoadingOverlay(
            isLoading: studyProvider.isLoading,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.group_add_outlined,
                            size: 36,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          '초대 코드 입력',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '모임 관리자에게 받은 초대 코드를 입력하세요',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 40),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(color: AppTheme.borderColor),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Invite Code
                              TextFormField(
                                controller: _codeController,
                                focusNode: _codeFocus,
                                textAlign: TextAlign.center,
                                textCapitalization: TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _nicknameFocus.requestFocus(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'XXXXXXXX',
                                  hintStyle: TextStyle(
                                    letterSpacing: 4,
                                    color: AppTheme.textTertiary,
                                    fontWeight: FontWeight.w400,
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
                              const SizedBox(height: 20),

                              // Nickname
                              TextFormField(
                                controller: _nicknameController,
                                focusNode: _nicknameFocus,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleJoin(),
                                decoration: const InputDecoration(
                                  labelText: '닉네임',
                                  hintText: '모임에서 사용할 닉네임',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '닉네임을 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Join Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _handleJoin,
                                  child: const Text('참여하기'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
