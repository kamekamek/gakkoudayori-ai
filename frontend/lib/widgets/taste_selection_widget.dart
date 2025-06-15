import 'package:flutter/material.dart';

/// テイスト選択ウィジェット
class TasteSelectionWidget extends StatefulWidget {
  final String selectedTaste;
  final Function(String) onTasteChanged;

  const TasteSelectionWidget({
    Key? key,
    required this.selectedTaste,
    required this.onTasteChanged,
  }) : super(key: key);

  @override
  State<TasteSelectionWidget> createState() => _TasteSelectionWidgetState();
}

class _TasteSelectionWidgetState extends State<TasteSelectionWidget> {
  // 利用可能なテイスト
  final List<Map<String, dynamic>> tastes = [
    {
      'type': 'modern',
      'name': 'モダン',
      'description': '現代的でスタイリッシュ',
      'icon': Icons.smartphone,
      'color': Color(0xFF3498db),
      'sample': '🌟 今日の学級活動'
    },
    {
      'type': 'classic',
      'name': 'クラシック',
      'description': '伝統的で格式のある',
      'icon': Icons.menu_book,
      'color': Color(0xFF3949ab),
      'sample': '学級通信（正式）'
    },
    {
      'type': 'minimal',
      'name': 'ミニマル',
      'description': 'シンプルで無駄のない',
      'icon': Icons.minimize,
      'color': Color(0xFF757575),
      'sample': '学級通信'
    },
    {
      'type': 'colorful',
      'name': 'カラフル',
      'description': '明るく楽しい',
      'icon': Icons.palette,
      'color': Color(0xFFff6b6b),
      'sample': '🌈 楽しい学級通信 🎈'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(Icons.palette, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                'テイスト選択',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // テイスト選択ボタン
          ...tastes.map((taste) => _buildTasteCard(taste)).toList(),
        ],
      ),
    );
  }

  Widget _buildTasteCard(Map<String, dynamic> taste) {
    final isSelected = widget.selectedTaste == taste['type'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onTasteChanged(taste['type']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected ? taste['color'].withOpacity(0.1) : Colors.grey[50],
            border: Border.all(
              color: isSelected ? taste['color'] : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // アイコン
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: taste['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  taste['icon'],
                  color: taste['color'],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),

              // テキスト情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taste['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? taste['color'] : Colors.black87,
                      ),
                    ),
                    Text(
                      taste['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'サンプル: ${taste['sample']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // 選択インジケータ
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: taste['color'],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
