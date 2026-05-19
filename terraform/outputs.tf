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

output "rds_endpoint" {
  description = "RDS endpoint used by the local loader and Glue job"
  value       = aws_db_instance.news_db.address
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.news_db.port
}

output "rds_database_name" {
  description = "Name of the source MySQL database"
  value       = aws_db_instance.news_db.db_name
}

output "glue_role_arn" {
  description = "ARN of the IAM role used by AWS Glue"
  value       = aws_iam_role.glue_role.arn
}

output "glue_connection_name" {
  description = "Name of the Glue connection to RDS"
  value       = aws_glue_connection.rds_connection.name
}

output "glue_catalog_database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.analytics_db.name
}

output "glue_crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.processed_data_crawler.name
}

output "glue_script_s3_path" {
  description = "S3 path of the uploaded Glue ETL script"
  value       = "s3://${aws_s3_bucket.data_lake.id}/${aws_s3_object.glue_script.key}"
}