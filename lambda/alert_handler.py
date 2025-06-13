import json
import boto3
import os

def lambda_handler(event, context):
    print("Event Received:", json.dumps(event))

    detail_type = event.get("detail-type", "Unknown")
    detail = event.get("detail", {})

    message = {
        "summary": f"AWS Security Alert: {detail_type}",
        "detail": detail
    }

    sns = boto3.client("sns")
    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject="AWS Security Alert",
        Message=json.dumps(message, indent=2)
    )

    return {"statusCode": 200, "body": "Alert sent"}
