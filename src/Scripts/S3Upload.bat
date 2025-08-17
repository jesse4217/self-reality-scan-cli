@echo off
::================================Variables================================
set ROOT_DIR=C:\Users\jesse\Documents\RealityCapture\cmd-snippet
set /p ProjectName="Enter the name of your RC project: "
set /p s3uri="Enter the S3 URI: "
::================================Variables================================
::%ROOT_DIR%\rc-projects\%ProjectName%\model (only folder upload available)

aws s3 cp %ROOT_DIR%\rc-projects\%ProjectName%\model %s3uri% --recursive

if %errorlevel% neq 0 (
    echo Error: AWS S3 upload failed.
    exit /b 1
) else (
    echo S3 Upload completed successfully.
)