import os
import subprocess

def aws_s3_download(root_dir, project_name, s3_uri):
    batch_content = f"""@echo off
aws s3 cp {s3_uri} "{root_dir}\\rc-projects\\{project_name}\\s3-images" --recursive

if %errorlevel% neq 0 (
    echo Error: AWS S3 download failed.
    exit /b 1
) else (
    echo S3 Download completed successfully.
)
"""

    batch_file_path = os.path.join(root_dir, "temp_download_script.bat")
    
    try:
        with open(batch_file_path, "w") as batch_file:
            batch_file.write(batch_content)
        
        subprocess.run(batch_file_path, check=True, shell=True)
        print("Batch script executed successfully.")
    except subprocess.CalledProcessError:
        print("An error occurred while executing the batch script.")
    except IOError:
        print("An error occurred while writing the batch file.")
    finally:
        if os.path.exists(batch_file_path):
            os.remove(batch_file_path)


def rc_process_all(root_dir, project_name):
    batch_content = f"""@echo off

call {root_dir}\src\Scripts\Helper.bat

::================================Variables================================

set FourMarkers={root_dir}\src\Settings\DetectFourMarkers.xml
set GroundControlPoints={root_dir}\src\Settings\GroundControlPoints.csv
set SetGCPs={root_dir}\src\Settings\SetGroundControlPoints.xml
set RegionBox={root_dir}\src\Settings\ReconstructionRegionNew.rcbox
set ModelExportSetting={root_dir}\src\Settings\ModelExportSetting.xml
set AlignmentSetting = {root_dir}\src\Settings\AlignmentSetting.xml
set MeshModelSetting = {root_dir}\src\Settings\MeshModelSetting.xml

set ModelExportDir={root_dir}\rc-projects\{project_name}\model\model.stl

set ModelName=model

set OutputDir={root_dir}\rc-projects\{project_name}

echo Reality Capture Processing...
%RealityCaptureExe% -addFolder "%RC_PROJECT_INPUT_DIR%" ^
-printProgress ^
-setProjectCoordinateSystem Local:1 ^
-detectMarkers "%FourMarkers%" ^
-importGroundControlPoints "%GroundControlPoints%" "%SetGCPs%" ^
-align ^
-setReconstructionRegionAuto ^
-setReconstructionRegion "%RegionBox%" ^
-calculatePreviewModel ^
-renameSelectedModel "%ModelName%" ^
-exportModel "%ModelName%" "%ModelExportDir%" ^
-save "%OutputDir%\project.rcproj" ^
-quit

echo Process Completed!

"""
    
    batch_file_path = os.path.join(root_dir, "temp_rc_process_all.bat")
    
    try:
        with open(batch_file_path, "w") as batch_file:
            batch_file.write(batch_content)
        
        subprocess.run(batch_file_path, check=True, shell=True)
        print("Batch script executed successfully.")
    except subprocess.CalledProcessError:
        print("An error occurred while executing the batch script.")
    except IOError:
        print("An error occurred while writing the batch file.")
    finally:
        if os.path.exists(batch_file_path):
            os.remove(batch_file_path)

def aws_s3_upload(root_dir, project_name, s3_uri):
    batch_content = f"""@echo off
aws s3 cp {root_dir}\\rc-projects\\{project_name}\\model {s3_uri} --recursive

if %errorlevel% neq 0 (
    echo Error: AWS S3 upload failed.
    exit /b 1
) else (
    echo S3 Upload completed successfully.
)
"""

    batch_file_path = os.path.join(root_dir, "temp_upload_script.bat")
    
    try:
        with open(batch_file_path, "w") as batch_file:
            batch_file.write(batch_content)
        
        subprocess.run(batch_file_path, check=True, shell=True)
        print("Batch script executed successfully.")
    except subprocess.CalledProcessError:
        print("An error occurred while executing the batch script.")
    except IOError:
        print("An error occurred while writing the batch file.")
    finally:
        if os.path.exists(batch_file_path):
            os.remove(batch_file_path)