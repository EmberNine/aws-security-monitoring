# AWS Security Monitoring and Alerting Lab

This project configures real-time cloud security monitoring using native AWS services.

##  Goal

Set up AWS Config, GuardDuty, SecurityHub, CloudTrail, and Lambda to build an end-to-end detection and alerting pipeline.

##  Stack

- AWS Config
- AWS GuardDuty
- AWS SecurityHub
- AWS CloudTrail
- AWS Lambda (Python)
- Optional: Terraform / AWS CLI

## Project Structure

```
aws-security-monitoring/
├── terraform/                 # Infrastructure as Code
├── lambda/                   # Custom alerting logic
├── scripts/                  # Shell scripts for automation
├── docs/                     # Architecture diagrams or notes
```

##  Setup Instructions

### 1. Enable AWS Config

```bash
aws configservice put-configuration-recorder \
  --name default \
  --role-arn arn:aws:iam::<account-id>:role/aws-config-role \
  --recording-group allSupported=true
```

### 2. Enable GuardDuty

```bash
aws guardduty create-detector --enable
```

### 3. Enable Security Hub

```bash
aws securityhub enable-security-hub
```

### 4. Enable CloudTrail

```bash
aws cloudtrail create-trail \
  --name SecurityTrail \
  --s3-bucket-name your-log-bucket
aws cloudtrail start-logging --name SecurityTrail
```

### 5. Deploy Lambda Alert Function

- Modify `lambda/alert_handler.py` to include SNS or Slack webhook.
- Zip and deploy:

```bash
cd lambda && zip function.zip alert_handler.py
aws lambda create-function \
  --function-name SecurityAlertHandler \
  --runtime python3.11 \
  --handler alert_handler.lambda_handler \
  --role arn:aws:iam::<account-id>:role/lambda-execution-role \
  --zip-file fileb://function.zip
```

##  Optional Automation

- Use EventBridge rules to invoke Lambda on GuardDuty/SecurityHub findings.
- Terraform can be used for full automation (see `/terraform` folder).

##  Architecture

![Architecture](docs/architecture.png)

##  License

MIT
