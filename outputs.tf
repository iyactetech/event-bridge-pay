# TerraformP/environments/dev/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC created for the dev environment"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs in the dev VPC"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs in the dev VPC"
  value       = module.vpc.public_subnets
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster in the dev environment"
  value       = module.eks_cluster.cluster_name
}



output "rds_endpoint" {
  description = "The endpoint address of the RDS PostgreSQL instance"
  value       = module.rds_database.db_instance_address
}

output "rds_port" {
  description = "The port of the RDS PostgreSQL instance"
  value       = module.rds_database.db_instance_port
}



output "ecr_repository_url" {
  description = "URL of the ECR repository for the Node.js application"
  value       = aws_ecr_repository.api_repo.repository_url
}


output "reconciliation_lambda_name" {
  description = "Name of the reconciliation Lambda function"
  value       = module.lambda_reconciliation.lambda_function_name
}
