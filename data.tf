
// Data source to get your AWS account ID
data "aws_caller_identity" "current" {}

// Data source to get current AWS region
data "aws_region" "current" {}