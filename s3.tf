module "audit_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket_prefix = "eventbridge-payment-logs-"
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_encryption.arn
      }
    }
  }

  tags = {
    Name        = "AuditLogs"
    Environment = var.environment
  }
}



resource "aws_kms_key" "s3_encryption" {
  description             = "KMS key for S3 bucket encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "s3_encryption_alias" {
  name          = "alias/s3-audit-logs"
  target_key_id = aws_kms_key.s3_encryption.id
}
