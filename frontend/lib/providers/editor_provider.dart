import 'package:flutter/foundation.dart';

class EditorProvider extends ChangeNotifier {
  String _htmlContent = '<p>ここに内容を入力してください...</p>';
  bool _isLoading = false;
  String? _errorMessage;

  // WebView用のHTML template
  String _htmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HTML Editor</title>
    <style>
        body {
            font-family: 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
            margin: 20px;
            line-height: 1.6;
        }
        .editor {
            min-height: 400px;
            border: 1px solid #ddd;
            padding: 15px;
            border-radius: 8px;
            outline: none;
        }
        .toolbar {
            margin-bottom: 10px;
            padding: 10px;
            background: #f5f5f5;
            border-radius: 5px;
        }
        .toolbar button {
            margin: 0 5px;
            padding: 5px 10px;
            border: 1px solid #ccc;
            background: white;
            border-radius: 3px;
            cursor: pointer;
        }
        .toolbar button:hover {
            background: #e9e9e9;
        }
    </style>
</head>
<body>
    <div class="toolbar">
        <button onclick="execCmd('bold')"><b>B</b></button>
        <button onclick="execCmd('italic')"><i>I</i></button>
        <button onclick="execCmd('underline')"><u>U</u></button>
        <button onclick="execCmd('formatBlock', 'h1')">H1</button>
        <button onclick="execCmd('formatBlock', 'h2')">H2</button>
        <button onclick="execCmd('formatBlock', 'p')">P</button>
        <button onclick="insertBubble()">💬 吹き出し</button>
        <button onclick="insertIcon()">🎨 アイコン</button>
    </div>
    <div id="editor" class="editor" contenteditable="true">
        CONTENT_PLACEHOLDER
    </div>
    
    <script>
        function execCmd(command, value = null) {
            document.execCommand(command, false, value);
            updateContent();
        }
        
        function insertBubble() {
            const bubble = '<div style="background: #e3f2fd; border-radius: 15px; padding: 10px; margin: 10px 0; border-left: 4px solid #2196f3;">💬 ここに内容を入力</div>';
            document.execCommand('insertHTML', false, bubble);
            updateContent();
        }
        
        function insertIcon() {
            const icon = '<span style="font-size: 24px; margin: 0 5px;">🌸</span>';
            document.execCommand('insertHTML', false, icon);
            updateContent();
        }
        
        function updateContent() {
            const content = document.getElementById('editor').innerHTML;
            // Flutter側にコンテンツを送信
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('contentChanged', content);
            }
        }
        
        // 初期化時にコンテンツ変更を監視
        document.getElementById('editor').addEventListener('input', updateContent);
        document.getElementById('editor').addEventListener('paste', function() {
            setTimeout(updateContent, 100);
        });
        
        // 初期コンテンツ設定
        function setContent(content) {
            document.getElementById('editor').innerHTML = content;
        }
        
        // コンテンツ取得
        function getContent() {
            return document.getElementById('editor').innerHTML;
        }
    </script>
</body>
</html>
  ''';

  String get htmlContent => _htmlContent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get htmlTemplate =>
      _htmlTemplate.replaceAll('CONTENT_PLACEHOLDER', _htmlContent);

  void setHtmlContent(String content) {
    _htmlContent = content;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // HTMLコンテンツを更新（WebViewからのコールバック用）
  void updateContentFromWebView(String content) {
    _htmlContent = content;
    notifyListeners();
  }

  // テンプレート適用
  void applyTemplate(String templateName) {
    switch (templateName) {
      case 'simple':
        _htmlContent = '<h1>学級通信</h1><p>今日の出来事...</p>';
        break;
      case 'bubble':
        _htmlContent = '''
          <h1>🌸 学級通信 🌸</h1>
          <div style="background: #e3f2fd; border-radius: 15px; padding: 15px; margin: 15px 0; border-left: 4px solid #2196f3;">
            💬 <strong>今日のハイライト</strong><br>
            ここに内容を入力してください
          </div>
        ''';
        break;
      case 'seasonal':
        _htmlContent = '''
          <div style="background: linear-gradient(135deg, #ffeb3b, #ff9800); padding: 20px; border-radius: 10px; text-align: center;">
            <h1 style="color: white; text-shadow: 2px 2px 4px rgba(0,0,0,0.5);">🍂 秋の学級通信 🍂</h1>
          </div>
          <p style="margin-top: 20px;">季節の内容をここに...</p>
        ''';
        break;
      default:
        _htmlContent = '<p>テンプレートが見つかりません</p>';
    }
    notifyListeners();
  }

  // カラーパレット適用
  void applyColorPalette(String season) {
    // 既存のコンテンツに季節のスタイルを適用
    String colorStyle = '';
    switch (season) {
      case 'spring':
        colorStyle = 'style="color: #4caf50; background: #f1f8e9;"';
        break;
      case 'summer':
        colorStyle = 'style="color: #2196f3; background: #e3f2fd;"';
        break;
      case 'autumn':
        colorStyle = 'style="color: #ff9800; background: #fff3e0;"';
        break;
      case 'winter':
        colorStyle = 'style="color: #9c27b0; background: #f3e5f5;"';
        break;
    }

    // 簡単な色適用（実際はより複雑な処理が必要）
    if (colorStyle.isNotEmpty) {
      _htmlContent = '<div $colorStyle>$_htmlContent</div>';
      notifyListeners();
    }
  }
}
