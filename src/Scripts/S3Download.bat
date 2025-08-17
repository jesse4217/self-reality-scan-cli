@echo off
::================================Variables================================
set ROOT_DIR=C:\Users\jesse\Documents\RealityCapture\cmd-snippet
set /p ProjectName="Enter the name of your RC project: "
set /p s3uri="Enter the S3 URI: "
::================================Variables================================

aws s3 cp %s3uri% "%ROOT_DIR%\rc-projects\%ProjectName%\s3-images" --recursive

if %errorlevel% neq 0 (
    echo Error: AWS S3 download failed.
    exit /b 1
) else (
    echo S3 Downlaod completed successfully.
)