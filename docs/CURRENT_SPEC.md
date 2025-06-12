# 📋 現在仕様・状況管理

**最終更新**: 2025-01-17 23:30  
**状況**: 🔄 リビルド開始  

---

## 🎯 **実装目標**

### **最終ゴール**
音声入力 → AI文章生成 → HTML学級通信作成・ダウンロード

### **現在のフェーズ**  
**Phase R (Reset)**: 複雑なコードベースをリセットし、最小機能から再構築

---

## ✅ **動作確認済み機能**

### **バックエンド（FastAPI）**
- ✅ Google Cloud Speech-to-Text API連携
- ✅ Vertex AI Gemini Pro API連携  
- ✅ HTML制約プロンプト機能
- ✅ Firebase Authentication/Firestore/Storage

### **フロントエンド（Flutter Web）**
- ⚠️ **問題発生**: 複雑すぎて音声録音が動作しない
- ⚠️ **問題発生**: UI/UXが複雑で保守困難
- ⚠️ **問題発生**: エラーが多すぎて開発効率悪い

---

## ❌ **既知の問題**

### **Critical Issues**
1. **音声録音不可**: Web Audio API統合に失敗
2. **UI複雑化**: 3カラムレイアウト等が過度に複雑
3. **依存地獄**: パッケージ競合・バージョン問題
4. **コード分散**: 機能が多数ファイルに分散し把握困難

### **Minor Issues**  
- 102個のlintエラー
- テストファイル引数不足
- 非推奨API使用警告

---

## 🔄 **リビルド方針**

### **削除予定機能**
- 🗑️ 複雑な3カラムレイアウト
- 🗑️ Quill.js統合（過度に複雑）
- 🗑️ 季節テーマシステム（後回し）
- 🗑️ マルチエージェント機能（後回し）
- 🗑️ PDF出力機能（後回し）
- 🗑️ 写真ライブラリ（後回し）

### **保持機能**
- ✅ Google Cloud Speech-to-Text
- ✅ Vertex AI Gemini Pro
- ✅ 基本的なHTML生成
- ✅ Firebase基盤（簡素化）

---

## 🎯 **新仕様（Phase R）**

### **UI構成**
```
┌─────────────────────────────────────┐
│  🎤 学級通信AI - 音声入力システム    │
├─────────────────────────────────────┤
│                                     │
│        [🎤 録音開始]               │
│                                     │
│  📝 音声入力内容:                   │
│  [                              ]   │
│                                     │
│        [🤖 HTML生成]               │
│                                     │
│  📄 生成結果:                       │
│  [                              ]   │
│                                     │
│        [💾 ダウンロード]            │
│                                     │
└─────────────────────────────────────┘
```

### **技術仕様**
- **フロントエンド**: Flutter Web（最小構成）
- **音声録音**: Web Audio API（JavaScript直接呼び出し）
- **音声認識**: Google Cloud Speech-to-Text
- **AI文章生成**: Vertex AI Gemini Pro
- **ファイル出力**: HTML直接ダウンロード

---

## 📦 **最小依存関係**

### **pubspec.yaml（簡素版）**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0          # API呼び出し
  web: ^1.1.0           # Web API
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### **削除予定パッケージ**
- ❌ provider (状態管理不要)
- ❌ firebase_* (Phase R後に再導入)
- ❌ webview_flutter_* (Quill.js削除)
- ❌ file_picker (画像機能後回し)
- ❌ json_annotation (複雑なモデル不要)

---

## 📁 **ファイル構成（Phase R）**

### **保持ファイル**
```
├── lib/
│   ├── main.dart              # ✅ 簡素化
│   ├── app.dart               # 🆕 新規作成
│   ├── pages/
│   │   └── home_page.dart     # 🆕 メイン画面のみ
│   └── services/
│       ├── audio_service.dart # 🆕 音声録音
│       ├── speech_service.dart# 🆕 STT
│       └── ai_service.dart    # 🆕 Gemini
├── web/
│   ├── index.html            # ✅ 簡素化  
│   └── audio.js              # 🆕 音声JS
└── backend/
    └── functions/
        ├── main.py           # ✅ 既存利用
        ├── speech_recognition_service.py # ✅ 既存利用
        └── html_constraint_service.py    # ✅ 既存利用
```

### **削除ファイル**
- 🗑️ `lib/features/` 全体（過度に複雑）
- 🗑️ `lib/core/` の大部分（theme等不要）
- 🗑️ `test/` 全体（Phase R後に再構築）

---

## 🚀 **次のアクション**

### **R1: プロジェクト整理** (今すぐ実行)
1. 不要ファイル削除
2. pubspec.yaml簡素化
3. 基本ディレクトリ作成

### **R2-R5: 機能実装** (明日)
1. 音声録音機能
2. 音声認識連携
3. AI文章生成
4. HTML表示・ダウンロード

---

**🎯 成功指標**: 音声→HTML学級通信が1本のフローで完全動作すること 