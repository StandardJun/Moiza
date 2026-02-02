import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:study_penalty/config/routes.dart';
import 'package:study_penalty/config/theme.dart';
import 'package:study_penalty/models/study_group_model.dart';
import 'package:study_penalty/providers/auth_provider.dart';
import 'package:study_penalty/providers/study_provider.dart';
import 'package:study_penalty/widgets/common/banner_ad_widget.dart';
import 'package:study_penalty/widgets/common/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final studyProvider = context.read<StudyProvider>();
      if (authProvider.user != null) {
        studyProvider.loadUserStudyGroups(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 스터디'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<StudyProvider>(
              builder: (context, studyProvider, child) {
                if (studyProvider.studyGroups.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: studyProvider.studyGroups.length,
                  itemBuilder: (context, index) {
                    final study = studyProvider.studyGroups[index];
                    return _StudyCard(study: study);
                  },
                );
              },
            ),
          ),
          // 하단 배너 광고
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () => context.push(AppRoutes.joinStudy),
            backgroundColor: AppTheme.secondaryColor,
            child: const Icon(Icons.group_add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => context.push(AppRoutes.createStudy),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '참여 중인 스터디가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 스터디를 만들거나 초대 코드로 참여하세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  final StudyGroupModel study;

  const _StudyCard({required this.study});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/study/${study.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          study.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '멤버 ${study.memberCount}명',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              if (study.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  study.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // 벌금 규칙 표시
              Wrap(
                spacing: 8,
                children: [
                  _PenaltyChip(
                    label: '지각',
                    amount: study.penaltyRule.latePenalty,
                  ),
                  _PenaltyChip(
                    label: '결석',
                    amount: study.penaltyRule.absentPenalty,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PenaltyChip extends StatelessWidget {
  final String label;
  final int amount;

  const _PenaltyChip({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${_formatCurrency(amount)}',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.warningColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }
}
