@echo off
setlocal enabledelayedexpansion

rem Windows Commands Launcher for Gakkoudayori AI
rem This batch file provides Windows equivalents for Makefile commands

echo ========================================
echo   Gakkoudayori AI - Windows Commands
echo ========================================
echo.

if "%1"=="" (
    echo Usage: windows-commands.bat [command]
    echo.
    echo Available commands:
    echo   help         - Show this help message
    echo   dev          - Start frontend development server
    echo   backend-dev  - Start backend development server
    echo   backend-setup - Setup Python environment
    echo   test         - Run all tests
    echo   build        - Build for production
    echo   clean        - Clean build artifacts
    echo.
    echo Or use individual batch files:
    echo   win-dev.bat
    echo   win-backend-dev.bat
    echo   win-backend-setup.bat
    echo   win-test.bat
    echo   win-build.bat
    echo.
    exit /b 1
)

set COMMAND=%1

if /i "%COMMAND%"=="help" (
    call :show_help
    exit /b 0
)

if /i "%COMMAND%"=="dev" (
    echo Starting frontend development server...
    call "%~dp0win-dev.bat"
    exit /b !errorlevel!
)

if /i "%COMMAND%"=="backend-dev" (
    echo Starting backend development server...
    call "%~dp0win-backend-dev.bat"
    exit /b !errorlevel!
)

if /i "%COMMAND%"=="backend-setup" (
    echo Setting up Python environment...
    call "%~dp0win-backend-setup.bat"
    exit /b !errorlevel!
)

if /i "%COMMAND%"=="test" (
    echo Running tests...
    call "%~dp0win-test.bat"
    exit /b !errorlevel!
)

if /i "%COMMAND%"=="build" (
    echo Building for production...
    call "%~dp0win-build.bat"
    exit /b !errorlevel!
)

if /i "%COMMAND%"=="clean" (
    echo Cleaning build artifacts...
    call :clean
    exit /b !errorlevel!
)

echo Error: Unknown command "%COMMAND%"
echo Run "windows-commands.bat help" for available commands
exit /b 1

:show_help
echo ========================================
echo   Gakkoudayori AI - Windows Commands
echo ========================================
echo.
echo This is a Windows batch file equivalent of the Makefile commands.
echo.
echo USAGE:
echo   windows-commands.bat [command]
echo.
echo COMMANDS:
echo   help         Show this help message
echo   dev          Start frontend development server (Flutter Web)
echo   backend-dev  Start backend development server (FastAPI)
echo   backend-setup Setup Python virtual environment
echo   test         Run all tests (frontend + backend)
echo   build        Build frontend for production
echo   clean        Clean build artifacts
echo.
echo INDIVIDUAL BATCH FILES:
echo   You can also use these files directly:
echo   - win-dev.bat         Frontend development
echo   - win-backend-dev.bat Backend development
echo   - win-backend-setup.bat Python environment setup
echo   - win-test.bat        Run tests
echo   - win-build.bat       Production build
echo.
echo REQUIREMENTS:
echo   - Flutter SDK
echo   - Python 3.9+
echo   - Node.js 18+ (for E2E tests)
echo   - Firebase CLI
echo.
exit /b 0

:clean
echo Cleaning build artifacts...
echo.

rem Clean Flutter build
if exist "..\frontend\build" (
    echo Removing frontend\build directory...
    rmdir /s /q "..\frontend\build"
)

rem Clean Flutter web build
if exist "..\frontend\.dart_tool" (
    echo Removing frontend\.dart_tool directory...
    rmdir /s /q "..\frontend\.dart_tool"
)

rem Clean Python cache
if exist "..\backend\functions\__pycache__" (
    echo Removing Python cache...
    for /d /r "..\backend\functions" %%d in (__pycache__) do @if exist "%%d" rmdir /s /q "%%d"
)

rem Clean pytest cache
if exist "..\backend\functions\.pytest_cache" (
    echo Removing pytest cache...
    rmdir /s /q "..\backend\functions\.pytest_cache"
)

echo Clean completed!
exit /b 0