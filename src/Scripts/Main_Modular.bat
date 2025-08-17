@echo off
:: Main_Modular.bat - Modularized Reality Capture Pipeline Orchestrator
:: Coordinates all processing modules for the complete workflow

setlocal enabledelayedexpansion

:: Get command line parameters
set ProjectName=%1
set S3URI=%2

:: Validate parameters
if "%ProjectName%"=="" (
    echo Error: Project name not provided.
    echo Usage: Main_Modular.bat ^<ProjectName^> ^<S3_URI^>
    echo Example: Main_Modular.bat 2025-0815-0958-scan s3://bucket/path/
    exit /b 1
)

if "%S3URI%"=="" (
    echo Error: S3 URI not provided.
    echo Usage: Main_Modular.bat ^<ProjectName^> ^<S3_URI^>
    exit /b 1
)

:: Set script directory
set SCRIPT_DIR=%~dp0

:: Load configuration
echo ==========================================
echo REALITY CAPTURE PROCESSING PIPELINE
echo ==========================================
echo Loading configuration...
call "%SCRIPT_DIR%modules\config.bat"
if %errorlevel% neq 0 (
    echo Error: Failed to load configuration
    exit /b %errorlevel%
)

:: Load paths configuration
call "%SCRIPT_DIR%settings\paths.bat"
call :ValidatePaths
if %errorlevel% neq 0 (
    echo Error: Path validation failed
    exit /b %errorlevel%
)

:: Load date/time utilities
call "%SCRIPT_DIR%modules\datetime.bat"

:: Log pipeline start
echo ==========================================
echo PROJECT INFORMATION
echo ==========================================
echo Project Name: %ProjectName%
echo S3 URI: %S3URI%
echo Start Time: %FormattedDate%
echo Root Directory: %ROOT_DIR%
echo ==========================================

:: Create project directory structure
echo Creating project directories...
if not exist "%ROOT_DIR%\rc-projects\%ProjectName%" mkdir "%ROOT_DIR%\rc-projects\%ProjectName%"
if not exist "%ROOT_DIR%\rc-projects\%ProjectName%\model" mkdir "%ROOT_DIR%\rc-projects\%ProjectName%\model"
if not exist "%ROOT_DIR%\rc-projects\%ProjectName%\metadata" mkdir "%ROOT_DIR%\rc-projects\%ProjectName%\metadata"

:: Step 1: S3 Download
echo.
echo [Step 1/5] S3 DOWNLOAD
echo ==========================================
call "%SCRIPT_DIR%modules\s3_download.bat" %ProjectName% %S3URI%
if %errorlevel% neq 0 (
    echo Error: S3 download failed
    goto :error_handler
)

:: Step 2: Background Removal
echo.
echo [Step 2/5] BACKGROUND REMOVAL
echo ==========================================
call "%SCRIPT_DIR%modules\remove_background.bat" %ProjectName%
if %errorlevel% neq 0 (
    echo Error: Background removal failed
    goto :error_handler
)

:: Step 3: Reality Capture Processing
echo.
echo [Step 3/5] REALITY CAPTURE PROCESSING
echo ==========================================
call "%SCRIPT_DIR%modules\reality_capture.bat" %ProjectName%
if %errorlevel% neq 0 (
    echo Error: Reality Capture processing failed
    goto :error_handler
)

:: Step 4: XMP Metadata Parsing
echo.
echo [Step 4/5] METADATA PARSING
echo ==========================================
call "%SCRIPT_DIR%modules\xmp_parser.bat" %ProjectName%
if %errorlevel% neq 0 (
    echo Warning: XMP parsing encountered issues but continuing...
)

:: Step 5: S3 Upload
echo.
echo [Step 5/5] S3 UPLOAD
echo ==========================================
call "%SCRIPT_DIR%modules\s3_upload.bat" %ProjectName% %S3URI%
if %errorlevel% neq 0 (
    echo Warning: S3 upload completed with warnings
)

:: Pipeline completed successfully
echo.
echo ==========================================
echo PIPELINE COMPLETED SUCCESSFULLY
echo ==========================================
echo Project: %ProjectName%
echo Duration: Started at %FormattedDate%
call "%SCRIPT_DIR%modules\datetime.bat"
echo          Completed at %FormattedDate%
echo.
echo Output Summary:
echo   - Model: %ROOT_DIR%\rc-projects\%ProjectName%\model\
echo   - Metadata: %ROOT_DIR%\rc-projects\%ProjectName%\metadata\
echo   - Reports: %ROOT_DIR%\rc-projects\%ProjectName%\*.html
echo   - S3 Location: %S3URI:Face=Scan%
echo ==========================================
echo.
echo Process completed successfully!
exit /b 0

:: Error handler
:error_handler
echo.
echo ==========================================
echo PIPELINE FAILED
echo ==========================================
echo An error occurred during processing.
echo Please check the error messages above for details.
echo.
echo Troubleshooting tips:
echo   1. Verify AWS credentials are configured
echo   2. Check S3 URI is correct and accessible
echo   3. Ensure Reality Capture is installed
echo   4. Verify Python and dependencies are installed
echo ==========================================
exit /b 1