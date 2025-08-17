import json
import boto3
import time
import os
from urllib.parse import unquote

# config
from ..config.setup import s3_client
from ..config.setup import sqs_client
from ..config.setup import SQS_QUEUE_URL

# workflows
from ..workflows.rc_prompt import execute_batch

def format_s3_key(key):
    # URL decode the string
    decoded_key = unquote(key)
    return decoded_key

def check_json_file(bucket, key):
    try:
        # Download the file from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        file_content = response['Body'].read().decode('utf-8')
        
        data = json.loads(file_content)
        return data.get('fileCount', 0)
    except Exception as e:
        print(f"Error downloading or parsing JSON file: {str(e)}")
        return 0

def extract_object_key(message_body):
    try:
        # Parse the JSON string if it's a string
        if isinstance(message_body, str):
            body = json.loads(message_body)
        else:
            body = message_body

        # Navigate through the nested structure
        records = body.get('Records', [])
        if records:
            s3_info = records[0].get('s3', {})
            object_info = s3_info.get('object', {})
            return object_info.get('key')
        else:
            return None
    except json.JSONDecodeError:
        print("Error: Invalid JSON string")
        return None
    except Exception as e:
        print(f"Error extracting object key: {str(e)}")
        return None
    
def process_sqs_message():
    message_count = 0
    detected_message_count = 0
    
    while True:
        print("Receiving...")
        messages = sqs_client.receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=20,
            MessageAttributeNames=['All']
        )
        
        # print(f"sqs_client.receive_message:{messages}")
        if 'Messages' in messages:
            for message in messages['Messages']:
                body = message.get('Body', 'No body')
                receipt_handle = message.get('ReceiptHandle', 'No receipt handle')
                message_attributes = message.get('MessageAttributes', {})
                message_count += 1
                
                # Check if the message indicates a JSON file upload
                try:
                    body_json = json.loads(body)
                    # print(f"body_json:{body_json}")
                    if 'Records' in body_json:
                        for record in body_json['Records']:
                            # print(f"record:{record}")
                            if record['eventName'].startswith('ObjectCreated:') and record['s3']['object']['key'].endswith('.json'):
                                bucket = record['s3']['bucket']['name']
                                key = record['s3']['object']['key']
                                formatted_key = format_s3_key(key)
                                print(f"Detected JSON upload: {formatted_key}")
                                
                                image_count = check_json_file(bucket, formatted_key)
                                detected_message_count = image_count
                                
                                if detected_message_count > 0:
                                    print(f"Detected {detected_message_count} images")

                except json.JSONDecodeError:
                    print("Message body is not valid JSON")
                except KeyError:
                    print("Unexpected message format")
                
                print(f"Body: {body}")
                print(f"ReceiptHandle: {receipt_handle}")
                print(f"MessageAttributes: {message_attributes}")
                print(f"Message Count: {message_count}")
                print(f"Detected Count: {detected_message_count}")
                print("---")
                
                # Delete the processed message
                sqs_client.delete_message(
                    QueueUrl=SQS_QUEUE_URL,
                    ReceiptHandle=receipt_handle
                )
            if message_count == detected_message_count and detected_message_count > 0:
                # TO-DO:
                extracted_key = extract_object_key(body)
                print("Finished")
                message_count = 0
                detected_message_count = 0
                print(f"Init Message Count: {message_count}")
                print(f"Init Detected Count: {detected_message_count}")
                execute_batch(extracted_key)

        else:
            print('Queue is currently Empty or Messages are Invisible')
            print(f"Message Count: {message_count}")
            print(f"Detected Count: {detected_message_count}")
            message_count = 0
            detected_message_count = 0
        
        time.sleep(1)