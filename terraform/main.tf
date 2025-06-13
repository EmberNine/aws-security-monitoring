provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "aws-security-monitoring-trail-logs"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudTrailGetBucketAcl",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = "arn:aws:s3:::aws-security-monitoring-trail-logs"
      },
      {
        Sid       = "AllowCloudTrailPutObject",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::aws-security-monitoring-trail-logs/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AllowConfigGetBucketAcl",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = "arn:aws:s3:::aws-security-monitoring-trail-logs"
      },
      {
        Sid       = "AllowConfigPutObject",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::aws-security-monitoring-trail-logs/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "SecurityTrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}

resource "aws_guardduty_detector" "main" {
  enable = true
}

resource "aws_securityhub_account" "main" {
  depends_on = [aws_guardduty_detector.main]
}

resource "aws_iam_role" "config" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "config_inline_policy" {
  name = "aws-config-inline"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::aws-security-monitoring-trail-logs/AWSLogs/*",
          "arn:aws:s3:::aws-security-monitoring-trail-logs"
        ]
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "main" {
  name     = "default"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.bucket

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_policy,
    aws_config_configuration_recorder.main
  ]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}
