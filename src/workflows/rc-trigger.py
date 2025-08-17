import subprocess
import sys
import os
import argparse
from dotenv import load_dotenv

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.setup import ROOT_DIR
from config.aws_utils import aws_s3_download
from config.aws_utils import rc_process_all
from config.aws_utils import aws_s3_upload

# Load environment variables
load_dotenv()

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='RealityCapture processing trigger')
    parser.add_argument('--project-name', type=str, 
                        default=os.getenv('DEFAULT_PROJECT_NAME', '2024-08-21-09-21-20-Face'),
                        help='Project name for processing')
    parser.add_argument('--s3-uri', type=str,
                        default=os.getenv('DEFAULT_S3_URI'),
                        help='S3 URI for the project (e.g., s3://bucket/path/to/project/)')
    
    args = parser.parse_args()
    
    # Validate inputs
    if not args.s3_uri:
        print("Error: S3 URI is required. Provide it via --s3-uri argument or DEFAULT_S3_URI environment variable")
        sys.exit(1)
    
    project_name = args.project_name
    s3_uri = args.s3_uri
    
    print(f"Processing project: {project_name}")
    print(f"S3 URI: {s3_uri}")
    
    # Download from S3
    aws_s3_download(ROOT_DIR, project_name, s3_uri)
    
    # Process with RealityCapture
    rc_process_all(ROOT_DIR, project_name)
    
    # Upload back to S3
    aws_s3_upload(ROOT_DIR, project_name, s3_uri)
    
    print(f"Processing complete for project: {project_name}")

if __name__ == "__main__":
    main()

