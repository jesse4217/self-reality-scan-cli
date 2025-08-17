from urllib.parse import unquote
import datetime
import subprocess
import os
import re
import boto3

from ..config.setup import s3_client
from ..config.setup import S3_BUCKET_NAME

def extract_s3_path(s3_uri):
    """
    Extract the path starting from 'public/testUsers/' from an S3 URI.

    :param s3_uri: The full S3 URI
    :return: The extracted path
    """
    # Split the URI by '/'
    parts = s3_uri.split('/')

    # Find the index of 'public'
    try:
        public_index = parts.index('public')
    except ValueError:
        raise ValueError("The S3 URI does not contain 'public' in the path")

    # Join the parts from 'public' onwards
    extracted_path = '/'.join(parts[public_index:])

    return extracted_path

def upload_file_to_s3(s3_client, s3_bucket_dir, local_file_path, s3_file_name):
    try:
        # Upload the file
        # s3_client.upload_file('/tmp/hello.txt', 'mybucket', 'hello.txt')
        s3_client.upload_file(local_file_path, s3_bucket_dir, s3_file_name)
        print(f"s3_bucket_dir:{s3_bucket_dir}")
        print(f"local_file_path:{local_file_path}")
        print(f"s3_file_name:{s3_file_name}")
        return True
    except Exception as e:
        print(f"Error uploading file to S3: {e}")
        return False
    
def remove_filename_from_s3uri(s3uri):
    # Split the S3 URI into bucket and key parts
    bucket_part, key_part = s3uri.split('/', 3)[0:3], s3uri.split('/', 3)[3]
    
    # Remove the filename from the key part
    key_without_filename = os.path.dirname(key_part)
    
    # Combine the parts back into an S3 URI
    s3uri_without_filename = '/'.join(bucket_part + [key_without_filename, ''])
    
    return s3uri_without_filename

def generate_project_name(key):
    # Extract the date-time and type (Head) from the key
    match = re.search(r'(\d{4}-\d{2}-\d{2}-\d{2}:\d{2}:\d{2}-\w+)', key)
    if not match:
        raise ValueError("Could not find date-time and type in the key")
    date_time_type = match.group(1)

    # Replace colons with hyphens in the time part
    date_time_type = date_time_type.replace(':', '-')

    # Extract the user name (nakoshi) from the key
    user_match = re.search(r'/testUsers/(\w+)/', key)
    if not user_match:
        raise ValueError("Could not find user name in the key")
    user_name = user_match.group(1)

    # Combine parts to create the project name
    project_name = f"{date_time_type}-{user_name}"

    return project_name

def execute_batch(object_key):
    decoded_key = unquote(object_key)
    # s3://berry-scan-v10-storage-5652650a01f11-staging/public/testUsers/nakoshi/2024-08-09/12:49:35/2024-08-09-12:49:37-Head/
    print(f"{decoded_key}")
    original_s3uri = f"s3://{S3_BUCKET_NAME}/{decoded_key}"
    s3uri = remove_filename_from_s3uri(original_s3uri)
    project_name = generate_project_name(decoded_key)

    ROOT_DIR = r"C:\Users\jesse\Documents\RealityCapture\cmd-snippet"
    Helper = r"C:\Users\jesse\Documents\RealityCapture\cmd-snippet\src\Scripts\Helper.bat"
    FILE_PATH_IN_PROJECT = r"model\model.stl"

# 
    output_model_dir = os.path.join(ROOT_DIR, "rc-projects", project_name, FILE_PATH_IN_PROJECT)
    s3_extracted_url = extract_s3_path(s3uri)
    # s3_file_name = f"{s3_extracted_url}{project_name}.stl"
    s3_file_name = f"{s3_extracted_url}test.stl"
    print(f"[py] s3uri: {s3uri}")
    print(f"[py] project_name: {project_name}")

    # Create a temporary batch file with the variables set
    temp_batch_content = f"""
@echo off
echo {Helper}
call {Helper}

::set ROOT_DIR=%USERPROFILE%\\Documents\\RealityCapture\\cmd-snippet
set ROOT_DIR={ROOT_DIR}
echo ROOT_DIR: %ROOT_DIR%
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

::================================S3 Download================================
set ProjectName={project_name}
set s3uri={s3uri}
aws s3 cp %s3uri% "%ROOT_DIR%\\rc-projects\\%ProjectName%\\s3-images" --recursive
echo S3 Download completed.
echo Moving S3 Downloaded Images to the Python Workplace...

::================================Remove Background================================
set SOURCE_DIR=%ROOT_DIR%\\rc-projects\\%ProjectName%\\s3-images
set DESTINATION_DIR=%ROOT_DIR%\\src\\workflows\\py-rmbg\\input

if not exist "%DESTINATION_DIR%\\" mkdir "%DESTINATION_DIR%"

echo Source: "%SOURCE_DIR%"
echo Destination: "%DESTINATION_DIR%"

xcopy "%SOURCE_DIR%\\*.*" "%DESTINATION_DIR%" /I /Y

echo Start Removing Image Background
python "%ROOT_DIR%\\src\\workflows\\py-rmbg\\remove_background.py"
echo Removing Completed!

echo Deleting all files from: %DESTINATION_DIR%
del /Q "%DESTINATION_DIR%\\*"

set OUTPUT_DIR=%ROOT_DIR%\\src\\workflows\\py-rmbg\\output
set RC_PROJECT_INPUT_DIR=%ROOT_DIR%\\rc-projects\\%ProjectName%\\input-images

if not exist "%RC_PROJECT_INPUT_DIR%\\" mkdir "%RC_PROJECT_INPUT_DIR%"
xcopy "%OUTPUT_DIR%\\*.*" "%RC_PROJECT_INPUT_DIR%" /I /Y
del /Q "%OUTPUT_DIR%\\*"

echo Move Background Removed Images to Reality Capture Workplace.

::================================Reality Capture================================
call ..\Scripts\Helper.bat

set FourMarkers=%ROOT_DIR%\\src\\Settings\\DetectFourMarkers.xml
set GroundControlPoints=%ROOT_DIR%\\src\\Settings\\RevisedGCPs.csv
set SetGCPs=%ROOT_DIR%\\src\\Settings\\SetGroundControlPoints.xml
set RegionBox=%ROOT_DIR%\\src\\Settings\\reconstructionRegionNew.rcbox
set ModelExportSetting=%ROOT_DIR%\\src\\Settings\\model-export-setting.xml
set AlignmentSetting = %ROOT_DIR%\\src\\Settings\\AlignmentSetting.xml
set MeshModelSetting = %ROOT_DIR%\\src\\Settings\\MeshModelSetting.xml

set ModelExportDir=%ROOT_DIR%\\rc-projects\\%ProjectName%\\model\\model.stl

set ModelName=model

set OutputDir=%ROOT_DIR%\\rc-projects\\%ProjectName%

echo Reality Capture Processing...
echo ========DEBUG=========
echo ROOT_DIR: %ROOT_DIR%
echo RealityCaptureExe: %RealityCaptureExe%
echo RC_PROJECT_INPUT_DIR: %RC_PROJECT_INPUT_DIR%
echo ========DEBUG=========
%RealityCaptureExe% -addFolder "%RC_PROJECT_INPUT_DIR%" ^
-printProgress ^
-setProjectCoordinateSystem Local:1 ^
-detectMarkers "%FourMarkers%" ^
-importGroundControlPoints "%GroundControlPoints%" "%SetGCPs%" ^
-align ^
-setReconstructionRegionAuto ^
-setReconstructionRegion "%RegionBox%" ^
-calculateNormalModel ^
-renameSelectedModel "%ModelName%" ^
-exportModel "%ModelName%" "%ModelExportDir%" ^
-save "%OutputDir%\\project.rcproj" ^
-quit

echo Process Completed!
"""
    # Write the temporary batch file
    with open('temp_execute.bat', 'w') as f:
        f.write(temp_batch_content)
    
    # Execute the temporary batch file
    try:
        subprocess.run('temp_execute.bat', check=True, shell=True)
        print("Batch file executed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while executing the batch file: {e}")
    finally:
        # Clean up the temporary batch file
        os.remove('temp_execute.bat')
        upload_file_to_s3(s3_client, S3_BUCKET_NAME, output_model_dir, s3_file_name)