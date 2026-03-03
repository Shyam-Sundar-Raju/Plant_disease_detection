# =============================================================
# Terraform Variables
# =============================================================

variable "project_name" {
  description = "Name of the project, used as a prefix for all resources"
  type        = string
  default     = "plant-disease"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"  # Mumbai — closest to India
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB RAM — good for ML inference
  # For production with heavy AI usage, consider: t3.large or c5.xlarge
}

variable "mongodb_instance_class" {
  description = "DocumentDB / MongoDB instance class"
  type        = string
  default     = "db.t3.medium"
}
