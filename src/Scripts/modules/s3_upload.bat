@echo off
:: s3_upload.bat - S3 upload module
:: Uploads processed results back to S3

:: Parameters
set ProjectName=%1
set S3URI=%2

:: Validate parameters
if "%ProjectName%"=="" (
    echo Error: Project name not provided.
    echo Usage: s3_upload.bat ^<ProjectName^> ^<S3_URI^>
    exit /b 1
)

if "%S3URI%"=="" (
    echo Error: S3 URI not provided.
    echo Usage: s3_upload.bat ^<ProjectName^> ^<S3_URI^>
    exit /b 1
)

:: Transform S3 URI (replace Face/Head with Scan)
set UPLOAD_URI=%S3URI:Face=Scan%
set UPLOAD_URI=%UPLOAD_URI:Head=Scan%

:: Set file paths
set ModelName=%ProjectName:*-=%
set ModelExportDir=%ROOT_DIR%\rc-projects\%ProjectName%\model\%ModelName%.stl
set PointCloudExportFile=%ROOT_DIR%\rc-projects\%ProjectName%\model\point_cloud.ply
set JSON_FILE=%ROOT_DIR%\rc-projects\%ProjectName%\metadata\xmp_data.json

:: Log start
echo ==========================================
echo Starting S3 Upload
echo ==========================================
echo Project: %ProjectName%
echo Upload URI: %UPLOAD_URI%
echo ==========================================

:: Initialize upload status
set upload_success=1
set uploads_completed=0
set uploads_failed=0

:: Upload model file
if exist "%ModelExportDir%" (
    echo Uploading model: %ModelName%.stl
    aws s3 cp "%ModelExportDir%" %UPLOAD_URI%
    if %errorlevel% equ 0 (
        echo   Model upload completed successfully
        set /a uploads_completed+=1
    ) else (
        echo   Error: Model upload failed with error code %errorlevel%
        set upload_success=0
        set /a uploads_failed+=1
    )
) else (
    echo Warning: Model file not found: %ModelExportDir%
    set upload_success=0
)

:: Upload point cloud file
if exist "%PointCloudExportFile%" (
    echo Uploading point cloud: point_cloud.ply
    aws s3 cp "%PointCloudExportFile%" %UPLOAD_URI%
    if %errorlevel% equ 0 (
        echo   Point cloud upload completed successfully
        set /a uploads_completed+=1
    ) else (
        echo   Error: Point cloud upload failed with error code %errorlevel%
        set upload_success=0
        set /a uploads_failed+=1
    )
) else (
    echo Warning: Point cloud file not found: %PointCloudExportFile%
    set upload_success=0
)

:: Upload JSON metadata file
if exist "%JSON_FILE%" (
    echo Uploading metadata: xmp_data.json
    aws s3 cp "%JSON_FILE%" %UPLOAD_URI%
    if %errorlevel% equ 0 (
        echo   Metadata upload completed successfully
        set /a uploads_completed+=1
    ) else (
        echo   Error: Metadata upload failed with error code %errorlevel%
        set upload_success=0
        set /a uploads_failed+=1
    )
) else (
    echo Warning: Metadata file not found: %JSON_FILE%
    echo Checking for alternative JSON files...
    
    :: Try to upload any JSON file in metadata directory
    for %%f in ("%ROOT_DIR%\rc-projects\%ProjectName%\metadata\*.json") do (
        echo Uploading: %%~nxf
        aws s3 cp "%%f" %UPLOAD_URI%
        if !errorlevel! equ 0 (
            set /a uploads_completed+=1
        ) else (
            set /a uploads_failed+=1
        )
    )
)

:: Upload reports if they exist
set REPORTS_DIR=%ROOT_DIR%\rc-projects\%ProjectName%
if exist "%REPORTS_DIR%\*.html" (
    echo Uploading HTML reports...
    for %%f in ("%REPORTS_DIR%\*.html") do (
        echo   Uploading report: %%~nxf
        aws s3 cp "%%f" %UPLOAD_URI%reports/ >nul 2>&1
    )
)

:: Summary
echo ==========================================
echo Upload Summary:
echo   Completed: %uploads_completed% files
if %uploads_failed% gtr 0 (
    echo   Failed: %uploads_failed% files
)

if %upload_success%==1 (
    if %uploads_completed% gtr 0 (
        echo S3 upload completed successfully!
    ) else (
        echo Warning: No files were uploaded
        exit /b 1
    )
) else (
    if %uploads_completed% gtr 0 (
        echo S3 upload completed with warnings
    ) else (
        echo Error: S3 upload failed - no files uploaded
        exit /b 1
    )
)

echo S3 Location: %UPLOAD_URI%
echo ==========================================

:: Return status
if %upload_success%==1 (
    exit /b 0
) else (
    exit /b 1
)