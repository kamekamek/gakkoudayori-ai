import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ステップインジケーターウィジェット
class StepIndicatorWidget extends StatelessWidget {
  final String currentStep;
  final List<String> completedSteps;

  const StepIndicatorWidget({
    Key? key,
    required this.currentStep,
    required this.completedSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'id': 'audio_input', 'label': '音声入力', 'icon': Icons.mic},
      {'id': 'content_generation', 'label': 'コンテンツ生成', 'icon': Icons.edit},
      {'id': 'design_selection', 'label': 'デザイン選択', 'icon': Icons.palette},
      {'id': 'html_generation', 'label': 'HTML生成', 'icon': Icons.web},
      {'id': 'final_approval', 'label': '最終確認', 'icon': Icons.check_circle},
      {'id': 'complete', 'label': '完成', 'icon': Icons.done_all},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '進行状況',
            style: GoogleFonts.notoSansJp(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final stepId = step['id'] as String;
                final stepLabel = step['label'] as String;
                final stepIcon = step['icon'] as IconData;
                
                final isCompleted = completedSteps.contains(stepId);
                final isCurrent = currentStep == stepId || 
                    (currentStep == 'content_review' && stepId == 'content_generation') ||
                    (currentStep == 'html_review' && stepId == 'html_generation');
                final isUpcoming = !isCompleted && !isCurrent;

                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      // ステップアイコン
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? Colors.green[600]
                              : isCurrent 
                                  ? Colors.blue[600]
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: isCurrent ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : stepIcon,
                          color: isUpcoming ? Colors.grey[600] : Colors.white,
                          size: 20,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // ステップラベル
                      Text(
                        stepLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted 
                              ? Colors.green[600]
                              : isCurrent 
                                  ? Colors.blue[600]
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // 進行バー
          Container(
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              value: _calculateProgress(currentStep, completedSteps),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(String currentStep, List<String> completedSteps) {
    final totalSteps = 6;
    final completedCount = completedSteps.length;
    
    // 現在のステップが進行中の場合は+0.5
    double currentStepProgress = 0.0;
    if (currentStep == 'content_review' || 
        currentStep == 'design_selection' ||
        currentStep == 'html_review' ||
        currentStep == 'final_approval' ||
        currentStep == 'complete') {
      currentStepProgress = 0.5;
    }
    
    return (completedCount + currentStepProgress) / totalSteps;
  }
}