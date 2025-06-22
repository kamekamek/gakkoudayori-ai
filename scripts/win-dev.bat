@echo off
setlocal enabledelayedexpansion

rem Frontend Development Server for Windows
rem Starts Flutter Web development server with proper environment variables

echo ========================================
echo   Starting Frontend Development Server
echo ========================================
echo.

rem Check if we're in the scripts directory
if exist "win-dev.bat" (
    cd ..
)

rem Check if Flutter is installed
where flutter >nul 2>nul
if !errorlevel! neq 0 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install/windows
    exit /b 1
)

rem Check if frontend directory exists
if not exist "frontend" (
    echo Error: frontend directory not found
    echo Make sure you're running this from the project root
    exit /b 1
)

cd frontend

rem Check if pubspec.yaml exists
if not exist "pubspec.yaml" (
    echo Error: pubspec.yaml not found in frontend directory
    exit /b 1
)

echo Checking Flutter dependencies...
echo.

rem Get dependencies if needed
if not exist ".dart_tool" (
    echo Installing dependencies...
    flutter pub get
    if !errorlevel! neq 0 (
        echo Error: Failed to install dependencies
        exit /b 1
    )
)

echo Starting development server...
echo.
echo Environment: DEVELOPMENT
echo API URL: http://localhost:8081/api/v1/ai
echo.
echo Press Ctrl+C to stop the server
echo.

rem Start Flutter with development environment variables
flutter run -d chrome --dart-define=ENV=dev --dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai --web-port=5000

if !errorlevel! neq 0 (
    echo.
    echo Error: Failed to start development server
    echo.
    echo Troubleshooting:
    echo 1. Make sure Chrome is installed
    echo 2. Check if port 5000 is available
    echo 3. Run 'flutter doctor' to check your environment
    exit /b 1
)

exit /b 0