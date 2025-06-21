@echo off
setlocal enabledelayedexpansion

rem Backend Development Server for Windows
rem Starts FastAPI development server with hot reload

echo ========================================
echo   Starting Backend Development Server
echo ========================================
echo.

rem Check if we're in the scripts directory
if exist "win-backend-dev.bat" (
    cd ..
)

rem Check if Python is installed
python --version >nul 2>nul
if !errorlevel! neq 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.9 or later from https://www.python.org/
    exit /b 1
)

rem Check if backend directory exists
if not exist "backend\functions" (
    echo Error: backend\functions directory not found
    echo Make sure you're running this from the project root
    exit /b 1
)

cd backend\functions

rem Check if virtual environment exists
if not exist "venv" (
    echo Virtual environment not found!
    echo.
    echo Please run win-backend-setup.bat first to create the environment
    echo.
    pause
    exit /b 1
)

rem Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

if !errorlevel! neq 0 (
    echo Error: Failed to activate virtual environment
    echo Try running win-backend-setup.bat to recreate the environment
    exit /b 1
)

rem Check if required files exist
if not exist "start_server.py" (
    echo Error: start_server.py not found
    echo Make sure you're in the correct directory
    exit /b 1
)

rem Set environment variables
set PYTHONPATH=%cd%
set GOOGLE_APPLICATION_CREDENTIALS=path\to\your\service-account-key.json

echo.
echo Starting FastAPI development server...
echo.
echo Server will run at: http://localhost:8081
echo API documentation: http://localhost:8081/docs
echo.
echo Press Ctrl+C to stop the server
echo.

rem Check if Firebase emulator should be used
if exist "..\..\firebase.json" (
    echo Note: For full Firebase integration, you may want to use:
    echo   firebase emulators:start --only functions
    echo.
)

rem Start the development server
python start_server.py

if !errorlevel! neq 0 (
    echo.
    echo Error: Failed to start backend server
    echo.
    echo Troubleshooting:
    echo 1. Check if port 8081 is already in use
    echo 2. Verify all dependencies are installed (run win-backend-setup.bat)
    echo 3. Check for Python syntax errors in start_server.py
    echo 4. Ensure GOOGLE_APPLICATION_CREDENTIALS is set correctly
    pause
    exit /b 1
)

rem Deactivate virtual environment when done
deactivate

exit /b 0