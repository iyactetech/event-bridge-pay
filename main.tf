

// Local variables for consistent naming and tagging

locals {
  project_name      = var.project_name
  environment_name  = var.environment_name
  region            = data.aws_region.current.name 
  tags = {
    Project     = local.project_name
    Environment = local.environment_name
    ManagedBy   = "Terraform"
  }
}