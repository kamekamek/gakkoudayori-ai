import 'package:flutter/material.dart';

/// ADKマルチエージェント進捗ダッシュボード
/// 
/// 7つの専門エージェント + 1つのコーディネーターエージェントの
/// 処理状況をリアルタイムで表示するWidget
class ADKAgentDashboard extends StatefulWidget {
  final List<AgentStatus> agentStatuses;
  final NewsletterStyle selectedStyle; // スタイル選択対応
  final Function(String agentId)? onAgentTap;
  final bool isCompact;

  const ADKAgentDashboard({
    Key? key,
    required this.agentStatuses,
    required this.selectedStyle,
    this.onAgentTap,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<ADKAgentDashboard> createState() => _ADKAgentDashboardState();
}

class _ADKAgentDashboardState extends State<ADKAgentDashboard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildFullView() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildProgressOverview(),
            const SizedBox(height: 16),
            Expanded(child: _buildAgentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    final completedCount = widget.agentStatuses
        .where((status) => status.status == AgentStatusType.completed)
        .length;
    final totalCount = widget.agentStatuses.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'エージェント: $completedCount/$totalCount',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            height: 4,
            child: LinearProgressIndicator(
              value: completedCount / totalCount,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.psychology,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '🎯 学級通信生成プロセス',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStyleIndicator(),
                ],
              ),
              Text(
                'ADKマルチエージェントシステム',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStyleIndicator() {
    final isClassic = widget.selectedStyle == NewsletterStyle.classic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isClassic ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClassic ? Colors.blue.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClassic ? Icons.article : Icons.auto_awesome,
            size: 14,
            color: isClassic ? Colors.blue.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isClassic ? 'クラシック' : 'モダン',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isClassic ? Colors.blue.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final hasProcessing = widget.agentStatuses
        .any((status) => status.status == AgentStatusType.processing);
    
    if (hasProcessing) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      );
    }
    
    final allCompleted = widget.agentStatuses
        .every((status) => status.status == AgentStatusType.completed);
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: allCompleted ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildProgressOverview() {
    final completedCount = widget.agentStatuses
        .where((status) => status.status == AgentStatusType.completed)
        .length;
    final processingCount = widget.agentStatuses
        .where((status) => status.status == AgentStatusType.processing)
        .length;
    final totalCount = widget.agentStatuses.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '進捗状況',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: completedCount / totalCount,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount/$totalCount 完了',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (processingCount > 0)
            Row(
              children: [
                Icon(
                  Icons.autorenew,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '$processingCount 処理中',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAgentList() {
    return ListView.separated(
      itemCount: widget.agentStatuses.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final status = widget.agentStatuses[index];
        return _buildAgentTile(status);
      },
    );
  }

  Widget _buildAgentTile(AgentStatus status) {
    return InkWell(
      onTap: widget.onAgentTap != null
          ? () => widget.onAgentTap!(status.id)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            _buildAgentIcon(status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '[${status.order}] ${status.icon} ${status.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildStatusChip(status.status),
                    ],
                  ),
                  if (status.message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      status.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (status.progress > 0 && status.progress < 1) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: status.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(status.color),
                    ),
                  ],
                ],
              ),
            ),
            if (status.status == AgentStatusType.processing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(status.color),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentIcon(AgentStatus status) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          status.icon,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AgentStatusType status) {
    Color color;
    String text;
    IconData? icon;

    switch (status) {
      case AgentStatusType.waiting:
        color = Colors.grey;
        text = '待機中';
        icon = Icons.schedule;
        break;
      case AgentStatusType.processing:
        color = Colors.orange;
        text = '処理中';
        icon = Icons.autorenew;
        break;
      case AgentStatusType.completed:
        color = Colors.green;
        text = '完了';
        icon = Icons.check_circle;
        break;
      case AgentStatusType.error:
        color = Colors.red;
        text = 'エラー';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// エージェントの状態を表すクラス
class AgentStatus {
  final String id;
  final int order;
  final String name;
  final String icon;
  final AgentStatusType status;
  final String message;
  final double progress; // 0.0 ~ 1.0
  final Color color;
  final DateTime? startTime;
  final DateTime? endTime;

  const AgentStatus({
    required this.id,
    required this.order,
    required this.name,
    required this.icon,
    required this.status,
    this.message = '',
    this.progress = 0.0,
    required this.color,
    this.startTime,
    this.endTime,
  });

  AgentStatus copyWith({
    String? id,
    int? order,
    String? name,
    String? icon,
    AgentStatusType? status,
    String? message,
    double? progress,
    Color? color,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return AgentStatus(
      id: id ?? this.id,
      order: order ?? this.order,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      color: color ?? this.color,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Duration? get processingTime {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }
}

/// エージェントの状態タイプ
enum AgentStatusType {
  waiting,
  processing,
  completed,
  error,
}

/// ニュースレタースタイル
enum NewsletterStyle {
  classic,
  modern,
}

/// 7エージェント + コーディネーターのスタイル対応設定
class ADKAgentConfigs {
  static List<AgentStatus> get defaultAgents => getAgentsForStyle(NewsletterStyle.classic);
  
  static List<AgentStatus> getAgentsForStyle(NewsletterStyle style) {
    final isClassic = style == NewsletterStyle.classic;
    final baseColor = isClassic ? const Color(0xFF1976D2) : const Color(0xFFFF9800);
    final secondaryColor = isClassic ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50);
    
    return [
      AgentStatus(
        id: 'content_writer',
        order: 1,
        name: '文章生成エージェント',
        icon: '📝',
        status: AgentStatusType.waiting,
        message: isClassic ? 'CLASSIC_TENSAKU.md 使用' : 'MODERN_TENSAKU.md 使用',
        color: secondaryColor,
      ),
      AgentStatus(
        id: 'design_specialist',
        order: 2,
        name: 'デザイン仕様エージェント',
        icon: '🎨',
        status: AgentStatusType.waiting,
        message: isClassic ? 'クラシック仕様でデザイン作成' : 'モダン仕様でデザイン作成',
        color: baseColor,
      ),
      AgentStatus(
        id: 'html_generator',
        order: 3,
        name: 'HTML生成エージェント',
        icon: '🏗️',
        status: AgentStatusType.waiting,
        message: isClassic ? 'CLASSIC_LAYOUT.md で実行予定' : 'MODERN_LAYOUT.md で実行予定',
        color: const Color(0xFFFF9800),
      ),
      AgentStatus(
        id: 'pdf_generator',
        order: 4,
        name: 'PDF変換エージェント',
        icon: '📄',
        status: AgentStatusType.waiting,
        message: isClassic ? 'クラシックスタイル継承' : 'モダンスタイル継承',
        color: const Color(0xFF9C27B0),
      ),
      AgentStatus(
        id: 'media_specialist',
        order: 5,
        name: '画像・メディアエージェント',
        icon: '🖼️',
        status: AgentStatusType.waiting,
        message: isClassic ? '落ち着いたトーンで画像生成' : '鮮やかなトーンで画像生成',
        color: const Color(0xFFF44336),
      ),
      AgentStatus(
        id: 'classroom_publisher',
        order: 6,
        name: '配信準備エージェント',
        icon: '📤',
        status: AgentStatusType.waiting,
        message: 'スタイル統一で配信準備',
        color: const Color(0xFF00BCD4),
      ),
      AgentStatus(
        id: 'quality_assurance',
        order: 7,
        name: '品質保証エージェント',
        icon: '✅',
        status: AgentStatusType.waiting,
        message: isClassic ? '読みやすさ重視でチェック' : '視覚的美しさ重視でチェック',
        color: secondaryColor,
      ),
    ];
  }
  
  /// スタイル別のテーマカラー
  static Color getPrimaryColor(NewsletterStyle style) {
    return style == NewsletterStyle.classic 
        ? const Color(0xFF1976D2)  // 深青
        : const Color(0xFFFF9800); // 鮮橙
  }
  
  static Color getSecondaryColor(NewsletterStyle style) {
    return style == NewsletterStyle.classic
        ? const Color(0xFF2E7D32)  // 深緑  
        : const Color(0xFF4CAF50); // 鮮緑
  }
}