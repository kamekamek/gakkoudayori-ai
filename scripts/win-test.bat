@echo off
setlocal enabledelayedexpansion

rem Test Runner for Windows
rem Runs both frontend and backend tests

echo ========================================
echo   Running All Tests
echo ========================================
echo.

rem Check if we're in the scripts directory
if exist "win-test.bat" (
    cd ..
)

set TOTAL_ERRORS=0

rem Run Frontend Tests
echo ========================================
echo   Frontend Tests (Flutter)
echo ========================================
echo.

rem Check if Flutter is installed
where flutter >nul 2>nul
if !errorlevel! neq 0 (
    echo Warning: Flutter is not installed, skipping frontend tests
    echo.
    set /a TOTAL_ERRORS+=1
) else (
    if exist "frontend" (
        cd frontend
        
        echo Running Flutter analyzer...
        flutter analyze
        if !errorlevel! neq 0 (
            echo Flutter analyze found issues!
            set /a TOTAL_ERRORS+=1
        ) else (
            echo Flutter analyze passed!
        )
        
        echo.
        echo Running Flutter tests...
        flutter test
        if !errorlevel! neq 0 (
            echo Flutter tests failed!
            set /a TOTAL_ERRORS+=1
        ) else (
            echo Flutter tests passed!
        )
        
        cd ..
    ) else (
        echo Error: frontend directory not found
        set /a TOTAL_ERRORS+=1
    )
)

echo.
echo ========================================
echo   Backend Tests (Python)
echo ========================================
echo.

rem Check if Python is installed
python --version >nul 2>nul
if !errorlevel! neq 0 (
    echo Warning: Python is not installed, skipping backend tests
    echo.
    set /a TOTAL_ERRORS+=1
) else (
    if exist "backend\functions" (
        cd backend\functions
        
        rem Check if virtual environment exists
        if not exist "venv" (
            echo Error: Virtual environment not found
            echo Please run win-backend-setup.bat first
            set /a TOTAL_ERRORS+=1
        ) else (
            rem Activate virtual environment
            call venv\Scripts\activate.bat
            
            echo Running flake8 linter...
            flake8 . --exclude=venv,__pycache__ --max-line-length=100
            if !errorlevel! neq 0 (
                echo Flake8 found style issues!
                set /a TOTAL_ERRORS+=1
            ) else (
                echo Flake8 passed!
            )
            
            echo.
            echo Running black formatter check...
            black --check . --exclude="venv|__pycache__"
            if !errorlevel! neq 0 (
                echo Black found formatting issues!
                echo Run 'black .' to fix them
                set /a TOTAL_ERRORS+=1
            ) else (
                echo Black formatting check passed!
            )
            
            echo.
            echo Running pytest...
            pytest -v
            if !errorlevel! neq 0 (
                echo Pytest tests failed!
                set /a TOTAL_ERRORS+=1
            ) else (
                echo Pytest tests passed!
            )
            
            rem Deactivate virtual environment
            deactivate
        )
        
        cd ..\..  
    ) else (
        echo Error: backend\functions directory not found
        set /a TOTAL_ERRORS+=1
    )
)

echo.
echo ========================================
echo   Test Summary
echo ========================================
echo.

if !TOTAL_ERRORS! equ 0 (
    echo All tests passed successfully!
    echo.
    exit /b 0
) else (
    echo Total errors found: !TOTAL_ERRORS!
    echo.
    echo Please fix the issues above before committing.
    echo.
    pause
    exit /b 1
)