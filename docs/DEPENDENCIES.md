# 📦 依存関係管理

**最終更新**: 2025-01-17 23:30  
**Phase**: R (Reset) - 最小構成  

---

## 🎯 **依存関係方針**

### **基本原則**
1. **最小限主義**: 必要最小限のパッケージのみ使用
2. **安定性優先**: 実績があり安定したパッケージを選択
3. **Web互換性**: Flutter Web で確実に動作するもの
4. **保守性**: メンテナンスされており将来性があるもの

---

## 📋 **Phase R 必須パッケージ**

### **Core Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0          # HTTP API呼び出し用
  web: ^1.1.0           # Web API (Audio等) 用
```

### **Development Dependencies**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0  # Lint設定
```

---

## ❌ **削除予定パッケージ（複雑化の原因）**

### **状態管理関連**
- ❌ `provider: ^6.0.5` - 過度に複雑な状態管理
- ❌ `flutter_riverpod: ^2.4.9` - 同上

### **Firebase関連（Phase R後に再検討）**
- ❌ `firebase_core: ^2.24.2`
- ❌ `firebase_auth: ^4.15.3`
- ❌ `cloud_firestore: ^4.13.6`
- ❌ `firebase_storage: ^11.5.6`
- ❌ `firebase_analytics: ^10.7.4`

### **UI/ウィジェット関連**
- ❌ `webview_flutter: ^4.4.2` - Quill.js統合で複雑化
- ❌ `webview_flutter_web: ^0.2.2+4` - 同上
- ❌ `webview_flutter_platform_interface: ^2.8.0` - 同上

### **ファイル・メディア関連**
- ❌ `file_picker: ^6.1.1` - 画像機能後回し
- ❌ `image: ^4.1.3` - 同上
- ❌ `path_provider: ^2.1.1` - ファイル操作複雑化

### **データ処理関連**
- ❌ `json_annotation: ^4.8.1` - モデル複雑化
- ❌ `json_serializable: ^6.7.1` - 同上
- ❌ `build_runner: ^2.4.7` - 同上

### **その他ユーティリティ**
- ❌ `uuid: ^4.2.1` - 現状不要
- ❌ `equatable: ^2.0.5` - モデル比較不要
- ❌ `go_router: ^12.1.3` - 単一画面につき不要

---

## 🔧 **パッケージ選定理由**

### **`http: ^1.1.0`** ✅
- **用途**: Google Cloud API（STT・Gemini）呼び出し
- **理由**: 
  - Flutter標準的なHTTPクライアント
  - Web対応済み、安定性高い
  - シンプルなAPI設計
- **代替案検討**: dio は高機能だが今回は不要

### **`web: ^1.1.0`** ✅  
- **用途**: Web Audio API、JavaScript連携
- **理由**:
  - Web専用API呼び出しに必須
  - Dart Web標準パッケージ
  - 軽量、依存関係なし
- **使用箇所**: 音声録音、ファイルダウンロード

---

## 🚫 **除外パッケージと理由**

### **Provider系状態管理**
- **問題**: 小規模アプリには過剰
- **Phase R方針**: StatefulWidget の setState() で十分
- **再検討時期**: Phase 2 で機能拡張時

### **Firebase系**
- **問題**: 認証・データ保存が現状不要
- **Phase R方針**: ローカルストレージ or HTTP API直接呼び出し
- **再検討時期**: ユーザー管理必要になった時点

### **WebView系**
- **問題**: Quill.js統合で複雑化、デバッグ困難
- **Phase R方針**: 基本HTML生成で十分
- **再検討時期**: リッチテキストエディタが必要になった時点

---

## 📊 **バージョン管理戦略**

### **固定バージョン方針**
```yaml
# ❌ 危険: バージョン範囲指定
http: ^1.1.0

# ✅ 安全: 固定バージョン（Phase R）
http: 1.1.0
web: 1.1.0
```

### **理由**
- Phase R は動作優先、予期しないバージョン更新を避ける
- 機能拡張時に計画的にバージョンアップ
- トラブルシューティング時の切り分け容易

---

## 🔄 **段階的導入計画**

### **Phase R+1: 基本機能拡張**
```yaml
# 追加候補
shared_preferences: ^2.2.2  # 設定保存
path: ^1.8.3               # パス操作
```

### **Phase R+2: UI/UX改善**
```yaml
# 追加候補
flutter_svg: ^2.0.9       # アイコン
google_fonts: ^6.1.0      # フォント
```

### **Phase R+3: 高度な機能**
```yaml
# 再検討候補
firebase_core: ^2.24.2    # 必要に応じて
provider: ^6.0.5          # 状態管理複雑化時
```

---

## 🚨 **注意事項**

### **Web特有の制約**
- `dart:io` 使用不可（ファイル操作制限）
- ネイティブプラグイン使用不可
- CORS制約あり（API呼び出し時）

### **回避方法**
- ファイル操作: `web` パッケージのWeb API使用
- ネイティブ機能: JavaScript Bridge経由
- CORS: バックエンドでヘッダー設定

---

**🎯 Phase R 成功指標**: 依存関係3個以下で音声→HTML変換完全動作 