# bastion.tf

data "aws_iam_policy" "eks_cluster_policy" {
  name = "AmazonEKSClusterPolicy"
}


# Define the EC2 Instance (Bastion Host)
resource "aws_instance" "bastion_host" {
  ami           = "ami-08a6efd148b1f7504" 
  instance_type = "t2.micro" 

  # Assign to a public subnet
  # Ensure 'module.vpc.public_subnets[0]' points to an actual public subnet ID
  subnet_id = module.vpc.public_subnets[0]

  # Assign a public IP for direct SSH access
  associate_public_ip_address = true

  # Attach a security group that allows SSH from your IP
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  # SSH Key Pair Name - you need to have this key pair uploaded to AWS
  # or provisioned by Terraform. Replace with your actual key name.
  key_name = "my-bastion-key"

  # IAM Instance Profile: Grants the EC2 instance permissions to interact with AWS services,
  # including EKS.
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  tags = merge(local.tags, {
    Name = "${local.project_name}-${local.environment_name}-bastion"
  })

  # Optional: User data to install kubectl and aws-iam-authenticator on boot
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y curl unzip

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # Install aws-iam-authenticator (adjust version if needed)
    curl -o aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.7.4/aws-iam-authenticator_0.7.4_linux_amd64
    chmod +x ./aws-iam-authenticator
    sudo mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

    # Install AWS CLI v2 (EKS update-kubeconfig requires v2)
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Set up kubectl auto-completion (optional)
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'alias k=kubectl' >> ~/.bashrc
    echo 'complete -F __start_kubectl k' >> ~/.bashrc

    # Update kubeconfig for the EKS cluster (replace with your cluster name and region)
    # This will run on first boot. The IAM role attached to the instance must have permissions for this.
    aws eks update-kubeconfig --name ${local.project_name}-${local.environment_name}-eks --region ${data.aws_region.current.name}

    aws eks update-kubeconfig --name ${local.project_name}-${local.environment_name}-eks --region ${data.aws_region.current.name}


    EOF
}

# Security Group for the Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "${local.project_name}-${local.environment_name}-bastion-sg"
  description = "Allow SSH inbound traffic to bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # IMPORTANT: Replace with YOUR public IP address (or CIDR block)
    # Never use "0.0.0.0/0" for SSH in production!
    cidr_blocks = [var.my_public_ip]  # e.g., "203.0.113.5/32" 
    description = "Allow SSH from my local machine"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = merge(local.tags, {
    Name = "${local.project_name}-${local.environment_name}-bastion-sg"
  })
}

# IAM Role for the Bastion Host
resource "aws_iam_role" "bastion_role" {
  name = "${local.project_name}-${local.environment_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

# Attach necessary policies to the Bastion IAM Role
resource "aws_iam_role_policy_attachment" "bastion_ssm_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # Allows SSM access
}



# If you want to allow the bastion to manage EKS (e.g., delete node groups for testing)
# resource "aws_iam_role_policy_attachment" "bastion_eks_admin_policy" {
#   role       = aws_iam_role.bastion_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# IAM Instance Profile: required to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${local.project_name}-${local.environment_name}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}


# Output the public IP of the bastion host for easy SSH
output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = aws_instance.bastion_host.public_ip
}


