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

output "data_lake_bucket_id" {
  description = "ID of the S3 data lake bucket"
  value       = aws_s3_bucket.data_lake.id
}

output "data_lake_bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "processed_data_path" {
  description = "S3 path where processed Glue output will be written"
  value       = "s3://${aws_s3_bucket.data_lake.id}/processed/"
}

output "athena_results_path" {
  description = "S3 path where Athena query results will be stored"
  value       = "s3://${aws_s3_bucket.data_lake.id}/${var.athena_results_prefix}/"
}