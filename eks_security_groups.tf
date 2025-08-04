// eks_security_groups.tf

// =======================================================
// SECURITY GROUP DEFINITIONS
// =======================================================
resource "aws_security_group" "eks_control_plane" {
  name        = "${local.project_name}-${local.environment_name}-eks-control-plane"
  description = "EKS control plane security group"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.tags, {
    "Name" = "eks-control-plane"
  })
}

resource "aws_security_group" "eks_worker_nodes" {
  name        = "${local.project_name}-${local.environment_name}-eks-worker-nodes"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.tags, {
    "Name" = "eks-worker-nodes"
  })
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.project_name}-${local.environment_name}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.tags, {
    "Name" = "vpc-endpoints"
  })
}

// =======================================================
// RULES FOR EKS WORKER NODES SECURITY GROUP
// =======================================================
// Ingress rules for worker nodes
resource "aws_security_group_rule" "bastion_to_worker_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_nodes.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow SSH from Bastion host"
}

resource "aws_security_group_rule" "control_plane_to_worker" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535 // kubelet ports
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_nodes.id
  source_security_group_id = aws_security_group.eks_control_plane.id
  description              = "Allow control plane to communicate with worker nodes (kubelet)"
}

resource "aws_security_group_rule" "worker_node_to_worker_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.eks_worker_nodes.id
  self              = true
  description       = "Allow all traffic between worker nodes"
}

// Egress rules for worker nodes
resource "aws_security_group_rule" "worker_nodes_outbound_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_worker_nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound HTTPS traffic from worker nodes to the internet"
}

// NEWLY ADDED EGRESS RULE
resource "aws_security_group_rule" "worker_nodes_to_vpc_endpoints_egress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_nodes.id
  source_security_group_id = aws_security_group.vpc_endpoints.id
  description              = "Allow outbound HTTPS from worker nodes to VPC endpoints"
}


// =======================================================
// RULES FOR EKS CONTROL PLANE SECURITY GROUP
// =======================================================
// Ingress rules for control plane
resource "aws_security_group_rule" "worker_to_control_plane_ingress_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_control_plane.id
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  description              = "Allow worker nodes to access control plane on HTTPS"
}

resource "aws_security_group_rule" "bastion_to_eks_control_plane_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_control_plane.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow Bastion to access EKS control plane (HTTPS)"
}

// Egress rules for control plane
resource "aws_security_group_rule" "control_plane_to_worker_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_control_plane.id
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  description              = "Allow control plane to send HTTPS to worker nodes"
}

// =======================================================
// RULES FOR VPC ENDPOINTS SECURITY GROUP
// =======================================================
// Ingress rules for VPC endpoints
resource "aws_security_group_rule" "eks_nodes_to_vpc_endpoints_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoints.id
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  description              = "Allow HTTPS from EKS worker nodes"
}

resource "aws_security_group_rule" "bastion_to_vpc_endpoints_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoints.id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow HTTPS from Bastion host"
}