import boto3
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configuration from environment variables
ROOT_DIR = os.getenv('ROOT_DIR', r"C:\Users\jesse\Documents\RealityCapture\cmd-snippet")

# AWS configuration
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_REGION', 'ap-northeast-1')

# SQS configuration
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')

# S3 configuration
S3_BUCKET_NAME = os.getenv('S3_BUCKET_NAME')

# Initialize AWS clients
sqs_client = boto3.client('sqs', 
                         aws_access_key_id=AWS_ACCESS_KEY_ID,
                         aws_secret_access_key=AWS_SECRET_ACCESS_KEY, 
                         region_name=AWS_REGION)

s3_client = boto3.client('s3', 
                        aws_access_key_id=AWS_ACCESS_KEY_ID,
                        aws_secret_access_key=AWS_SECRET_ACCESS_KEY, 
                        region_name=AWS_REGION)