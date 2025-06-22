@echo off
REM 学校だよりAI - Windows11セットアップバッチファイル
REM 管理者権限で実行してください

echo 🎯 学校だよりAI - Windows11環境セットアップ開始
echo.

REM 管理者権限チェック
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ 管理者権限確認完了
) else (
    echo ❌ 管理者権限で実行してください
    echo バッチファイルを右クリック→「管理者として実行」でもう一度実行してください
    pause
    exit /b 1
)

REM PowerShell実行ポリシー設定
echo 📋 PowerShell実行ポリシー設定中...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force"
echo ✅ PowerShell実行ポリシー設定完了

REM PowerShellスクリプト実行
echo 🚀 PowerShellセットアップスクリプト実行中...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1" -ProjectPath "%~dp0.."

if %errorLevel% == 0 (
    echo.
    echo 🎉 セットアップ完了！
    echo.
    echo 📋 次の手順:
    echo 1. PowerShellまたはコマンドプロンプトを再起動
    echo 2. プロジェクトディレクトリに移動: cd "%~dp0.."
    echo 3. 環境確認: powershell -File scripts\check-env-windows.ps1
    echo 4. 開発開始: cd frontend ^&^& flutter run -d chrome
    echo.
    echo ⚠️ 重要な設定:
    echo - Firebase設定値を frontend\lib\firebase_options.dart に設定
    echo - Google Cloud認証: gcloud auth login
    echo - Firebase認証: firebase login
) else (
    echo.
    echo ❌ セットアップでエラーが発生しました
    echo PowerShellスクリプトを直接実行してください:
    echo powershell -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1"
)

echo.
pause