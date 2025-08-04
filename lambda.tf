module "lambda_eventbridge_logger" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = "eventbridge-audit-logger"
  description   = "Writes payment events from EventBridge to S3"
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  # Zip file built externally or use build-in method
  source_path = "./src/lambda-audit-logger" # folder containing index.js and package.json

  environment_variables = {
    BUCKET_NAME = module.audit_logs_bucket.s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = [
  {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.audit_logs_bucket.s3_bucket_arn}/*"
    ]
  },
  {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = [
      aws_kms_key.s3_encryption.arn
    ]
  }
]


  timeout = 10
}


module "lambda_reconciliation" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = "reconciliation-job"
  description   = "Scheduled job to check for pending payments"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 15

  source_path = "./src/lambda-reconciliation"

  attach_policy_statements = true
  policy_statements = [
    {
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      resources = [
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/billing/*"
      ]
    }
  ]
}
