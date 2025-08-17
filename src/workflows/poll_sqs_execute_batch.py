import json
import time
from pprint import pprint
import subprocess
import os
import boto3
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get AWS credentials from environment variables
aws_access_key_id = os.getenv('AWS_ACCESS_KEY_ID')
aws_secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')
region_name = os.getenv('AWS_REGION', 'ap-northeast-1')

# Initialize AWS clients
sqs_send = boto3.client('sqs', aws_access_key_id=aws_access_key_id, 
                        aws_secret_access_key=aws_secret_access_key, 
                        region_name=region_name)

sendQueueUrl = os.getenv('SQS_RECEIVER_QUEUE_URL', 'https://sqs.ap-northeast-1.amazonaws.com/159709900859/BerryScanv10OfficeTestEC2ReceiverQueue')


current_dir = Path(__file__).parent
main_batch_path = current_dir / "Main.bat"

def process_sqs_message():
    print("Receiving Messages from SQS...\nPress Ctrl+C to quit.")
    
    head_processing_threshold = 30

    while True:
        messages = sqs_send.receive_message(
            QueueUrl=sendQueueUrl,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=20,
            MessageAttributeNames=['All']
        )
        
        if 'Messages' in messages:
            for m in messages['Messages']:
                body = m.get('Body', 'No body')
                receipt_handle = m.get('ReceiptHandle', 'No receipt handle')
                
                try:
                    body_json = json.loads(body)
                    print("\n--- New Message ---")
                    pprint(body_json, indent=2, width=100)

                    if 'event_data' in body_json and 'Records' in body_json['event_data']:
                        for record in body_json['event_data']['Records']:
                            if 'Sns' in record and 'Message' in record['Sns']:
                                sns_message = json.loads(record['Sns']['Message'])
                                print("\nProcessed SNS Message:")
                                print(f"Status: {sns_message.get('status')}")
                                print(f"Project Name: {sns_message.get('project_name')}")
                                print(f"Face Folder Name: {sns_message.get('face_folder_name')}")
                                print(f"Head Folder Name: {sns_message.get('head_folder_name')}")
                                print(f"S3 URI: {sns_message.get('project_S3_URI')}")
                                print(f"Uploaded Images: {sns_message.get('uploaded_images')}")
                                print(f"Detected Images: {sns_message.get('detected_images')}")

                                detected_image = sns_message.get('detected_images')

                                # Execute Main.bat with the parsed information
                                # project_name = sns_message.get('project_name')
                                time_s3_uri = sns_message.get('project_S3_URI')

                                face_folder_name = sns_message.get('face_folder_name', '')
                                head_folder_name = sns_message.get('head_folder_name', '')

                                face_project_name = face_folder_name.rstrip('/')
                                head_project_name = head_folder_name.rstrip('/')
                                
                                # Construct the face scan URI
                                face_scan_uri = os.path.join(time_s3_uri, face_folder_name).replace('\\', '/')
                                
                                # execute_batch_file(face_folder_name, face_scan_uri)

                                head_scan_uri = os.path.join(time_s3_uri, head_folder_name).replace('\\', '/')

                                
                                execute_multiple_batch_files(face_project_name, face_scan_uri, head_project_name, head_scan_uri, detected_count=detected_image, threshold_count=head_processing_threshold)

                except json.JSONDecodeError:
                    print("Invalid JSON in message body")
                except KeyError:
                    print("Unexpected message structure")

                sqs_send.delete_message(
                    QueueUrl=sendQueueUrl,
                    ReceiptHandle=receipt_handle
                )
        else:
            print('No new messages in the queue')
        
        time.sleep(1)

def execute_batch_file(face_project_name, face_scan_uri):
    print(f"\nExecuting Main.bat with:")
    print(f"Project Name: {face_project_name}")
    print(f"Face Scan URI: {face_scan_uri}")

    try:
        # Use subprocess.run to execute the batch file with arguments
        result = subprocess.run([main_batch_path, face_project_name, face_scan_uri], 
                                capture_output=True, text=True, check=True)
        
        # Print the output from the batch file
        print("Batch file output:")
        print(result.stdout)
        
        print("Batch file execution completed.")
    except subprocess.CalledProcessError as e:
        print(f"Error executing batch file: {e}")
        print(f"Batch file error output: {e.stderr}")

def execute_multiple_batch_files(project_name_01, scan_uri_01, project_name_02, scan_uri_02, detected_count, threshold_count):
    start_time = time.time()
    print(f"\nExecuting Main.bat with:")
    print(f"Project Name 01: {project_name_01}")
    print(f"Project Name 01: {project_name_02}")
    print(f"Scan URI 01: {scan_uri_01}")
    print(f"Scan URI 02: {scan_uri_02}")

    try:
        # Use subprocess.run to execute the batch file with arguments
        if detected_count <= threshold_count:
            print("Generating Face...")
            result_01 = subprocess.run([main_batch_path, project_name_01, scan_uri_01], 
                                capture_output=True, text=True, check=True)
        else:
            print("Generating...")
            result_01 = subprocess.run([main_batch_path, project_name_01, scan_uri_01], 
                                capture_output=True, text=True, check=True)
            result_02 = subprocess.run([main_batch_path, project_name_02, scan_uri_02], 
                                capture_output=True, text=True, check=True)
        
        # Print the output from the batch file
        # print("Batch file output:")
        # print(result_01.stdout)
        # print(result_02.stdout)
        
        print("Batch file execution completed.")
        end_time = time.time()
        execution_time = end_time - start_time
        print(f"Function started at: {time.ctime(start_time)}")
        print(f"Function ended at: {time.ctime(end_time)}")
        print(f"Execution time: {execution_time:.6f} seconds")
        
    except subprocess.CalledProcessError as e:
        print(f"Error executing batch file: {e}")
        print(f"Batch file error output: {e.stderr}")

try:
    process_sqs_message()
except KeyboardInterrupt:
    print("\nProgram stopped by user.")