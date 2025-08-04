// Random password for the RDS database (will be stored in Secrets Manager)
resource "random_password" "db_password" {
  length  = 16
  special = false
  lower   = true
  upper   = true
  numeric  = true
}

module "rds_database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${local.project_name}-${local.environment_name}-db"

  engine            = "postgres"
  engine_version    = "15.8"
  family            = "postgres15"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name = var.db_name
  
  db_subnet_group_name = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az              = false // For dev, single AZ is typically fine
  create_monitoring_role = true

  username = "payments_admin"
  password = random_password.db_password.result

  port = 5432

  tags = local.tags

  backup_retention_period = 7
  skip_final_snapshot     = true // Set to false for production
  deletion_protection     = false // Set to true for production

  // Option to publish logs to CloudWatch
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}

// Security group for RDS to allow access from EKS worker nodes
resource "aws_security_group" "rds_sg" {
  name_prefix = "${local.project_name}-${local.environment_name}-rds-sg-"
  description = "Allow PostgreSQL traffic from EKS cluster to RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow PostgreSQL from EKS worker node security group"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [module.eks_cluster.node_security_group_id] // EKS worker node SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}