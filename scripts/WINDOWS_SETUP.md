# Windows11 環境構築ガイド

## 🎯 概要

Windows11で「学校だよりAI」プロジェクトを開始するための環境構築手順です。

## 🚀 クイックスタート（推奨）

### 1. 自動セットアップスクリプト実行

**PowerShellスクリプト（推奨）:**
```powershell
# 管理者権限でPowerShellを起動
# プロジェクトディレクトリで実行
.\scripts\setup-windows.ps1
```

**バッチファイル（簡単）:**
```batch
# setup-windows.bat を右クリック→「管理者として実行」
.\scripts\setup-windows.bat
```

### 2. 環境確認

```powershell
# 環境確認スクリプト実行
.\scripts\check-env-windows.ps1
```

### 3. 開発開始

```bash
cd frontend
flutter run -d chrome
```

## 📋 インストールされるツール

自動セットアップで以下のツールがインストールされます：

| ツール | 用途 | バージョン |
|--------|------|-----------|
| **Chocolatey** | パッケージマネージャー | 最新版 |
| **Git** | バージョン管理 | 最新版 |
| **Node.js** | JavaScript実行環境 | 20.10.0 |
| **Python** | バックエンド開発 | 3.11.6 |
| **Google Chrome** | アプリケーション実行 | 最新版 |
| **Visual Studio Code** | 開発エディタ | 最新版 |
| **Flutter SDK** | フロントエンド開発 | 3.16.5 |
| **Google Cloud CLI** | クラウド管理 | 最新版 |
| **Firebase CLI** | Firebase管理 | 最新版 |

## 🔧 手動セットアップ（詳細）

自動セットアップが失敗した場合の手動手順：

### 1. 必須ツールインストール

#### Chocolatey（パッケージマネージャー）
```powershell
# PowerShellを管理者権限で実行
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### 基本ツール
```powershell
# 一括インストール
choco install git nodejs python googlechrome vscode -y
```

#### Flutter SDK
```powershell
# Flutter SDK ダウンロード・インストール
# 1. https://docs.flutter.dev/get-started/install/windows からダウンロード
# 2. C:\flutter に解凍
# 3. PATH環境変数に C:\flutter\bin を追加

# PATH設定確認
flutter --version
flutter config --enable-web
```

#### Google Cloud CLI
```powershell
# Google Cloud CLI インストーラーダウンロード
# https://cloud.google.com/sdk/docs/install からダウンロード・実行
```

#### Firebase CLI
```powershell
npm install -g firebase-tools
```

### 2. プロジェクト依存関係

#### Python環境
```powershell
cd backend\functions
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
deactivate
```

#### Flutter環境
```powershell
cd frontend
flutter pub get
```

### 3. 設定ファイル

#### Firebase設定
```powershell
# テンプレートから設定ファイルをコピー
copy frontend\lib\firebase_options.dart.template frontend\lib\firebase_options.dart

# エディタで設定値を編集
code frontend\lib\firebase_options.dart
```

必要な設定値：
- `apiKey`: Firebase APIキー
- `projectId`: FirebaseプロジェクトID
- `appId`: Firebase アプリID

## 🧪 動作確認

### 1. 環境確認
```powershell
# 全ツール確認
.\scripts\check-env-windows.ps1

# Flutter確認
flutter doctor

# 個別確認
flutter --version
node --version
python --version
firebase --version
gcloud version
```

### 2. アプリケーション起動
```powershell
# フロントエンド起動
cd frontend
flutter run -d chrome

# バックエンド起動（別ターミナル）
cd backend\functions
.\venv\Scripts\Activate.ps1
python start_server.py
```

## 🛠️ 開発ツール設定

### Visual Studio Code拡張機能

推奨拡張機能：
- **Dart**: Flutter/Dart開発
- **Flutter**: Flutter開発
- **Python**: Python開発
- **GitLens**: Git管理
- **Thunder Client**: API テスト

自動インストール：
```powershell
# VS Code拡張機能一括インストール
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
code --install-extension ms-python.python
code --install-extension eamodio.gitlens
code --install-extension rangav.vscode-thunder-client
```

### PowerShell設定

PowerShell Profile設定：
```powershell
# PowerShell Profile作成・編集
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
notepad $PROFILE
```

Profile内容例：
```powershell
# 学校だよりAI プロジェクト用エイリアス
function gakkoudayori-dev {
    Set-Location "C:\path\to\gakkoudayori-ai"
    .\scripts\check-env-windows.ps1
}

# Flutter関数
function flutter-dev {
    Set-Location "frontend"
    flutter run -d chrome
}

# Python関数
function python-dev {
    Set-Location "backend\functions"
    .\venv\Scripts\Activate.ps1
}
```

## 🔍 トラブルシューティング

### よくある問題と解決方法

#### 1. 管理者権限エラー
```
問題: "管理者権限で実行してください"
解決: PowerShellまたはバッチファイルを右クリック→「管理者として実行」
```

#### 2. Flutter PATH エラー
```
問題: "'flutter' は、内部コマンドまたは外部コマンドとして認識されません"
解決: 
1. C:\flutter\bin をPATH環境変数に追加
2. PowerShellまたはコマンドプロンプトを再起動
```

#### 3. Python仮想環境エラー
```
問題: "venv\Scripts\Activate.ps1 を読み込めません"
解決: 
PowerShell実行ポリシー設定
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 4. Firebase設定エラー
```
問題: "Firebase configuration not found"
解決: 
1. frontend\lib\firebase_options.dart が存在するか確認
2. 実際のFirebase設定値が入力されているか確認
```

#### 5. Google Cloud認証エラー
```
問題: "Your default credentials were not found"
解決:
gcloud auth login
gcloud config set project your-project-id
```

### ログ確認

エラー時の詳細ログ確認：
```powershell
# Flutter詳細ログ
flutter run -d chrome --verbose

# Python詳細ログ
cd backend\functions
.\venv\Scripts\Activate.ps1
python start_server.py --debug
```

## 📚 参考資料

### 公式ドキュメント
- [Flutter Windows インストール](https://docs.flutter.dev/get-started/install/windows)
- [Google Cloud CLI インストール](https://cloud.google.com/sdk/docs/install-sdk#windows)
- [Firebase CLI インストール](https://firebase.google.com/docs/cli#install-cli-windows)
- [Node.js Windows インストール](https://nodejs.org/en/download/)

### プロジェクト関連
- [開発ガイド](development_guide.md)
- [システム設計](system_architecture.md)
- [メインREADME](../README.md)

## 💡 開発のコツ

### 1. 効率的な開発ワークフロー
```powershell
# 開発開始時の推奨手順
1. .\scripts\check-env-windows.ps1  # 環境確認
2. cd frontend && flutter pub get   # 依存関係更新
3. flutter run -d chrome           # 開発サーバー起動
```

### 2. 定期的なメンテナンス
```powershell
# 週次実行推奨
choco upgrade all              # 全ツール更新
flutter upgrade               # Flutter更新
npm update -g firebase-tools  # Firebase CLI更新
```

### 3. バックアップ推奨
- `frontend\lib\firebase_options.dart`（設定ファイル）
- `backend\functions\.env`（環境変数）
- `backend\secrets\`（認証キー）

---

## 🎯 次のステップ

環境構築完了後：

1. **[開発ガイド](development_guide.md)** で開発ワークフローを確認
2. **[システム設計](system_architecture.md)** でアーキテクチャを理解
3. **実際の開発を開始** - `make dev` で開発環境起動

Windows11での学校だよりAI開発を始めましょう！🚀