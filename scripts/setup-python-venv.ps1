# Python仮想環境セットアップスクリプト（Windows用）

param(
    [Parameter()]
    [switch]$Force = $false
)

Write-Host "🐍 Python仮想環境セットアップ開始" -ForegroundColor Green

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

# プロジェクトルート確認
$ProjectRoot = (Get-Item $PSScriptRoot).Parent.FullName
$BackendDir = Join-Path $ProjectRoot "backend\functions"
$VenvDir = Join-Path $BackendDir "venv"

Write-Host "📁 プロジェクトディレクトリ: $ProjectRoot" -ForegroundColor Cyan
Write-Host "📁 バックエンドディレクトリ: $BackendDir" -ForegroundColor Cyan

# Python確認
Write-Host "🔍 Python確認中..." -ForegroundColor White
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Pythonがインストールされていません"
    Write-Host "インストール方法:" -ForegroundColor Yellow
    Write-Host "  1. https://www.python.org/downloads/ からダウンロード" -ForegroundColor White
    Write-Host "  2. または: choco install python" -ForegroundColor White
    exit 1
}

$PythonVersion = python --version
Write-Status "Python確認完了: $PythonVersion"

# バックエンドディレクトリ移動
Set-Location $BackendDir

# 既存の仮想環境確認
if (Test-Path $VenvDir) {
    Write-Warning "既存の仮想環境が見つかりました"
    if ($Force) {
        $Reply = "Y"
    } else {
        $Reply = Read-Host "削除して再作成しますか？ (Y/N)"
    }
    
    if ($Reply -eq "Y") {
        Write-Host "🗑️ 既存の仮想環境を削除中..." -ForegroundColor White
        Remove-Item -Path $VenvDir -Recurse -Force
        Write-Status "既存の仮想環境削除完了"
    } else {
        Write-Host "既存の仮想環境を使用します" -ForegroundColor White
        exit 0
    }
}

# 仮想環境作成
Write-Host "🏗️ 仮想環境作成中..." -ForegroundColor White
python -m venv venv
Write-Status "仮想環境作成完了"

# 仮想環境アクティベート
Write-Host "🔌 仮想環境アクティベート中..." -ForegroundColor White
& ".\venv\Scripts\Activate.ps1"

# pipアップグレード
Write-Host "📦 pipアップグレード中..." -ForegroundColor White
python -m pip install --upgrade pip
Write-Status "pipアップグレード完了"

# requirements.txt確認・インストール
if (Test-Path "requirements.txt") {
    Write-Host "📋 requirements.txt発見" -ForegroundColor White
    Write-Host "📦 依存関係インストール中..." -ForegroundColor White
    pip install -r requirements.txt
    Write-Status "依存関係インストール完了"
} else {
    Write-Warning "requirements.txtが見つかりません"
    Write-Host "📝 基本的な依存関係をインストール中..." -ForegroundColor White
    
    # 基本的なパッケージインストール
    pip install fastapi uvicorn[standard] python-dotenv
    pip install google-cloud-aiplatform google-cloud-speech google-cloud-storage
    pip install firebase-admin
    pip install weasyprint
    pip install pytest pytest-cov pytest-asyncio
    pip install flake8 black isort mypy
    
    # requirements.txt生成
    Write-Host "📝 requirements.txt生成中..." -ForegroundColor White
    pip freeze > requirements.txt
    Write-Status "requirements.txt生成完了"
}

# 開発用パッケージインストール
Write-Host "🛠️ 開発用パッケージ確認中..." -ForegroundColor White
$devPackages = @("pytest", "flake8", "black", "mypy", "ipython")
$toInstall = @()

foreach ($package in $devPackages) {
    if (-not (pip show $package 2>$null)) {
        $toInstall += $package
    }
}

if ($toInstall.Count -gt 0) {
    Write-Host "開発用パッケージインストール中..." -ForegroundColor White
    pip install $toInstall pytest-cov pytest-asyncio isort
    Write-Status "開発用パッケージインストール完了"
}

# .env ファイル作成
if (-not (Test-Path ".env")) {
    Write-Host "🌍 .envファイル作成中..." -ForegroundColor White
    @"
# Google Cloud設定
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=./secrets/service-account-key.json

# Vertex AI設定
VERTEX_AI_LOCATION=asia-northeast1
GEMINI_MODEL=gemini-1.5-pro

# 環境設定
ENVIRONMENT=development
DEBUG=True

# API設定
API_HOST=0.0.0.0
API_PORT=8081

# Firebase設定
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
"@ | Out-File -FilePath ".env" -Encoding UTF8
    Write-Status ".envファイル作成完了"
    Write-Warning ".envファイルを実際の値で更新してください"
} else {
    Write-Status ".envファイルは既に存在します"
}

# .gitignore確認
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    if ($gitignoreContent -notmatch "venv/") {
        Write-Host "📋 .gitignore更新中..." -ForegroundColor White
        Add-Content -Path ".gitignore" -Value @"

# Python
venv/
__pycache__/
*.pyc
*.pyo
.pytest_cache/
.coverage
htmlcov/
.env
"@
        Write-Status ".gitignore更新完了"
    }
} else {
    Write-Host "📋 .gitignore作成中..." -ForegroundColor White
    @"
# Python
venv/
__pycache__/
*.pyc
*.pyo
.pytest_cache/
.coverage
htmlcov/
.env
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
    Write-Status ".gitignore作成完了"
}

# アクティベーションスクリプト作成
Write-Host "📝 便利スクリプト作成中..." -ForegroundColor White

# activate.ps1作成
@'
# 仮想環境アクティベート用スクリプト

if (Test-Path "venv\Scripts\Activate.ps1") {
    & ".\venv\Scripts\Activate.ps1"
    Write-Host "✅ Python仮想環境アクティベート完了" -ForegroundColor Green
    Write-Host "📦 Python: $(python --version)" -ForegroundColor Cyan
    Write-Host "📦 pip: $(pip --version)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🚀 開発サーバー起動: python start_server.py" -ForegroundColor White
    Write-Host "🧪 テスト実行: pytest" -ForegroundColor White
    Write-Host "🔍 コード検査: flake8 ." -ForegroundColor White
    Write-Host "✨ コード整形: black ." -ForegroundColor White
} else {
    Write-Host "❌ 仮想環境が見つかりません" -ForegroundColor Red
    Write-Host "実行: .\setup-python-venv.ps1" -ForegroundColor Yellow
}
'@ | Out-File -FilePath "activate.ps1" -Encoding UTF8

# activate.bat作成
@"
@echo off
REM 仮想環境アクティベート用バッチファイル

if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
    echo ✅ Python仮想環境アクティベート完了
    python --version
    pip --version
    echo.
    echo 🚀 開発サーバー起動: python start_server.py
    echo 🧪 テスト実行: pytest
    echo 🔍 コード検査: flake8 .
    echo ✨ コード整形: black .
) else (
    echo ❌ 仮想環境が見つかりません
    echo 実行: powershell -File setup-python-venv.ps1
)
"@ | Out-File -FilePath "activate.bat" -Encoding ASCII

# start_server.py確認
if (-not (Test-Path "start_server.py")) {
    Write-Host "📝 開発サーバースクリプト作成中..." -ForegroundColor White
    @'
#!/usr/bin/env python3
"""開発用サーバー起動スクリプト"""
import os
import sys
import uvicorn
from dotenv import load_dotenv

# .env読み込み
load_dotenv()

if __name__ == "__main__":
    # 環境変数取得
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", 8081))
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    print(f"🚀 開発サーバー起動中...")
    print(f"📍 URL: http://localhost:{port}")
    print(f"🔧 Debug: {debug}")
    print(f"📁 作業ディレクトリ: {os.getcwd()}")
    
    # Uvicorn起動
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=debug,
        log_level="debug" if debug else "info"
    )
'@ | Out-File -FilePath "start_server.py" -Encoding UTF8
    Write-Status "開発サーバースクリプト作成完了"
}

# テストスクリプト作成
@'
# テスト実行スクリプト

if (Test-Path "venv\Scripts\Activate.ps1") {
    & ".\venv\Scripts\Activate.ps1"
    
    Write-Host "🧪 テスト実行中..." -ForegroundColor Green
    pytest -v --cov=. --cov-report=html --cov-report=term
    
    Write-Host ""
    Write-Host "📊 カバレッジレポート: htmlcov\index.html" -ForegroundColor Cyan
} else {
    Write-Host "❌ 仮想環境が見つかりません" -ForegroundColor Red
}
'@ | Out-File -FilePath "run_tests.ps1" -Encoding UTF8

# 環境情報表示
Write-Host ""
Write-Host "📊 仮想環境情報:" -ForegroundColor Cyan
python --version
pip --version
Write-Host ""
Write-Host "📦 インストール済みパッケージ:" -ForegroundColor Cyan
pip list | Select-Object -First 20
Write-Host "..." -ForegroundColor Gray
Write-Host ""

# 完了メッセージ
Write-Status "Python仮想環境セットアップ完了！"

Write-Host ""
Write-Host "🎯 次の手順:" -ForegroundColor Green
Write-Host "1. 仮想環境アクティベート: .\venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host "   または: .\activate.ps1" -ForegroundColor White
Write-Host "   または: activate.bat (コマンドプロンプト)" -ForegroundColor White
Write-Host "2. .envファイル編集: 実際の設定値を入力" -ForegroundColor White
Write-Host "3. 開発サーバー起動: python start_server.py" -ForegroundColor White
Write-Host "4. テスト実行: .\run_tests.ps1" -ForegroundColor White
Write-Host ""
Write-Host "💡 便利なコマンド:" -ForegroundColor Cyan
Write-Host "  deactivate - 仮想環境を終了" -ForegroundColor White
Write-Host "  pip freeze > requirements.txt - 依存関係を保存" -ForegroundColor White
Write-Host "  pip install -r requirements.txt - 依存関係を復元" -ForegroundColor White
Write-Host ""