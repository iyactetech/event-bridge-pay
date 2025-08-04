variable "project_name" {
  description = "The name of the overall project (e.g., PaymentProcessor)"
  type        = string
}

variable "environment_name" {
  description = "The name of the deployment environment (e.g., dev, prod)"
  type        = string
}

variable "instance_type_api" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.medium"
}

variable "db_instance_class" {
  description = "RDS DB instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage in gigabytes (GB)."
  type        = number
  default     = 20
}


# It's good practice to define a variable for region at the root or within environments
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "db_name" {
  type    = string
  default = "billing"
}

variable "region" {
  description = "AWS region"
  type        = string
}


variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}


variable "my_public_ip" {
  description = "Your local public IP address to allow SSH access from."
  type        = string
  
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/32$", var.my_public_ip))
    error_message = "The 'my_public_ip' variable must be a valid CIDR block with a /32 suffix (e.g., '192.0.2.1/32')."
  }
}