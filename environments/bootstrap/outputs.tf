output "bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = aws_s3_bucket.state.bucket
}

output "dynamodb_table" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "next_steps" {
  description = "Instructions to deploy the dev environment"
  value = <<-EOT
    Run the following commands to deploy the infrastructure:
      cd environments/dev
      terraform init -reconfigure
      terraform apply
  EOT
}

