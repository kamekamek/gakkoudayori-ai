#!/bin/bash
# flutter_setup_cli.sh
# Flutter環境セットアップスクリプト

set -e

echo "🎨 Flutter環境セットアップ開始"

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Flutter CLI確認
echo "📋 Flutter CLI確認中..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter CLIがインストールされていません"
    echo "インストールURL: https://docs.flutter.dev/get-started/install"
    exit 1
fi

print_status "Flutter CLI確認完了"

# Flutter doctor実行
echo "🩺 Flutter doctor実行中..."
flutter doctor

# Flutter Web有効化確認
echo "🌐 Flutter Web有効化確認中..."
flutter config --enable-web
print_status "Flutter Web有効化完了"

# Chromeチェック
echo "🔍 Chrome ブラウザ確認中..."
if ! command -v google-chrome &> /dev/null && ! command -v chromium-browser &> /dev/null && ! command -v open &> /dev/null; then
    print_warning "Chrome ブラウザが見つかりません"
else
    print_status "Chrome ブラウザ確認完了"
fi

# frontend ディレクトリ移動
cd frontend

# Flutter プロジェクト初期化確認
if [ ! -f "pubspec.yaml" ]; then
    print_warning "Flutter プロジェクトを初期化中..."
    flutter create . --project-name gakkoudayori_ai --org ai.gakkoudayori
    print_status "Flutter プロジェクト初期化完了"
else
    print_status "Flutter プロジェクトは既に存在します"
fi

# pubspec.yaml 更新
echo "📦 依存関係更新中..."

cat > pubspec.yaml << 'EOF'
name: gakkoudayori_ai
description: 学校だよりAI - 音声入力で学級通信を自動生成
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  
  # Web
  webview_flutter: ^4.4.2
  webview_flutter_web: ^0.2.2+4
  
  # State Management
  provider: ^6.1.1
  riverpod: ^2.4.9
  flutter_riverpod: ^2.4.9
  
  # HTTP & API
  http: ^1.1.2
  dio: ^5.4.0
  
  # JSON
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
  
  # UI Components
  material_design_icons_flutter: ^7.0.7296
  flutter_colorpicker: ^1.0.3
  
  # File & Storage
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  
  # Utils
  uuid: ^4.2.1
  intl: ^0.19.0
  
  # Development
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Testing
  mockito: ^5.4.4
  flutter_driver:
    sdk: flutter
  integration_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  
  # Linting
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/audio/
  
  fonts:
    - family: NotoSansJP
      fonts:
        - asset: assets/fonts/NotoSansJP-Regular.ttf
        - asset: assets/fonts/NotoSansJP-Bold.ttf
          weight: 700

EOF

print_status "pubspec.yaml更新完了"

# 依存関係取得
echo "📥 依存関係取得中..."
flutter pub get

# assets ディレクトリ作成
echo "📁 assetsディレクトリ作成中..."
mkdir -p assets/{images,icons,audio,fonts}
print_status "assetsディレクトリ作成完了"

# web ディレクトリ設定
echo "🌐 web ディレクトリ設定中..."
mkdir -p web/{quill,assets}

# Quill.js設定準備
echo "📝 Quill.js設定準備中..."
mkdir -p web/quill/{css,js}

cat > web/quill/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Quill Editor</title>
  <link href="https://cdn.quilljs.com/1.3.6/quill.snow.css" rel="stylesheet">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: 'Noto Sans JP', sans-serif;
    }
    
    #editor-container {
      height: 100vh;
      width: 100%;
    }
    
    .ql-toolbar {
      border-top: none;
      border-left: none;
      border-right: none;
    }
    
    .ql-container {
      border: none;
      font-size: 16px;
      line-height: 1.6;
    }
    
    /* 季節テーマ用CSS変数 */
    :root {
      --theme-primary: #4CAF50;
      --theme-secondary: #81C784;
      --theme-accent: #C8E6C9;
    }
    
    .theme-spring {
      --theme-primary: #4CAF50;
      --theme-secondary: #81C784;
      --theme-accent: #C8E6C9;
    }
    
    .theme-summer {
      --theme-primary: #2196F3;
      --theme-secondary: #64B5F6;
      --theme-accent: #BBDEFB;
    }
    
    .theme-autumn {
      --theme-primary: #FF9800;
      --theme-secondary: #FFB74D;
      --theme-accent: #FFE0B2;
    }
    
    .theme-winter {
      --theme-primary: #9C27B0;
      --theme-secondary: #BA68C8;
      --theme-accent: #E1BEE7;
    }
  </style>
</head>
<body>
  <div id="editor-container">
    <div id="editor"></div>
  </div>
  
  <script src="https://cdn.quilljs.com/1.3.6/quill.min.js"></script>
  <script>
    // Quill.js 初期化
    const quill = new Quill('#editor', {
      theme: 'snow',
      modules: {
        toolbar: [
          [{ 'header': [1, 2, 3, false] }],
          ['bold', 'italic', 'underline'],
          [{ 'list': 'ordered'}, { 'list': 'bullet' }],
          ['clean']
        ]
      },
      placeholder: '学級通信の内容を入力してください...'
    });
    
    // Flutter ↔ JavaScript Bridge
    window.quillEditor = {
      // Delta取得
      getContents: function() {
        return JSON.stringify(quill.getContents());
      },
      
      // Delta設定
      setContents: function(deltaJson) {
        const delta = JSON.parse(deltaJson);
        quill.setContents(delta);
      },
      
      // HTML取得
      getHTML: function() {
        return quill.root.innerHTML;
      },
      
      // HTML設定
      setHTML: function(html) {
        quill.root.innerHTML = html;
      },
      
      // テーマ変更
      setTheme: function(theme) {
        document.body.className = 'theme-' + theme;
      },
      
      // 変更監視
      onChange: function(callback) {
        quill.on('text-change', function(delta, oldDelta, source) {
          if (source === 'user') {
            callback(JSON.stringify(quill.getContents()));
          }
        });
      }
    };
    
    // Flutter通信用
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('quillReady');
    }
  </script>
</body>
</html>
EOF

print_status "Quill.js設定完了"

# lib ディレクトリ構造作成
echo "📂 lib ディレクトリ構造作成中..."

mkdir -p lib/{
  main,
  screens,
  widgets,
  providers,
  services,
  models,
  utils,
  constants
}

print_status "lib ディレクトリ構造作成完了"

# 基本main.dart作成
echo "📝 基本main.dart作成中..."

cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await Firebase.initializeApp();
  
  runApp(
    const ProviderScope(
      child: GakkouDayoriAiApp(),
    ),
  );
}

class GakkouDayoriAiApp extends StatelessWidget {
  const GakkouDayoriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学校だよりAI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'NotoSansJP',
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '学校だよりAI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '🎯 学校だよりAI',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              '音声入力で学級通信を自動生成',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('環境セットアップ中...'),
          ],
        ),
      ),
    );
  }
}
EOF

print_status "基本main.dart作成完了"

# Flutter Web テスト実行
echo "🧪 Flutter Web テスト実行中..."
flutter test
print_status "Flutter テスト完了"

# Flutter Web ビルドテスト
echo "🏗️  Flutter Web ビルドテスト中..."
flutter build web --web-renderer html
print_status "Flutter Web ビルド完了"

# 戻る
cd ..

print_status "Flutter環境セットアップ完了！"

echo ""
echo "🎯 確認方法:"
echo "1. cd frontend"
echo "2. flutter run -d chrome"
echo "3. ブラウザでアプリケーション確認"
echo ""
EOF 