output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail_bucket.id
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}
