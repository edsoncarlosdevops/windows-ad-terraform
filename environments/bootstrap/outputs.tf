output "bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "init_dev" {
  value = <<-EOT
    Execute no dev:
      cd environments/dev
      terraform init -reconfigure
      terraform apply
  EOT
}
