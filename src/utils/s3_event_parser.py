import json
import urllib.parse
import re

def read_json_file(file_path):
    try:
        with open(file_path, 'r') as file:
            return json.load(file)
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}")
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in file {file_path}")
    except Exception as e:
        print(f"Error reading file: {str(e)}")
    return None

def parse_s3_event(event):
    try:
        # If event is already a dictionary, use it directly
        if isinstance(event, dict):
            event_dict = event
        else:
            # Otherwise, try to parse it as JSON
            event_dict = json.loads(event)

        # Extract the bucket name and object key
        bucket_name = event_dict['Records'][0]['s3']['bucket']['name']
        object_key = event_dict['Records'][0]['s3']['object']['key']

        # URL decode the object key (S3 uses URL encoding for special characters)
        object_key = urllib.parse.unquote_plus(object_key)

        return {
            'bucket_name': bucket_name,
            'object_key': object_key
        }
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        print(f"Error parsing S3 event: {str(e)}")
        return None

def parse_project_name_from_object_key(input_object_key):
    # Split the object key by '/'
    parts = input_object_key.split('/')
    
    # Find the part that matches the pattern YYYY-MM-DD-HH-MM-SS-Face
    for part in parts:
        if re.match(r'\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}-Face', part):
            return part
    
    # If no matching part is found, return None
    return None

# Example usage
if __name__ == "__main__":
    file_path = r"C:\Users\jesse\Documents\RealityCapture\cmd-snippet\event_sample.json"
    s3_event = read_json_file(file_path)

    if s3_event:
        result = parse_s3_event(s3_event)
        if result:
            object_key = result['object_key']  # This is now correctly a string
            print(f"Bucket Name: {result['bucket_name']}")
            print(f"Object Key: {object_key}")
            
            project_name = parse_project_name_from_object_key(object_key)
            if project_name:
                print(f"Project Name: {project_name}")
            else:
                print("Project name not found in the object key.")
        else:
            print("Failed to parse S3 event.")
    else:
        print("Failed to read S3 event from file.")