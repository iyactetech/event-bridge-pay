# TerraformP/environments/dev/iam.tf



// IAM Role for EKS Service Account for IRSA (IAM Roles for Service Accounts)
// This role will be assumed by a Kubernetes Service Account in your Node.js app's namespace
resource "aws_iam_role" "eks_app_irsa_role" {
  name               = "${local.project_name}-${local.environment_name}-app-irsa-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks_cluster.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks_cluster.oidc_provider}:sub" : "system:serviceaccount:default:${local.project_name}-api-sa" # K8s Service Account name
          }
        }
      }
    ]
  })

  tags = local.tags
}



// IAM role and policy for the reconciliation Lambda
resource "aws_iam_role" "reconciliation_lambda_role" {
  name_prefix        = "${local.project_name}-${local.environment_name}-lambda-reco-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
  tags = local.tags
}

resource "aws_iam_policy" "reconciliation_lambda_policy" {
  name        = "${local.project_name}-${local.environment_name}-lambda-reco-policy"
  description = "Policy for reconciliation lambda to access logs and secrets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*:*"
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:DescribeParameters"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/billing/db_host",
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/billing/db_user",
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/billing/db_password",
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/billing/db_name"
  ] 
      },
      // If your reconciliation needs to interact with payment provider APIs or other AWS services, add permissions here
    ],
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "reconciliation_lambda_attach" {
  role       = aws_iam_role.reconciliation_lambda_role.name
  policy_arn = aws_iam_policy.reconciliation_lambda_policy.arn
}


resource "aws_iam_role" "self_managed_nodes" {
  name = "${local.project_name}-${local.environment_name}-self-managed-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_instance_profile" "self_managed_nodes" {
  name = "${local.project_name}-${local.environment_name}-nodes-instance-profile"
  role = aws_iam_role.self_managed_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.self_managed_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.self_managed_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.self_managed_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_eks_access_entry" "bastion_access" {
  cluster_name = module.eks_cluster.cluster_name
  principal_arn = aws_iam_role.bastion_role.arn
  type          = "STANDARD"

  tags = local.tags
}

// Bastion EKS Access Policy
resource "aws_iam_policy" "bastion_eks_access" {
  name        = "bastion-eks-access"
  description = "Minimal EKS access for bastion host"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "eks:DescribeCluster",
          "eks:AccessKubernetesApi"
        ],
        Resource = "*"
      }
    ]
  })
}

// attaching Bastion EKS Access Policy to bastion IAM role
resource "aws_iam_policy_attachment" "bastion_eks_access_attachment" {
  name       = "attach-bastion-eks-access"
  roles      = [aws_iam_role.bastion_role.name]
  policy_arn = aws_iam_policy.bastion_eks_access.arn
}





