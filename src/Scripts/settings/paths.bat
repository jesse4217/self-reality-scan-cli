@echo off
:: paths.bat - Centralized path configuration
:: Defines all directory paths used throughout the pipeline

:: Base directories
set SCRIPTS_DIR=%ROOT_DIR%\src\Scripts
set MODULES_DIR=%SCRIPTS_DIR%\modules
set SETTINGS_DIR=%ROOT_DIR%\src\Settings
set WORKFLOWS_DIR=%ROOT_DIR%\src\workflows
set UTILS_DIR=%ROOT_DIR%\src\utils
set PROJECTS_DIR=%ROOT_DIR%\rc-projects
set TEMPLATES_DIR=%ROOT_DIR%\src\ReportTemplates

:: Python workflow directories
set RMBG_DIR=%WORKFLOWS_DIR%\py-rmbg
set RMBG_INPUT_DIR=%RMBG_DIR%\input
set RMBG_OUTPUT_DIR=%RMBG_DIR%\output

:: XMP parsing directories
set XMP_PARSER_DIR=%UTILS_DIR%\xmps_to_json
set XMP_INPUT_DIR=%XMP_PARSER_DIR%\input
set XMP_OUTPUT_DIR=%XMP_PARSER_DIR%\output

:: Function to get project-specific paths
:: Usage: call :GetProjectPaths ProjectName
:GetProjectPaths
set PROJECT_NAME=%1
if "%PROJECT_NAME%"=="" exit /b 1

set PROJECT_DIR=%PROJECTS_DIR%\%PROJECT_NAME%
set PROJECT_S3_IMAGES=%PROJECT_DIR%\s3-images
set PROJECT_INPUT_IMAGES=%PROJECT_DIR%\input-images
set PROJECT_MODEL_DIR=%PROJECT_DIR%\model
set PROJECT_METADATA_DIR=%PROJECT_DIR%\metadata
set PROJECT_XMP_DIR=%PROJECT_DIR%\xmp
set PROJECT_RCPROJ=%PROJECT_DIR%\project.rcproj

exit /b 0

:: Validate critical directories exist
:ValidatePaths
set validation_failed=0

if not exist "%ROOT_DIR%" (
    echo Error: ROOT_DIR not found: %ROOT_DIR%
    set validation_failed=1
)

if not exist "%SCRIPTS_DIR%" (
    echo Error: Scripts directory not found: %SCRIPTS_DIR%
    set validation_failed=1
)

if not exist "%SETTINGS_DIR%" (
    echo Warning: Settings directory not found: %SETTINGS_DIR%
)

if not exist "%WORKFLOWS_DIR%" (
    echo Error: Workflows directory not found: %WORKFLOWS_DIR%
    set validation_failed=1
)

if %validation_failed%==1 (
    echo Path validation failed. Please check your installation.
    exit /b 1
)

echo Path configuration loaded successfully
exit /b 0