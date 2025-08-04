module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${local.project_name}-${local.environment_name}-eks"
  cluster_version = "1.33"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets // For EKS API endpoint access

  enable_irsa = true // Enable IAM Roles for Service Accounts

  cluster_security_group_id = aws_security_group.eks_control_plane.id
  node_security_group_id    = aws_security_group.eks_worker_nodes.id
  
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false


  tags = local.tags

  // Optional: Add ALB Ingress Controller via EKS add-ons or Helm
  // For simplicity, we'll assume ALB will be created separately or via Kubernetes manifests/Helm charts.
}



data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI account ID for us-east-1

  filter {
    name   = "name"
    values = ["amazon-eks-node-*-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


// ECR Repository for your Node.js application's Docker image
resource "aws_ecr_repository" "api_repo" {
  name                 = "${local.project_name}/api"
  image_tag_mutability = "MUTABLE" # IMMUTABLE for production
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}



# Allow nodes to talk to control plane
resource "aws_security_group_rule" "nodes_to_control_plane_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_nodes.id
  source_security_group_id = aws_security_group.eks_control_plane.id
  description              = "Nodes to control plane (HTTPS)"
}



# Bootstrap user data
data "template_file" "user_data" {
  template = file("${path.module}/bootstrap.sh")
  vars = {
    cluster_name = module.eks_cluster.cluster_name
  }
}

resource "aws_launch_template" "self_managed_node_lt" {
  name_prefix   = "self-managed-node-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = var.instance_type_api

  iam_instance_profile {
    name = aws_iam_instance_profile.self_managed_nodes.name
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  vpc_security_group_ids = [aws_security_group.eks_worker_nodes.id]
}

resource "aws_autoscaling_group" "self_managed_node_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.self_managed_node_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/${module.eks_cluster.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}


resource "aws_vpc_endpoint" "eks_api" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.eks"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.vpc.public_subnets[0]]
  security_group_ids = [aws_security_group.bastion_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "eks_auth" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.eks-auth"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [module.vpc.public_subnets[0]]
  security_group_ids = [aws_security_group.bastion_sg.id]
  private_dns_enabled = true
}