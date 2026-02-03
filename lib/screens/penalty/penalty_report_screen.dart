import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moiza/config/theme.dart';
import 'package:moiza/providers/study_provider.dart';
import 'package:moiza/providers/penalty_provider.dart';
import 'package:moiza/models/penalty_model.dart';
import 'package:moiza/services/penalty_service.dart';
import 'package:moiza/widgets/common/banner_ad_widget.dart';
import 'package:moiza/widgets/common/loading_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class PenaltyReportScreen extends StatefulWidget {
  final String studyGroupId;

  const PenaltyReportScreen({super.key, required this.studyGroupId});

  @override
  State<PenaltyReportScreen> createState() => _PenaltyReportScreenState();
}

class _PenaltyReportScreenState extends State<PenaltyReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final studyProvider = context.read<StudyProvider>();
    final penaltyProvider = context.read<PenaltyProvider>();

    penaltyProvider.loadStudyGroupPenalties(widget.studyGroupId);
    penaltyProvider.loadPenaltySummaries(
      studyGroupId: widget.studyGroupId,
      members: studyProvider.members,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('벌금 정산서'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: '정산서 공유',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '멤버별 정산 현황'),
            Tab(text: '전체 내역'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MemberSummaryTab(studyGroupId: widget.studyGroupId),
                _AllPenaltiesTab(studyGroupId: widget.studyGroupId),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  void _shareReport() {
    final penaltyProvider = context.read<PenaltyProvider>();
    final studyProvider = context.read<StudyProvider>();
    final study = studyProvider.selectedStudyGroup;

    if (study == null) return;

    final buffer = StringBuffer();
    buffer.writeln('📋 ${study.name} 벌금 정산서');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    for (final summary in penaltyProvider.penaltySummaries) {
      buffer.writeln('👤 ${summary.userName}');
      buffer.writeln('   총 벌금: ${_formatCurrency(summary.totalPenalty)}');
      buffer.writeln('   납부: ${_formatCurrency(summary.paidAmount)}');
      buffer.writeln('   미납: ${_formatCurrency(summary.unpaidAmount)}');
      buffer.writeln('');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('총 미납 금액: ${_formatCurrency(penaltyProvider.stats['unpaid'] ?? 0)}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('정산서가 클립보드에 복사되었습니다')),
    );
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }
}

class _MemberSummaryTab extends StatelessWidget {
  final String studyGroupId;

  const _MemberSummaryTab({required this.studyGroupId});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PenaltyProvider>(
      builder: (context, penaltyProvider, child) {
        if (penaltyProvider.isLoading) {
          return const LoadingWidget();
        }

        if (penaltyProvider.penaltySummaries.isEmpty) {
          return const Center(
            child: Text(
              '아직 벌금 내역이 없습니다',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: penaltyProvider.penaltySummaries.length,
          itemBuilder: (context, index) {
            final summary = penaltyProvider.penaltySummaries[index];
            return _MemberSummaryCard(summary: summary);
          },
        );
      },
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  final PenaltySummary summary;

  const _MemberSummaryCard({required this.summary});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: summary.unpaidAmount > 0
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.successColor.withOpacity(0.1),
          child: Text(
            summary.userName.isNotEmpty ? summary.userName[0].toUpperCase() : '?',
            style: TextStyle(
              color: summary.unpaidAmount > 0
                  ? AppTheme.errorColor
                  : AppTheme.successColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          summary.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '미납: ${_formatCurrency(summary.unpaidAmount)}',
          style: TextStyle(
            color: summary.unpaidAmount > 0
                ? AppTheme.errorColor
                : AppTheme.successColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow(
                  label: '총 벌금',
                  value: _formatCurrency(summary.totalPenalty),
                ),
                _SummaryRow(
                  label: '납부 완료',
                  value: _formatCurrency(summary.paidAmount),
                  valueColor: AppTheme.successColor,
                ),
                _SummaryRow(
                  label: '미납',
                  value: _formatCurrency(summary.unpaidAmount),
                  valueColor: summary.unpaidAmount > 0
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                ),
                if (summary.penalties.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    '세부 내역',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...summary.penalties.take(5).map((penalty) {
                    return _PenaltyItem(penalty: penalty);
                  }),
                  if (summary.penalties.length > 5)
                    Text(
                      '외 ${summary.penalties.length - 5}건',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyItem extends StatelessWidget {
  final PenaltyModel penalty;

  const _PenaltyItem({required this.penalty});

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: penalty.isPaid ? AppTheme.successColor : AppTheme.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${DateFormat('M/d').format(penalty.date)} ${penalty.typeDisplayName}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            _formatCurrency(penalty.amount),
            style: TextStyle(
              fontSize: 13,
              color: penalty.isPaid ? AppTheme.textSecondary : AppTheme.errorColor,
              decoration: penalty.isPaid ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllPenaltiesTab extends StatelessWidget {
  final String studyGroupId;

  const _AllPenaltiesTab({required this.studyGroupId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PenaltyProvider, StudyProvider>(
      builder: (context, penaltyProvider, studyProvider, child) {
        if (penaltyProvider.penalties.isEmpty) {
          return const Center(
            child: Text(
              '아직 벌금 내역이 없습니다',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: penaltyProvider.penalties.length,
          itemBuilder: (context, index) {
            final penalty = penaltyProvider.penalties[index];
            final member = studyProvider.members.firstWhere(
              (m) => m.id == penalty.userId,
              orElse: () => studyProvider.members.first,
            );

            return _PenaltyListItem(
              penalty: penalty,
              memberName: member.displayName,
              onMarkPaid: () {
                penaltyProvider.markAsPaid(penalty.id);
              },
            );
          },
        );
      },
    );
  }
}

class _PenaltyListItem extends StatelessWidget {
  final PenaltyModel penalty;
  final String memberName;
  final VoidCallback onMarkPaid;

  const _PenaltyListItem({
    required this.penalty,
    required this.memberName,
    required this.onMarkPaid,
  });

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: penalty.isPaid
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            penalty.isPaid ? Icons.check : Icons.warning,
            color: penalty.isPaid ? AppTheme.successColor : AppTheme.errorColor,
            size: 20,
          ),
        ),
        title: Text(
          memberName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${DateFormat('M월 d일').format(penalty.date)} · ${penalty.typeDisplayName}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCurrency(penalty.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: penalty.isPaid ? AppTheme.textSecondary : AppTheme.errorColor,
                decoration: penalty.isPaid ? TextDecoration.lineThrough : null,
              ),
            ),
            if (!penalty.isPaid) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: AppTheme.successColor,
                onPressed: onMarkPaid,
                tooltip: '납부 처리',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
