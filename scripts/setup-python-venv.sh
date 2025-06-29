#!/bin/bash
# Python仮想環境セットアップスクリプト（Mac/Linux用）

set -e

echo "🐍 Python仮想環境セットアップ開始"

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

# プロジェクトルート確認
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
BACKEND_DIR="$PROJECT_ROOT/backend/functions"
VENV_DIR="$BACKEND_DIR/venv"

echo "📁 プロジェクトディレクトリ: $PROJECT_ROOT"
echo "📁 バックエンドディレクトリ: $BACKEND_DIR"

# Python確認
echo "🔍 Python確認中..."
if ! command -v python3 &> /dev/null; then
    print_error "Python3がインストールされていません"
    echo "インストール方法:"
    echo "  Mac: brew install python3"
    echo "  Ubuntu/Debian: sudo apt-get install python3 python3-pip python3-venv"
    echo "  CentOS/RHEL: sudo yum install python3 python3-pip"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
print_status "Python確認完了: $PYTHON_VERSION"

# pip確認
echo "📦 pip確認中..."
if ! python3 -m pip --version &> /dev/null; then
    print_warning "pipがインストールされていません。インストール中..."
    python3 -m ensurepip --upgrade
fi
print_status "pip確認完了"

# バックエンドディレクトリ移動
cd "$BACKEND_DIR"

# 既存の仮想環境確認
if [ -d "$VENV_DIR" ]; then
    print_warning "既存の仮想環境が見つかりました"
    read -p "削除して再作成しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  既存の仮想環境を削除中..."
        rm -rf "$VENV_DIR"
        print_status "既存の仮想環境削除完了"
    else
        echo "既存の仮想環境を使用します"
        exit 0
    fi
fi

# 仮想環境作成
echo "🏗️  仮想環境作成中..."
python3 -m venv venv
print_status "仮想環境作成完了"

# 仮想環境アクティベート
echo "🔌 仮想環境アクティベート中..."
source venv/bin/activate

# pipアップグレード
echo "📦 pipアップグレード中..."
pip install --upgrade pip
print_status "pipアップグレード完了"

# requirements.txt確認・インストール
if [ -f "requirements.txt" ]; then
    echo "📋 requirements.txt発見"
    echo "📦 依存関係インストール中..."
    pip install -r requirements.txt
    print_status "依存関係インストール完了"
else
    print_warning "requirements.txtが見つかりません"
    echo "📝 基本的な依存関係をインストール中..."
    
    # 基本的なパッケージインストール
    pip install fastapi uvicorn[standard] python-dotenv
    pip install google-cloud-aiplatform google-cloud-speech google-cloud-storage
    pip install firebase-admin
    pip install weasyprint
    pip install pytest pytest-cov pytest-asyncio
    pip install flake8 black isort mypy
    
    # requirements.txt生成
    echo "📝 requirements.txt生成中..."
    pip freeze > requirements.txt
    print_status "requirements.txt生成完了"
fi

# 開発用パッケージインストール
echo "🛠️  開発用パッケージ確認中..."
if ! pip show pytest &> /dev/null; then
    echo "開発用パッケージインストール中..."
    pip install pytest pytest-cov pytest-asyncio
    pip install flake8 black isort mypy
    pip install ipython
    print_status "開発用パッケージインストール完了"
fi

# .env ファイル作成
if [ ! -f ".env" ]; then
    echo "🌍 .envファイル作成中..."
    cat > .env << 'EOF'
# Google Cloud設定
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=./secrets/service-account-key.json

# Vertex AI設定
VERTEX_AI_LOCATION=asia-northeast1
GEMINI_MODEL=gemini-2.5-pro

# 環境設定
ENVIRONMENT=development
DEBUG=True

# API設定
API_HOST=0.0.0.0
API_PORT=8081

# Firebase設定
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
EOF
    print_status ".envファイル作成完了"
    print_warning ".envファイルを実際の値で更新してください"
else
    print_status ".envファイルは既に存在します"
fi

# .gitignore確認
if ! grep -q "venv/" .gitignore 2>/dev/null; then
    echo "📋 .gitignore更新中..."
    echo "" >> .gitignore
    echo "# Python" >> .gitignore
    echo "venv/" >> .gitignore
    echo "__pycache__/" >> .gitignore
    echo "*.pyc" >> .gitignore
    echo "*.pyo" >> .gitignore
    echo ".pytest_cache/" >> .gitignore
    echo ".coverage" >> .gitignore
    echo "htmlcov/" >> .gitignore
    echo ".env" >> .gitignore
    print_status ".gitignore更新完了"
fi

# アクティベーションスクリプト作成
echo "📝 便利スクリプト作成中..."

# activate.sh作成
cat > activate.sh << 'EOF'
#!/bin/bash
# 仮想環境アクティベート用スクリプト

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ Python仮想環境アクティベート完了"
    echo "📦 Python: $(python --version)"
    echo "📦 pip: $(pip --version)"
    echo ""
    echo "🚀 開発サーバー起動: python start_server.py"
    echo "🧪 テスト実行: pytest"
    echo "🔍 コード検査: flake8 ."
    echo "✨ コード整形: black ."
else
    echo "❌ 仮想環境が見つかりません"
    echo "実行: ./setup-python-venv.sh"
fi
EOF
chmod +x activate.sh

# start_server.py確認
if [ ! -f "start_server.py" ]; then
    echo "📝 開発サーバースクリプト作成中..."
    cat > start_server.py << 'EOF'
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
EOF
    print_status "開発サーバースクリプト作成完了"
fi

# テストスクリプト作成
cat > run_tests.sh << 'EOF'
#!/bin/bash
# テスト実行スクリプト

source venv/bin/activate

echo "🧪 テスト実行中..."
pytest -v --cov=. --cov-report=html --cov-report=term

echo ""
echo "📊 カバレッジレポート: htmlcov/index.html"
EOF
chmod +x run_tests.sh

# 環境情報表示
echo ""
echo "📊 仮想環境情報:"
echo "Python: $(python --version)"
echo "pip: $(pip --version)"
echo ""
echo "📦 インストール済みパッケージ:"
pip list | head -20
echo "..."
echo ""

# 完了メッセージ
print_status "Python仮想環境セットアップ完了！"

echo ""
echo "🎯 次の手順:"
echo "1. 仮想環境アクティベート: source venv/bin/activate"
echo "   または: ./activate.sh"
echo "2. .envファイル編集: 実際の設定値を入力"
echo "3. 開発サーバー起動: python start_server.py"
echo "4. テスト実行: ./run_tests.sh"
echo ""
echo "💡 便利なコマンド:"
echo "  deactivate - 仮想環境を終了"
echo "  pip freeze > requirements.txt - 依存関係を保存"
echo "  pip install -r requirements.txt - 依存関係を復元"
echo ""