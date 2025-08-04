module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "${local.project_name}-${local.environment_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"] // Example: 3 AZs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"] # Dedicated for RDS

  enable_nat_gateway     = true
  single_nat_gateway     = true // For dev, single NAT Gateway is often sufficient
  enable_vpn_gateway     = false

  tags = local.tags


}


resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags              = local.tags
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags              = local.tags
}

# Example of a Gateway endpoint (for S3)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
  tags              = local.tags
}


resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = local.tags
}


resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = local.tags
}


// VPC Endpoint for EKS API
resource "aws_vpc_endpoint" "eks_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets // Should be in private subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

// VPC Endpoint for EKS Authentication
resource "aws_vpc_endpoint" "eks_auth" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.eks-auth"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets // Should be in private subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}



/*
resource "aws_route" "public_internet_access" {
  count                  = length(module.vpc.public_route_table_ids)
  route_table_id         = module.vpc.public_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.igw_id
}
*/