# =============================================================
# Terraform Outputs
# =============================================================

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS API server"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "ecr_repository_url" {
  description = "URL of the ECR repository — use this in your CI/CD to push Docker images"
  value       = aws_ecr_repository.backend.repository_url
}

output "s3_uploads_bucket" {
  description = "Name of the S3 bucket used for image uploads"
  value       = aws_s3_bucket.uploads.bucket
}

output "s3_uploads_bucket_arn" {
  description = "ARN of the S3 uploads bucket"
  value       = aws_s3_bucket.uploads.arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "kubectl_config_command" {
  description = "Run this command to configure kubectl to connect to your cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
