@echo off
:: config.bat - Central configuration management
:: Loads environment variables and sets up global configuration

:: Check if .env file exists and load it
set ENV_FILE=%~dp0\..\..\..\..env
if exist "%ENV_FILE%" (
    echo Loading environment variables from .env...
    for /f "usebackq tokens=1,2 delims==" %%a in ("%ENV_FILE%") do (
        if not "%%a"=="" if not "%%b"=="" (
            set "%%a=%%b"
        )
    )
) else (
    echo Warning: .env file not found. Using default values.
)

:: Set ROOT_DIR - can be overridden by environment variable
if not defined ROOT_DIR (
    set ROOT_DIR=C:\Users\Administrator\WorkPlace\reality-capture-cli
)

:: AWS Configuration - from environment or defaults
if not defined AWS_REGION (
    set AWS_REGION=ap-northeast-1
)

:: S3 Configuration
if not defined S3_BUCKET_NAME (
    echo Warning: S3_BUCKET_NAME not defined in environment
)

:: Validate critical configurations
if not defined AWS_ACCESS_KEY_ID (
    echo Error: AWS_ACCESS_KEY_ID not found in environment variables
    echo Please configure your .env file with AWS credentials
    exit /b 1
)

if not defined AWS_SECRET_ACCESS_KEY (
    echo Error: AWS_SECRET_ACCESS_KEY not found in environment variables
    echo Please configure your .env file with AWS credentials
    exit /b 1
)

:: Export configuration status
echo Configuration loaded:
echo   ROOT_DIR: %ROOT_DIR%
echo   AWS_REGION: %AWS_REGION%
echo   S3_BUCKET: %S3_BUCKET_NAME%

:: Return success
exit /b 0