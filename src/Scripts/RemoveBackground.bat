::================================Variables================================
set ROOT_DIR=C:\Users\jesse\Documents\RealityCapture\cmd-snippet
set /p ProjectName="Enter the name of your RC project: "
::================================Variables================================

set SOURCE_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\s3-images
set DESTINATION_DIR=%ROOT_DIR%\src\workflows\py-rmbg\input

if not exist "%DESTINATION_DIR%\" mkdir "%DESTINATION_DIR%"

echo Source: "%SOURCE_DIR%"
echo Destination: "%DESTINATION_DIR%"

xcopy "%SOURCE_DIR%\*.*" "%DESTINATION_DIR%" /I /Y

echo Start Removing Image Background
python "%ROOT_DIR%\src\workflows\py-rmbg\remove_background.py"
echo Removing Completed!

echo Deleting all files from: %DESTINATION_DIR%
del /Q "%DESTINATION_DIR%\*"

set OUTPUT_DIR=%ROOT_DIR%\src\workflows\py-rmbg\output
set RC_PROJECT_INPUT_DIR=%ROOT_DIR%\rc-projects\%ProjectName%\input-images

if not exist "%RC_PROJECT_INPUT_DIR%\" mkdir "%RC_PROJECT_INPUT_DIR%"
xcopy "%OUTPUT_DIR%\*.*" "%RC_PROJECT_INPUT_DIR%" /I /Y
del /Q "%OUTPUT_DIR%\*"

echo Move Background Removed Images to Reality Capture Workplace.
