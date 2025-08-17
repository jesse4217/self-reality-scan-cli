@echo off
:: rc_settings.bat - Reality Capture settings configuration
:: Centralizes all RC settings and paths

:: Reality Capture executable path
if not defined RealityCaptureExe (
    set RealityCaptureExe="C:\Program Files\Epic Games\RealityScan_2.0\RealityScan.exe"
)

:: Settings files base directory
set SETTINGS_DIR=%ROOT_DIR%\src\Settings

:: RC Setting Files
set FourMarkers=%SETTINGS_DIR%\DetectFourMarkers.xml
set GroundControlPoints=%SETTINGS_DIR%\GroundControlPoints.csv
set SetGCPs=%SETTINGS_DIR%\SetGroundControlPoints.xml
set RegionBox=%SETTINGS_DIR%\20250814-ReconstructionRegion.rcbox
set ModelExportSetting=%SETTINGS_DIR%\model-export-setting.xml
set AlignmentSetting=%SETTINGS_DIR%\AlignmentSetting.xml
set XMPExportParams=%SETTINGS_DIR%\XMPExportParams.xml
set MeshModelSetting=%SETTINGS_DIR%\MeshModelSetting.xml
set PointCloudExportSetting=%SETTINGS_DIR%\PointCloudExportSetting.xml
set SimplifyParams=%SETTINGS_DIR%\SimplifyParams.xml

:: Report Templates base directory
set TEMPLATES_DIR=%ROOT_DIR%\src\ReportTemplates

:: Report Template Files
set templateSelectedComponentsTiePointsStats=%TEMPLATES_DIR%\SelectedComponentsTiePointsStats.html
set templateAlignmentView=%TEMPLATES_DIR%\AlignmentView.html
set templateComponentAccuracyReport=%TEMPLATES_DIR%\ComponentAccuracyReport.html
set templateMisalignment=%TEMPLATES_DIR%\Misalignment.html
set templateOverview=%TEMPLATES_DIR%\Overview.html
set templateSelectedComponent=%TEMPLATES_DIR%\SelectedComponent.html
set templateSelectedModel=%TEMPLATES_DIR%\SelectedModel.html

:: Validate critical files exist
if not exist "%RealityCaptureExe%" (
    echo Warning: RealityCapture executable not found at %RealityCaptureExe%
    echo Please update the path in rc_settings.bat or set RealityCaptureExe environment variable
)

if not exist "%SETTINGS_DIR%" (
    echo Warning: Settings directory not found at %SETTINGS_DIR%
)

if not exist "%TEMPLATES_DIR%" (
    echo Warning: Report templates directory not found at %TEMPLATES_DIR%
)

echo Reality Capture settings loaded successfully
exit /b 0