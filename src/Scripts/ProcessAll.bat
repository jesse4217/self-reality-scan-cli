::================================Variables================================
set ROOT_DIR=C:\Users\jesse\Documents\RealityCapture\cmd-snippet
set /p ProjectName="Enter the name of your RC project: "
call %ROOT_DIR%\src\Scripts\Helper.bat

::================================Variables================================

::set Project="C:\Users\jiang\Jesse\RealityCapture\cli-output\cli-saved-project.rcproj"
set FourMarkers=%ROOT_DIR%\src\Settings\DetectFourMarkers.xml
set GroundControlPoints=%ROOT_DIR%\src\Settings\GroundControlPoints.csv
set SetGCPs=%ROOT_DIR%\src\Settings\SetGroundControlPoints.xml
set RegionBox=%ROOT_DIR%\src\Settings\20250610-ReconstructionRegion.rcbox
set ModelExportSetting=%ROOT_DIR%\src\Settings\ModelExportSetting.xml
set AlignmentSetting = %ROOT_DIR%\src\Settings\AlignmentSetting.xml
set MeshModelSetting = %ROOT_DIR%\src\Settings\MeshModelSetting.xml

set ModelExportDir=%ROOT_DIR%\rc-projects\%ProjectName%\model\model.stl

set ModelName=model

set OutputDir=%ROOT_DIR%\rc-projects\%ProjectName%

echo Reality Capture Processing...
%RealityCaptureExe% -addFolder "%RC_PROJECT_INPUT_DIR%" ^
-printProgress ^
-setProjectCoordinateSystem Local:1 ^
-detectMarkers "%FourMarkers%" ^
-importGroundControlPoints "%GroundControlPoints%" "%SetGCPs%" ^
-align 
-setReconstructionRegion "%RegionBox%" ^
-calculatePreviewModel ^
-renameSelectedModel "%ModelName%" ^
-exportModel "%ModelName%" "%ModelExportDir%" ^
-save "%OutputDir%\project.rcproj" ^
-quit

echo Process Completed!