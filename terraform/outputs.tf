output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "s3_bucket_name" {
  description = "S3 bucket name planned for the data lake"
  value       = var.s3_bucket_name
}

output "glue_job_name" {
  description = "Glue job name planned for the ETL pipeline"
  value       = var.glue_job_name
}

output "athena_database_name" {
  description = "Athena database name planned for analytics"
  value       = var.athena_db_name
}