@echo off
setlocal enabledelayedexpansion

rem Production Build Script for Windows
rem Builds Flutter Web app for production deployment

echo ========================================
echo   Production Build
echo ========================================
echo.

rem Check if we're in the scripts directory
if exist "win-build.bat" (
    cd ..
)

rem Check if Flutter is installed
where flutter >nul 2>nul
if !errorlevel! neq 0 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

rem Check if frontend directory exists
if not exist "frontend" (
    echo Error: frontend directory not found
    echo Make sure you're running this from the project root
    pause
    exit /b 1
)

cd frontend

rem Check if pubspec.yaml exists
if not exist "pubspec.yaml" (
    echo Error: pubspec.yaml not found in frontend directory
    pause
    exit /b 1
)

echo Cleaning previous builds...
if exist "build\web" (
    rmdir /s /q "build\web"
)

echo.
echo Installing/updating dependencies...
flutter pub get
if !errorlevel! neq 0 (
    echo Error: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Running Flutter analyzer...
flutter analyze
if !errorlevel! neq 0 (
    echo.
    echo Warning: Flutter analyze found issues
    echo Consider fixing these before building for production
    echo.
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i "!CONTINUE!" neq "y" (
        exit /b 1
    )
)

echo.
echo Building for production...
echo This may take several minutes...
echo.

rem Build with production environment variables
flutter build web --release ^^
    --dart-define=ENV=prod ^^
    --dart-define=API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai ^^
    --web-renderer=canvaskit

if !errorlevel! neq 0 (
    echo.
    echo Error: Build failed!
    echo.
    echo Common issues:
    echo 1. Check for compilation errors in the code
    echo 2. Ensure all assets are properly referenced
    echo 3. Verify pubspec.yaml is correctly formatted
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Build completed successfully!
echo ========================================
echo.
echo Build output: frontend\build\web
echo.
echo Next steps:
echo 1. Test the build locally:
    echo    cd frontend\build\web
    echo    python -m http.server 8000
    echo    (or use any static file server)
echo.
echo 2. Deploy to Firebase Hosting:
    echo    firebase deploy --only hosting
echo.
echo 3. Or deploy all (hosting + functions):
    echo    firebase deploy
echo.

rem Optional: Show build size
echo Build size information:
dir "build\web" | find "File(s)"
echo.

pause
exit /b 0