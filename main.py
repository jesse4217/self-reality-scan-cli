import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.workflows.sqs_listener_main import process_sqs_message

if __name__ == "__main__":
    print("SQS Executed!")
    process_sqs_message()
    print("SQS Terminated!")

    