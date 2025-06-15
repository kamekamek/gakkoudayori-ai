# Python 3.11のベースイメージを使用
FROM python:3.11-slim

# 作業ディレクトリを設定
WORKDIR /app

# システムパッケージの更新とインストール
# WeasyPrintと日本語フォント対応のためのライブラリを追加
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libfontconfig1 \
    libcairo2 \
    libgdk-pixbuf2.0-0 \
    libgtk-3-0 \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    && rm -rf /var/lib/apt/lists/*

# Pythonの依存関係をコピーしてインストール
COPY functions/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコードをコピー
COPY functions/ .

# ポート8080を公開（Cloud Runのデフォルト）
EXPOSE 8080

# 環境変数を設定
ENV FLASK_APP=main.py
ENV FLASK_ENV=production
ENV PORT=8080

# アプリケーションを起動
CMD ["python", "main.py"] 