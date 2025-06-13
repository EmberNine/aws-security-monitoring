import json
import boto3

def lambda_handler(event, context):
    print("Event Received:", json.dumps(event))

    message = f"Security Alert:\n{json.dumps(event['detail'], indent=2)}"

    sns = boto3.client('sns')
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:123456789012:SecurityAlerts',
        Message=message,
        Subject='AWS Security Alert'
    )

    return {"statusCode": 200}
