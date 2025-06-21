@echo off
setlocal enabledelayedexpansion

rem Python Backend Environment Setup for Windows
rem Creates virtual environment and installs dependencies

echo ========================================
echo   Python Backend Environment Setup
echo ========================================
echo.

rem Check if we're in the scripts directory
if exist "win-backend-setup.bat" (
    cd ..
)

rem Check if Python is installed
python --version >nul 2>nul
if !errorlevel! neq 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.9 or later from https://www.python.org/
    echo.
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

rem Get Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo Found Python version: %PYTHON_VERSION%

rem Check Python version (should be 3.9+)
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    if %%a lss 3 (
        echo Error: Python 3.9 or later is required
        echo You have Python %PYTHON_VERSION%
        pause
        exit /b 1
    )
    if %%a equ 3 if %%b lss 9 (
        echo Error: Python 3.9 or later is required
        echo You have Python %PYTHON_VERSION%
        pause
        exit /b 1
    )
)

rem Check if backend directory exists
if not exist "backend\functions" (
    echo Error: backend\functions directory not found
    echo Make sure you're running this from the project root
    pause
    exit /b 1
)

cd backend\functions

rem Check if requirements.txt exists
if not exist "requirements.txt" (
    echo Error: requirements.txt not found
    echo Cannot proceed without dependency list
    pause
    exit /b 1
)

rem Check if virtual environment already exists
if exist "venv" (
    echo.
    echo Virtual environment already exists.
    set /p RECREATE="Do you want to recreate it? (y/n): "
    if /i "!RECREATE!"=="y" (
        echo Removing existing virtual environment...
        rmdir /s /q venv
    ) else (
        echo Keeping existing environment.
        echo Activating virtual environment...
        call venv\Scripts\activate.bat
        goto :install_deps
    )
)

echo.
echo Creating virtual environment...
python -m venv venv

if !errorlevel! neq 0 (
    echo Error: Failed to create virtual environment
    echo.
    echo Try running: python -m pip install --upgrade pip virtualenv
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

if !errorlevel! neq 0 (
    echo Error: Failed to activate virtual environment
    pause
    exit /b 1
)

:install_deps
echo.
echo Upgrading pip...
python -m pip install --upgrade pip

echo.
echo Installing dependencies from requirements.txt...
echo This may take a few minutes...
echo.

pip install -r requirements.txt

if !errorlevel! neq 0 (
    echo.
    echo Error: Failed to install some dependencies
    echo.
    echo Common issues:
    echo 1. Network connection problems
    echo 2. Missing system dependencies (e.g., Visual C++ for some packages)
    echo 3. Incompatible package versions
    echo.
    echo Try installing Visual Studio Build Tools if you see compilation errors
    pause
    exit /b 1
)

echo.
echo Installing development dependencies...
pip install pytest pytest-cov black flake8 mypy

echo.
echo ========================================
echo   Setup completed successfully!
echo ========================================
echo.
echo Virtual environment created at: backend\functions\venv
echo.
echo To activate the environment manually:
echo   cd backend\functions
echo   venv\Scripts\activate.bat
echo.
echo To start the backend server:
echo   Run win-backend-dev.bat
echo.
echo Note: You'll need to set up your Google Cloud credentials:
echo   set GOOGLE_APPLICATION_CREDENTIALS=path\to\your\service-account-key.json
echo.

rem Deactivate virtual environment
deactivate

pause
exit /b 0