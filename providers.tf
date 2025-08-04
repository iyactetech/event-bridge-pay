

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
     
    }
    kubernetes = { # You'll need this for Helm deployments later
      source  = "hashicorp/kubernetes"
     
    }
    helm = { # You'll need this for Helm deployments later
      source  = "hashicorp/helm"
    
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5" # or the latest known working version
    }
    
    # Add other providers as needed (e.g., cloudflare, random, null)
  }
}

provider "aws" {
  region = var.aws_region # Get region from a root variable, passed from environment .tfvars
  # You might define `profile` or `assume_role` here for authentication if not using environment variables
}

# Provider for Kubernetes, configured after EKS cluster is deployed
provider "kubernetes" {
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_cluster.cluster_name
}

# Provider for Helm, configured after Kubernetes provider
provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
