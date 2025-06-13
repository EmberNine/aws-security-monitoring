resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts-topic"
}

resource "aws_iam_role" "lambda_alert_role" {
  name = "lambda-alert-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_alert_policy" {
  name = "lambda-alert-policy"
  role = aws_iam_role.lambda_alert_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "sns:Publish"
        ],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/alert_handler.py"
  output_path = "${path.module}/../lambda/alert_handler.zip"
}

resource "aws_lambda_function" "security_alert_handler" {
  function_name = "SecurityAlertHandler"
  role          = aws_iam_role.lambda_alert_role.arn
  handler       = "alert_handler.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "security_findings" {
  name        = "SecurityFindingsRule"
  description = "Triggers on AWS Config or GuardDuty findings"
  event_pattern = jsonencode({
    "source": ["aws.config", "aws.guardduty"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.security_findings.name
  target_id = "LambdaSecurityAlert"
  arn       = aws_lambda_function.security_alert_handler.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_alert_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_findings.arn
}
