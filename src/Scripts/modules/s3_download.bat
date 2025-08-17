@echo off
:: s3_download.bat - S3 download module
:: Downloads project files from S3 to local directory

:: Parameters
set ProjectName=%1
set S3URI=%2

:: Validate parameters
if "%ProjectName%"=="" (
    echo Error: Project name not provided.
    echo Usage: s3_download.bat ^<ProjectName^> ^<S3_URI^>
    exit /b 1
)

if "%S3URI%"=="" (
    echo Error: S3 URI not provided.
    echo Usage: s3_download.bat ^<ProjectName^> ^<S3_URI^>
    exit /b 1
)

:: Set download directory
set DOWNLOAD_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\s3-images

:: Create directory if it doesn't exist
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

:: Log download start
echo ==========================================
echo Starting S3 Download
echo ==========================================
echo Project: %ProjectName%
echo S3 URI: %S3URI%
echo Target: %DOWNLOAD_DIR%
echo ==========================================

:: Perform S3 download with error handling
echo Downloading from S3...
aws s3 cp %S3URI% "%DOWNLOAD_DIR%" --recursive

:: Check for errors
if %errorlevel% neq 0 (
    echo Error: S3 download failed with error code %errorlevel%
    echo Please check:
    echo   1. AWS credentials are configured
    echo   2. S3 URI is correct and accessible
    echo   3. Network connection is stable
    exit /b %errorlevel%
)

:: Count downloaded files
set /a filecount=0
for /f %%A in ('dir /b "%DOWNLOAD_DIR%\*" 2^>nul ^| find /c /v ""') do set filecount=%%A

echo S3 Download completed successfully!
echo Downloaded %filecount% files to %DOWNLOAD_DIR%
echo ==========================================

:: Return success
exit /b 0