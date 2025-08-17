@echo off
:: remove_background.bat - Background removal module
:: Processes images to remove backgrounds using Python script

:: Parameter
set ProjectName=%1

:: Validate parameter
if "%ProjectName%"=="" (
    echo Error: Project name not provided.
    echo Usage: remove_background.bat ^<ProjectName^>
    exit /b 1
)

:: Set directories
set SOURCE_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\s3-images
set RMBG_INPUT_DIR=%ROOT_DIR%\src\workflows\py-rmbg\input
set RMBG_OUTPUT_DIR=%ROOT_DIR%\src\workflows\py-rmbg\output
set RC_INPUT_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\input-images

:: Log start
echo ==========================================
echo Starting Background Removal
echo ==========================================
echo Project: %ProjectName%
echo Source: %SOURCE_DIR%
echo ==========================================

:: Create necessary directories
if not exist "%RMBG_INPUT_DIR%" mkdir "%RMBG_INPUT_DIR%"
if not exist "%RC_INPUT_DIR%" mkdir "%RC_INPUT_DIR%"

:: Check if source directory has files
if not exist "%SOURCE_DIR%\*.*" (
    echo Error: No files found in source directory
    echo Please ensure S3 download completed successfully
    exit /b 1
)

:: Copy images to background removal input directory
echo Copying images to background removal workspace...
xcopy "%SOURCE_DIR%\*.*" "%RMBG_INPUT_DIR%" /I /Y >nul
if %errorlevel% neq 0 (
    echo Error: Failed to copy images to processing directory
    exit /b %errorlevel%
)

:: Run Python background removal script
echo Processing images to remove backgrounds...
python "%ROOT_DIR%\src\workflows\py-rmbg\remover.py"
if %errorlevel% neq 0 (
    echo Error: Background removal script failed
    echo Please check Python installation and dependencies
    exit /b %errorlevel%
)

:: Clean up input directory
echo Cleaning up temporary input files...
del /Q "%RMBG_INPUT_DIR%\*" >nul

:: Move processed images to RC project directory
echo Moving processed images to Reality Capture workspace...
if exist "%RMBG_OUTPUT_DIR%\*.*" (
    xcopy "%RMBG_OUTPUT_DIR%\*.*" "%RC_INPUT_DIR%" /I /Y >nul
    if %errorlevel% neq 0 (
        echo Warning: Failed to move some processed images
    )
    
    :: Clean up output directory
    del /Q "%RMBG_OUTPUT_DIR%\*" >nul
) else (
    echo Warning: No processed images found in output directory
)

:: Count processed files
set /a filecount=0
for /f %%A in ('dir /b "%RC_INPUT_DIR%\*" 2^>nul ^| find /c /v ""') do set filecount=%%A

echo Background removal completed!
echo Processed %filecount% images
echo Output location: %RC_INPUT_DIR%
echo ==========================================

:: Return success
exit /b 0