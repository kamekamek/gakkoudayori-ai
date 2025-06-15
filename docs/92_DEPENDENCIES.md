# 📦 依存関係管理

**最終更新**: 2025-06-12 22:38  
**方針**: 必要最小限のパッケージのみ使用

---

## 🎯 **Phase R 最小依存関係**

### **pubspec.yaml (最小構成)**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0      # API呼び出し（STT・Gemini）
  web: ^1.1.0       # Web Audio API
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## 📋 **パッケージ使用目的**

### **production dependencies (2個)**

| パッケージ | バージョン | 使用目的 | Phase |
|-----------|-----------|----------|-------|
| `http` | ^1.1.0 | バックエンドAPI呼び出し | R3-R4 |
| `web` | ^1.1.0 | Web Audio API, JavaScript Bridge | R2 |

### **dev dependencies (2個)**
| パッケージ | バージョン | 使用目的 | Phase |
|-----------|-----------|----------|-------|
| `flutter_test` | SDK | 基本テスト | R5 |
| `flutter_lints` | ^6.0.0 | コード品質 | 全期間 |

---

## ❌ **削除済み依存関係**

### **複雑性の原因だったパッケージ**
- ❌ `provider` - 状態管理（シンプルなStatefulWidgetで十分）
- ❌ `firebase_*` - Firebase関連（Phase R後に必要に応じて再導入）
- ❌ `webview_flutter_*` - WebView（Quill.js削除により不要）
- ❌ `file_picker` - ファイル選択（写真機能は後回し）
- ❌ `json_annotation` - JSON生成（シンプルなMapで十分）
- ❌ `material_design_icons_flutter` - アイコン（基本アイコンで十分）
- ❌ `uuid` - ID生成（不要）
- ❌ `intl` - 国際化（後回し）

---

## 🔄 **段階的依存関係追加計画**

### **Phase R+1 (認証・保存機能)**
```yaml
# 必要に応じて追加予定
firebase_core: ^3.14.0
firebase_auth: ^5.5.4
```

### **Phase R+2 (データ永続化)**
```yaml
# 必要に応じて追加予定
cloud_firestore: ^5.6.8
firebase_storage: ^12.3.6
```

### **Phase R+3 (UI強化)**
```yaml
# 必要に応じて追加予定
provider: ^6.0.5
material_design_icons_flutter: ^7.0.7296
```

---

## 📝 **依存関係追加ルール**

### **追加前チェックリスト**
1. ✅ 本当に必要な機能か？
2. ✅ 標準ライブラリで代替できないか？
3. ✅ パッケージサイズは適切か？
4. ✅ メンテナンス状況は良好か？
5. ✅ 他のパッケージと競合しないか？

### **禁止事項**
- 🚫 1つの機能に複数のパッケージを使用
- 🚫 メンテナンスされていないパッケージの使用
- 🚫 "念のため"でのパッケージ追加
- 🚫 ドキュメントが不十分なパッケージの使用

---

**🎯 目標**: 軽量・高速・安定したアプリケーション 