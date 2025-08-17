@REM @echo off
call helper.bat

set ROOT_DIR=C:\Users\Administrator\WorkPlace\reality-capture-cli
echo %ROOT_DIR%
::================================START================================
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
     set dow=%%i
     set month=%%j
     set day=%%k
     set year=%%l
)
FOR /F "TOKENS=1 DELIMS=:" %%A IN ('TIME/T') DO SET HH=%%A
FOR /F "TOKENS=2 DELIMS=:" %%A IN ('TIME/T') DO SET MM=%%A
set Date=%year%-%dow%-%month%-%day%-%HH%-%MM%
echo PROJECT STARTED: %Date%


@REM ::================================S3 Download================================
@REM set /p ProjectName="Enter the name of your RC project: "
@REM set /p s3uri="Enter the S3 URI: "
@REM aws s3 cp %s3uri% "%ROOT_DIR%\rc-projects\%ProjectName%\s3-images" --recursive
@REM echo S3 Download completed.
@REM echo Moving S3 Downloaded Images to the Python Workplace...
::================================S3 Download================================
set ProjectName=%1
set s3uri=%2

if "%ProjectName%"=="" (
    echo Error: Project name not provided.
    echo Usage: Main.bat ^<ProjectName^> ^<S3_URI^>
    exit /b 1
)

if "%s3uri%"=="" (
    echo Error: S3 URI not provided.
    echo Usage: Main.bat ^<ProjectName^> ^<S3_URI^>
    exit /b 1
)

echo Downloading from S3...
aws s3 cp %s3uri% "%ROOT_DIR%\rc-projects\%ProjectName%\s3-images" --recursive
if %errorlevel% neq 0 (
    echo Error: S3 download failed.
    exit /b 1
)

echo S3 Download completed.
echo Moving S3 Downloaded Images to the Python Workplace...



::================================Remove Background================================
set SOURCE_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\s3-images
set DESTINATION_DIR=%ROOT_DIR%\src\workflows\py-rmbg\input

if not exist "%DESTINATION_DIR%\" mkdir "%DESTINATION_DIR%"

echo Source: "%SOURCE_DIR%"
echo Destination: "%DESTINATION_DIR%"

xcopy "%SOURCE_DIR%\*.*" "%DESTINATION_DIR%" /I /Y

@REM echo Start Removing Image Background
@REM python "%ROOT_DIR%\src\workflows\py-rmbg\remover.py"
@REM echo Removing Completed!

@REM echo Deleting all files from: %DESTINATION_DIR%
@REM del /Q "%DESTINATION_DIR%\*"

@REM set OUTPUT_DIR=%ROOT_DIR%\src\workflows\py-rmbg\output

set RC_PROJECT_INPUT_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\input-images

if not exist "%RC_PROJECT_INPUT_DIR%\" mkdir "%RC_PROJECT_INPUT_DIR%"
xcopy "%DESTINATION_DIR%\*.*" "%RC_PROJECT_INPUT_DIR%" /I /Y
del /Q "%DESTINATION_DIR%\*"

echo Move Background Removed Images to Reality Capture Workplace.

::================================Reality Capture================================
call %ROOT_DIR%\src\Scripts\Helper.bat

::set Project="C:\Users\jiang\Jesse\RealityCapture\cli-output\cli-saved-project.rcproj"
set FourMarkers=%ROOT_DIR%\src\Settings\DetectFourMarkers.xml
set GroundControlPoints=%ROOT_DIR%\src\Settings\GroundControlPoints.csv
set SetGCPs=%ROOT_DIR%\src\Settings\SetGroundControlPoints.xml
set RegionBox=%ROOT_DIR%\src\Settings\20250814-ReconstructionRegion.rcbox
set ModelExportSetting=%ROOT_DIR%\src\Settings\model-export-setting.xml
set AlignmentSetting=%ROOT_DIR%\src\Settings\AlignmentSetting.xml
set XMPExportParams=%ROOT_DIR%\src\Settings\XMPExportParams.xml
set MeshModelSetting = %ROOT_DIR%\src\Settings\MeshModelSetting.xml
set PointCloudExportSetting=%ROOT_DIR%\src\Settings\PointCloudExportSetting.xml

:: set the value of triangles to which high-poly model will be simplified
set SimplifyParams=%ROOT_DIR%\src\Settings\20250613SimplifyParams.xml
set SmoothingParams=%ROOT_DIR%\src\Settings\20250613SmoothingParams.xml
set ModelName=%ProjectName:*-=%

set ModelExportDir=%ROOT_DIR%\rc-projects\%ProjectName%\model\%ModelName%.stl
:: export point cloud
set PointCloudExportFile=%ROOT_DIR%\rc-projects\%ProjectName%\model\point_cloud.ply

set OutputDir=%ROOT_DIR%\rc-projects\%ProjectName%

::Reality Capture Reports::
set outputSelectedComponentsTiePointsStats=%ROOT_DIR%\rc-projects\%ProjectName%\SelectedComponentsTiePointsStats.html
set templateSelectedComponentsTiePointsStats=%ROOT_DIR%\src\ReportTemplates\SelectedComponentsTiePointsStats.html

set outputAlignmentView=%ROOT_DIR%\rc-projects\%ProjectName%\AlignmentView.html
set templateAlignmentView=%ROOT_DIR%\src\ReportTemplates\AlignmentView.html

set outputComponentAccuracyReport=%ROOT_DIR%\rc-projects\%ProjectName%\ComponentAccuracyReport.html
set templateComponentAccuracyReport=%ROOT_DIR%\src\ReportTemplates\ComponentAccuracyReport.html

set outputMisalignment=%ROOT_DIR%\rc-projects\%ProjectName%\Misalignment.html
set templateMisalignment=%ROOT_DIR%\src\ReportTemplates\Misalignment.html

set outputOverview=%ROOT_DIR%\rc-projects\%ProjectName%\Overview.html
set templateOverview=%ROOT_DIR%\src\ReportTemplates\Overview.html

set outputSelectedComponent=%ROOT_DIR%\rc-projects\%ProjectName%\SelectedComponent.html
set templateSelectedComponent=%ROOT_DIR%\src\ReportTemplates\SelectedComponent.html

set outputSelectedModel=%ROOT_DIR%\rc-projects\%ProjectName%\SelectedModel.html
set templateSelectedModel=%ROOT_DIR%\src\ReportTemplates\SelectedModel.html



echo Reality Capture Processing...
%RealityCaptureExe% -addFolder "%RC_PROJECT_INPUT_DIR%" ^
-printProgress ^
-setProjectCoordinateSystem Local:1 ^
-detectMarkers "%FourMarkers%" ^
-importGroundControlPoints "%GroundControlPoints%" "%SetGCPs%" ^
-align ^
-mergeComponents ^
-selectMaximalComponent ^
-setReconstructionRegion "%RegionBox%" ^
-calculateNormalModel ^
-renameSelectedModel "%ModelName%" ^
-simplify %SimplifyParams% ^
-smooth %SmoothingParams% ^
-exportModel "%ModelName%" "%ModelExportDir%" ^
-exportSparsePointCloud "%PointCloudExportFile%" ^
-exportXMP "%XMPExportParams%" ^
-exportReport "%outputSelectedComponentsTiePointsStats%" "%templateSelectedComponentsTiePointsStats%" ^
-exportReport "%outputSelectedComponent%" "%templateSelectedComponent%" ^
-exportReport "%outputOverview%" "%templateOverview%" ^
-exportReport "%outputAlignmentView%" "%templateAlignmentView%" ^
-exportReport "%outputMisalignment%" "%templateMisalignment%" ^
-exportReport "%outputSelectedModel%" "%templateSelectedModel%" ^
-save "%OutputDir%\project.rcproj" ^
-quit


::================================Parse XMP Files================================
set XMP_FILES_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\input-images

set PARSE_INPUT_DIR=%ROOT_DIR%\src\utils\xmps_to_json\input

set JSON_SAVE_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\metadata

if not exist "%PARSE_INPUT_DIR%\" mkdir "%PARSE_INPUT_DIR%"

echo Source: "%XMP_FILES_DIR%"
echo Destination: "%PARSE_INPUT_DIR%"

xcopy "%XMP_FILES_DIR%\*.*" "%PARSE_INPUT_DIR%" /I /Y

echo Start Parsing XMP files to json...
python "%ROOT_DIR%\src\utils\xmps_to_json\parse_xmps_to_json.py"
echo Parsing Completed!

echo Deleting all files from: %PARSE_INPUT_DIR%
del /Q "%PARSE_INPUT_DIR%\*"

set PRASE_OUTPUT_DIR=%ROOT_DIR%\src\utils\xmps_to_json\output

if not exist "%JSON_SAVE_DIR%\" mkdir "%JSON_SAVE_DIR%"
xcopy "%PRASE_OUTPUT_DIR%\*.*" "%JSON_SAVE_DIR%" /I /Y
del /Q "%PRASE_OUTPUT_DIR%\*"

echo Moved JSON File!
@REM if not exist "%ROOT_DIR%\rc-projects\%ProjectName%\xmp\" mkdir "%ROOT_DIR%\rc-projects\%ProjectName%\xmp\"
@REM move /Y "%JSON_SAVE_DIR%\*.xmp" "%ROOT_DIR%\rc-projects\%ProjectName%\xmp\"


::================================S3 Upload================================
set UPLOAD_URI=%s3uri:Face=Scan%
set UPLOAD_URI=%UPLOAD_URI:Head=Scan%

echo Uploading model
aws s3 cp "%ModelExportDir%" %UPLOAD_URI% 
echo Uploading model completed.

echo Uploading point cloud
aws s3 cp "%PointCloudExportFile%" %UPLOAD_URI% 
echo Uploading point cloud completed.

echo Uploading xmp_data.json
aws s3 cp "%JSON_SAVE_DIR%\xmp_data.json" %UPLOAD_URI%
echo Uploading xmp_data.json completed.

echo Process Completed!
@REM pause

