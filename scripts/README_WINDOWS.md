# Windows バッチファイルガイド

## 概要

このディレクトリには、Windowsユーザー向けにMakefileの主要コマンドをバッチファイルで実装したスクリプトが含まれています。

## ファイル一覧

### メインランチャー
- **`windows-commands.bat`** - すべてのコマンドを管理するメインスクリプト

### 個別コマンド
- **`win-dev.bat`** - フロントエンド開発サーバー起動
- **`win-backend-dev.bat`** - バックエンド開発サーバー起動
- **`win-backend-setup.bat`** - Python環境セットアップ
- **`win-test.bat`** - テスト実行
- **`win-build.bat`** - プロダクションビルド

## 使用方法

### 方法1: メインランチャーを使用

```batch
cd scripts
windows-commands.bat [コマンド]
```

利用可能なコマンド:
- `help` - ヘルプを表示
- `dev` - フロントエンド開発サーバー起動
- `backend-dev` - バックエンド開発サーバー起動
- `backend-setup` - Python環境セットアップ
- `test` - すべてのテストを実行
- `build` - プロダクションビルド
- `clean` - ビルド成果物をクリーン

### 方法2: 個別バッチファイルを直接実行

```batch
cd scripts
win-dev.bat          # フロントエンド開発
win-backend-dev.bat  # バックエンド開発
win-backend-setup.bat # 環境構築
win-test.bat         # テスト実行
win-build.bat        # ビルド
```

## 初回セットアップ

### 1. 必要なソフトウェアのインストール

- **Flutter SDK**: https://flutter.dev/docs/get-started/install/windows
- **Python 3.9+**: https://www.python.org/downloads/
- **Node.js 18+**: https://nodejs.org/
- **Firebase CLI**: `npm install -g firebase-tools`
- **Git**: https://git-scm.com/download/win

### 2. Python環境のセットアップ

```batch
cd scripts
win-backend-setup.bat
```

これにより:
- Python仮想環境が作成されます
- 必要な依存関係がインストールされます
- 開発ツール（pytest、black、flake8など）がインストールされます

### 3. Flutter依存関係のインストール

```batch
cd frontend
flutter pub get
```

## 開発ワークフロー

### フロントエンド開発

1. 開発サーバーを起動:
   ```batch
   scripts\win-dev.bat
   ```

2. ブラウザが自動的に開き、http://localhost:5000 でアプリケーションが表示されます

3. コードを編集すると自動的にリロードされます

### バックエンド開発

1. 別のコマンドプロンプトで開発サーバーを起動:
   ```batch
   scripts\win-backend-dev.bat
   ```

2. APIは http://localhost:8081 で利用可能になります

3. API ドキュメントは http://localhost:8081/docs で確認できます

### テスト実行

```batch
scripts\win-test.bat
```

これにより:
- Flutter analyze（静的解析）
- Flutter test（単体テスト）
- Python flake8（コードスタイルチェック）
- Python black（フォーマットチェック）
- Python pytest（単体テスト）

が実行されます。

### プロダクションビルド

```batch
scripts\win-build.bat
```

ビルドされたファイルは `frontend\build\web` に出力されます。

## トラブルシューティング

### 「'flutter' は認識されていません」エラー

1. Flutter SDKがインストールされているか確認
2. 環境変数PATHにFlutterのbinディレクトリが追加されているか確認
3. コマンドプロンプトを再起動

### 「'python' は認識されていません」エラー

1. Pythonがインストールされているか確認
2. インストール時に「Add Python to PATH」にチェックを入れたか確認
3. コマンドプロンプトを再起動

### ポートが使用中エラー

- フロントエンド（ポート5000）:
  ```batch
  netstat -ano | findstr :5000
  taskkill /F /PID [プロセスID]
  ```

- バックエンド（ポート8081）:
  ```batch
  netstat -ano | findstr :8081
  taskkill /F /PID [プロセスID]
  ```

### Python仮想環境のアクティベートエラー

1. セキュリティポリシーを確認:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. または、コマンドプロンプト（cmd.exe）を使用

### ビルドエラー

1. `flutter clean` を実行してキャッシュをクリア
2. `flutter pub get` で依存関係を再インストール
3. `flutter doctor` で環境を確認

## 注意事項

- バッチファイルはプロジェクトルートまたはscriptsディレクトリから実行できます
- 初回実行時は依存関係のダウンロードに時間がかかる場合があります
- Google Cloud認証が必要な機能を使用する場合は、サービスアカウントキーの設定が必要です
- Windows Defenderやアンチウイルスソフトが開発ツールをブロックする場合があります

## 関連ドキュメント

- [プロジェクトREADME](../README.md)
- [CLAUDE.md](../CLAUDE.md) - AI開発ガイドライン
- [Makefile](../Makefile) - Unix/Linux/macOS用コマンド