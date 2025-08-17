@echo off
:: reality_capture.bat - Reality Capture processing module
:: Handles all Reality Capture processing operations

:: Parameter
set ProjectName=%1

:: Validate parameter
if "%ProjectName%"=="" (
    echo Error: Project name not provided.
    echo Usage: reality_capture.bat ^<ProjectName^>
    exit /b 1
)

:: Load RC settings
call "%~dp0\..\settings\rc_settings.bat"
if %errorlevel% neq 0 (
    echo Error: Failed to load Reality Capture settings
    exit /b %errorlevel%
)

:: Load Helper.bat for markers configuration
call "%~dp0\..\Helper.bat"

:: Set project-specific paths
set RC_INPUT_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\input-images
set OutputDir=%ROOT_DIR%\rc-projects\%ProjectName%

:: Extract model name from project name (remove date prefix)
set ModelName=%ProjectName:*-=%

:: Set export paths
set ModelExportDir=%OutputDir%\model\%ModelName%.stl
set PointCloudExportFile=%OutputDir%\model\point_cloud.ply

:: Create model directory if it doesn't exist
if not exist "%OutputDir%\model" mkdir "%OutputDir%\model"

:: Set report output paths
set outputSelectedComponentsTiePointsStats=%OutputDir%\SelectedComponentsTiePointsStats.html
set outputAlignmentView=%OutputDir%\AlignmentView.html
set outputComponentAccuracyReport=%OutputDir%\ComponentAccuracyReport.html
set outputMisalignment=%OutputDir%\Misalignment.html
set outputOverview=%OutputDir%\Overview.html
set outputSelectedComponent=%OutputDir%\SelectedComponent.html
set outputSelectedModel=%OutputDir%\SelectedModel.html

:: Log start
echo ==========================================
echo Starting Reality Capture Processing
echo ==========================================
echo Project: %ProjectName%
echo Input: %RC_INPUT_DIR%
echo Model Name: %ModelName%
echo ==========================================

:: Check if input directory has files
if not exist "%RC_INPUT_DIR%\*.*" (
    echo Error: No input images found in %RC_INPUT_DIR%
    echo Please ensure background removal completed successfully
    exit /b 1
)

:: Run Reality Capture with all processing steps
echo Launching Reality Capture...
echo This may take several minutes depending on the number of images...

%RealityCaptureExe% -addFolder "%RC_INPUT_DIR%" ^
-printProgress ^
-setProjectCoordinateSystem Local:1 ^
-detectMarkers "%FourMarkers%" ^
-importGroundControlPoints "%GroundControlPoints%" "%SetGCPs%" ^
-align ^
-selectMaximalComponent ^
-setReconstructionRegionAuto ^
-setReconstructionRegion "%RegionBox%" ^
-calculateNormalModel ^
-simplify %SimplifyParams% ^
-renameSelectedModel "%ModelName%" ^
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

:: Check for errors
if %errorlevel% neq 0 (
    echo Error: Reality Capture processing failed with error code %errorlevel%
    exit /b %errorlevel%
)

:: Verify outputs
set success=1
if not exist "%ModelExportDir%" (
    echo Warning: Model file not created: %ModelExportDir%
    set success=0
)
if not exist "%PointCloudExportFile%" (
    echo Warning: Point cloud file not created: %PointCloudExportFile%
    set success=0
)
if not exist "%OutputDir%\project.rcproj" (
    echo Warning: Project file not saved: %OutputDir%\project.rcproj%
    set success=0
)

if %success%==1 (
    echo Reality Capture processing completed successfully!
    echo Model: %ModelExportDir%
    echo Point Cloud: %PointCloudExportFile%
    echo Project: %OutputDir%\project.rcproj
) else (
    echo Reality Capture processing completed with warnings
)

echo ==========================================

:: Return success/warning
exit /b 0