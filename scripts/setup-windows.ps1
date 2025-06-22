# 学校だよりAI - Windows11セットアップスクリプト
# PowerShellスクリプト
# 使用方法: PowerShell管理者権限で実行してください

param(
    [Parameter()]
    [string]$ProjectPath = $PWD
)

# エラー時停止
$ErrorActionPreference = "Stop"

Write-Host "🎯 学校だよりAI - Windows11環境セットアップ開始" -ForegroundColor Green
Write-Host "セットアップ対象: $ProjectPath" -ForegroundColor Cyan

# 関数定義
function Write-Status {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-AdminRights {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 管理者権限チェック
if (-not (Test-AdminRights)) {
    Write-Error "管理者権限で実行してください"
    Write-Host "PowerShellを右クリック→「管理者として実行」でもう一度実行してください" -ForegroundColor Yellow
    exit 1
}

Write-Status "管理者権限確認完了"

# Chocolatey インストール確認
Write-Host "📦 Chocolatey パッケージマネージャー確認中..." -ForegroundColor Cyan
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Warning "Chocolateyをインストール中..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Status "Chocolatey インストール完了"
} else {
    Write-Status "Chocolatey 確認完了"
}

# 必要ツールのインストール
Write-Host "🛠️ 必要ツールインストール中..." -ForegroundColor Cyan

$tools = @(
    @{name="Git"; package="git"; version="latest"},
    @{name="Node.js"; package="nodejs"; version="20.10.0"},
    @{name="Python"; package="python"; version="3.11.6"},
    @{name="Google Chrome"; package="googlechrome"; version="latest"},
    @{name="Visual Studio Code"; package="vscode"; version="latest"}
)

foreach ($tool in $tools) {
    Write-Host "📦 $($tool.name) 確認中..." -ForegroundColor White
    
    # 特別なチェック処理
    $isInstalled = $false
    switch ($tool.package) {
        "git" { $isInstalled = (Get-Command git -ErrorAction SilentlyContinue) -ne $null }
        "nodejs" { $isInstalled = (Get-Command node -ErrorAction SilentlyContinue) -ne $null }
        "python" { $isInstalled = (Get-Command python -ErrorAction SilentlyContinue) -ne $null }
        "googlechrome" { $isInstalled = Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe" }
        "vscode" { $isInstalled = (Get-Command code -ErrorAction SilentlyContinue) -ne $null }
    }
    
    if (-not $isInstalled) {
        Write-Warning "$($tool.name) をインストール中..."
        try {
            choco install $($tool.package) -y --force
            Write-Status "$($tool.name) インストール完了"
        } catch {
            Write-Error "$($tool.name) インストール失敗: $_"
        }
    } else {
        Write-Status "$($tool.name) 確認完了"
    }
}

# Flutter SDK インストール
Write-Host "🎨 Flutter SDK 確認中..." -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Warning "Flutter SDK をインストール中..."
    
    # Flutter SDK ダウンロード
    $flutterPath = "C:\flutter"
    if (Test-Path $flutterPath) {
        Write-Warning "既存のFlutterディレクトリを削除中..."
        Remove-Item -Path $flutterPath -Recurse -Force
    }
    
    Write-Host "Flutter SDK ダウンロード中..." -ForegroundColor White
    $flutterZip = "$env:TEMP\flutter_windows.zip"
    Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.5-stable.zip" -OutFile $flutterZip
    
    Write-Host "Flutter SDK 解凍中..." -ForegroundColor White
    Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
    Remove-Item $flutterZip
    
    # PATH 環境変数に追加
    Write-Host "Flutter PATH 設定中..." -ForegroundColor White
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*C:\flutter\bin*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\flutter\bin", "Machine")
        $env:PATH = "$env:PATH;C:\flutter\bin"
    }
    
    Write-Status "Flutter SDK インストール完了"
} else {
    Write-Status "Flutter SDK 確認完了"
}

# Flutter Web有効化
Write-Host "🌐 Flutter Web 有効化中..." -ForegroundColor Cyan
try {
    flutter config --enable-web
    Write-Status "Flutter Web 有効化完了"
} catch {
    Write-Warning "Flutter Web 有効化でエラーが発生しましたが続行します"
}

# Google Cloud CLI インストール
Write-Host "☁️ Google Cloud CLI 確認中..." -ForegroundColor Cyan
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Warning "Google Cloud CLI をインストール中..."
    
    # Google Cloud CLI インストーラーダウンロード
    $gcloudInstaller = "$env:TEMP\GoogleCloudSDKInstaller.exe"
    Write-Host "Google Cloud CLI ダウンロード中..." -ForegroundColor White
    Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -OutFile $gcloudInstaller
    
    Write-Host "Google Cloud CLI インストール中..." -ForegroundColor White
    Start-Process -FilePath $gcloudInstaller -ArgumentList "/S" -Wait
    Remove-Item $gcloudInstaller
    
    # PATH 更新
    $gcloudPath = "$env:USERPROFILE\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"
    if (Test-Path $gcloudPath) {
        $env:PATH = "$env:PATH;$gcloudPath"
        Write-Status "Google Cloud CLI インストール完了"
    } else {
        Write-Warning "Google Cloud CLI のパスが見つかりません。手動でPATHを設定してください"
    }
} else {
    Write-Status "Google Cloud CLI 確認完了"
}

# Firebase CLI インストール
Write-Host "🔥 Firebase CLI 確認中..." -ForegroundColor Cyan
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Warning "Firebase CLI をインストール中..."
    try {
        npm install -g firebase-tools
        Write-Status "Firebase CLI インストール完了"
    } catch {
        Write-Error "Firebase CLI インストール失敗: $_"
    }
} else {
    Write-Status "Firebase CLI 確認完了"
}

# プロジェクトディレクトリに移動
Set-Location $ProjectPath

# Python仮想環境セットアップ
Write-Host "🐍 Python仮想環境セットアップ中..." -ForegroundColor Cyan
$venvPath = "backend\functions\venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "Python仮想環境作成中..." -ForegroundColor White
    Set-Location "backend\functions"
    python -m venv venv
    Write-Status "Python仮想環境作成完了"
} else {
    Write-Status "Python仮想環境は既に存在します"
    Set-Location "backend\functions"
}

# 仮想環境アクティベートとパッケージインストール
Write-Host "Python依存関係インストール中..." -ForegroundColor White
& ".\venv\Scripts\Activate.ps1"
if (Test-Path "requirements.txt") {
    pip install -r requirements.txt
    Write-Status "Python依存関係インストール完了"
} else {
    Write-Warning "requirements.txt が見つかりません"
}
deactivate
Set-Location $ProjectPath

# Flutter依存関係取得
Write-Host "📱 Flutter依存関係取得中..." -ForegroundColor Cyan
Set-Location "frontend"
if (Test-Path "pubspec.yaml") {
    flutter pub get
    Write-Status "Flutter依存関係取得完了"
} else {
    Write-Warning "pubspec.yaml が見つかりません"
}
Set-Location $ProjectPath

# Firebase設定ファイル確認
Write-Host "🔥 Firebase設定確認中..." -ForegroundColor Cyan
$firebaseOptions = "frontend\lib\firebase_options.dart"
$firebaseTemplate = "$firebaseOptions.template"

if (Test-Path $firebaseTemplate -and -not (Test-Path $firebaseOptions)) {
    Write-Warning "Firebase設定ファイルをテンプレートからコピー中..."
    Copy-Item $firebaseTemplate $firebaseOptions
    Write-Host "⚠️ 重要: $firebaseOptions を編集して実際のFirebase設定値を入力してください" -ForegroundColor Yellow
    Write-Host "   - API Key, Project ID, App ID を設定" -ForegroundColor Yellow
} elseif (Test-Path $firebaseOptions) {
    Write-Status "Firebase設定ファイルが存在します"
} else {
    Write-Warning "Firebase設定ファイルが見つかりません"
}

# Flutter Doctor 実行
Write-Host "🩺 Flutter Doctor 実行中..." -ForegroundColor Cyan
flutter doctor

# 環境確認スクリプト作成
Write-Host "📋 環境確認スクリプト作成中..." -ForegroundColor Cyan
$checkScript = @"
# 環境確認スクリプト
Write-Host "🔍 学校だよりAI 環境確認" -ForegroundColor Green
Write-Host ""

# Flutter確認
Write-Host "📱 Flutter:" -ForegroundColor Cyan
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter --version | Select-Object -First 1
} else {
    Write-Host "   ❌ Flutter が見つかりません" -ForegroundColor Red
}

# Node.js確認
Write-Host "📦 Node.js:" -ForegroundColor Cyan
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "   ✅ Version: $((node --version))" -ForegroundColor Green
} else {
    Write-Host "   ❌ Node.js が見つかりません" -ForegroundColor Red
}

# Python確認
Write-Host "🐍 Python:" -ForegroundColor Cyan
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "   ✅ Version: $((python --version))" -ForegroundColor Green
} else {
    Write-Host "   ❌ Python が見つかりません" -ForegroundColor Red
}

# Firebase CLI確認
Write-Host "🔥 Firebase CLI:" -ForegroundColor Cyan
if (Get-Command firebase -ErrorAction SilentlyContinue) {
    Write-Host "   ✅ Version: $((firebase --version))" -ForegroundColor Green
} else {
    Write-Host "   ❌ Firebase CLI が見つかりません" -ForegroundColor Red
}

# Google Cloud CLI確認
Write-Host "☁️ Google Cloud CLI:" -ForegroundColor Cyan
if (Get-Command gcloud -ErrorAction SilentlyContinue) {
    Write-Host "   ✅ Version: $((gcloud version --format='value(Google Cloud SDK)'))" -ForegroundColor Green
} else {
    Write-Host "   ❌ Google Cloud CLI が見つかりません" -ForegroundColor Red
}

Write-Host ""
Write-Host "🚀 開発開始:" -ForegroundColor Green
Write-Host "   1. cd frontend" -ForegroundColor White
Write-Host "   2. flutter run -d chrome" -ForegroundColor White
"@

$checkScript | Out-File -FilePath "scripts\check-env-windows.ps1" -Encoding UTF8

Write-Status "環境確認スクリプト作成完了: scripts\check-env-windows.ps1"

Write-Host ""
Write-Host "🎉 Windows11環境セットアップ完了！" -ForegroundColor Green
Write-Host ""
Write-Host "📋 次の手順:" -ForegroundColor Cyan
Write-Host "1. PowerShellを再起動してPATH設定を反映" -ForegroundColor White
Write-Host "2. .\scripts\check-env-windows.ps1 で環境確認" -ForegroundColor White
Write-Host "3. Firebase設定ファイル編集: frontend\lib\firebase_options.dart" -ForegroundColor White
Write-Host "4. 開発開始: cd frontend && flutter run -d chrome" -ForegroundColor White
Write-Host ""
Write-Host "⚠️ 重要な設定:" -ForegroundColor Yellow
Write-Host "- Firebase設定値を frontend\lib\firebase_options.dart に設定" -ForegroundColor Yellow
Write-Host "- Google Cloud認証: gcloud auth login" -ForegroundColor Yellow
Write-Host "- Firebase認証: firebase login" -ForegroundColor Yellow
Write-Host ""