@echo off
:: xmp_parser.bat - XMP file parsing module
:: Converts XMP metadata files to JSON format

:: Parameter
set ProjectName=%1

:: Validate parameter
if "%ProjectName%"=="" (
    echo Error: Project name not provided.
    echo Usage: xmp_parser.bat ^<ProjectName^>
    exit /b 1
)

:: Set directories
set XMP_SOURCE_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\input-images
set PARSE_INPUT_DIR=%ROOT_DIR%\src\utils\xmps_to_json\input
set PARSE_OUTPUT_DIR=%ROOT_DIR%\src\utils\xmps_to_json\output
set JSON_SAVE_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\metadata

:: Log start
echo ==========================================
echo Starting XMP to JSON Parsing
echo ==========================================
echo Project: %ProjectName%
echo Source: %XMP_SOURCE_DIR%
echo ==========================================

:: Create necessary directories
if not exist "%PARSE_INPUT_DIR%" mkdir "%PARSE_INPUT_DIR%"
if not exist "%JSON_SAVE_DIR%" mkdir "%JSON_SAVE_DIR%"

:: Check if source directory has XMP files
dir /b "%XMP_SOURCE_DIR%\*.xmp" >nul 2>&1
if %errorlevel% neq 0 (
    echo Warning: No XMP files found in %XMP_SOURCE_DIR%
    echo Checking for other metadata files...
    
    :: Check for any files to process
    if not exist "%XMP_SOURCE_DIR%\*.*" (
        echo Error: No files found in source directory
        exit /b 1
    )
)

:: Copy files to parsing input directory
echo Copying files to parsing workspace...
xcopy "%XMP_SOURCE_DIR%\*.*" "%PARSE_INPUT_DIR%" /I /Y >nul
if %errorlevel% neq 0 (
    echo Error: Failed to copy files to parsing directory
    exit /b %errorlevel%
)

:: Run Python XMP parsing script
echo Parsing XMP metadata to JSON...
python "%ROOT_DIR%\src\utils\xmps_to_json\parse_xmps_to_json.py"
if %errorlevel% neq 0 (
    echo Error: XMP parsing script failed
    echo Please check Python installation and script configuration
    exit /b %errorlevel%
)

:: Clean up input directory
echo Cleaning up temporary files...
del /Q "%PARSE_INPUT_DIR%\*" >nul

:: Move parsed JSON files to project metadata directory
echo Moving parsed JSON files...
if exist "%PARSE_OUTPUT_DIR%\*.json" (
    xcopy "%PARSE_OUTPUT_DIR%\*.json" "%JSON_SAVE_DIR%" /I /Y >nul
    if %errorlevel% neq 0 (
        echo Warning: Failed to move some JSON files
    )
) else (
    echo Warning: No JSON files generated
)

:: Move any other output files
if exist "%PARSE_OUTPUT_DIR%\*.*" (
    xcopy "%PARSE_OUTPUT_DIR%\*.*" "%JSON_SAVE_DIR%" /I /Y >nul
)

:: Clean up output directory
del /Q "%PARSE_OUTPUT_DIR%\*" >nul 2>nul

:: Check results
if exist "%JSON_SAVE_DIR%\xmp_data.json" (
    echo XMP parsing completed successfully!
    echo Main output: %JSON_SAVE_DIR%\xmp_data.json
) else (
    echo Warning: xmp_data.json not found in output
    
    :: Count any JSON files created
    set /a jsoncount=0
    for /f %%A in ('dir /b "%JSON_SAVE_DIR%\*.json" 2^>nul ^| find /c /v ""') do set jsoncount=%%A
    
    if %jsoncount% gtr 0 (
        echo Created %jsoncount% JSON files in %JSON_SAVE_DIR%
    ) else (
        echo Warning: No JSON files were created
    )
)

echo ==========================================

:: Return success (even with warnings)
exit /b 0