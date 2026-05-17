variable "project_name" {
  description = "Project name used as a prefix for AWS resources"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "account_id" {
  description = "AWS account ID used for globally unique resource names"
  type        = string
}

variable "db_name" {
  description = "Name of the MySQL database"
  type        = string
}

variable "db_username" {
  description = "Username for the MySQL database"
  type        = string
}

variable "db_password" {
  description = "Password for the MySQL database"
  type        = string
  sensitive   = true
}

variable "db_instance_identifier" {
  description = "Identifier for the RDS database instance"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket used as the data lake"
  type        = string
}

variable "glue_job_name" {
  description = "Name of the AWS Glue ETL job"
  type        = string
}

variable "athena_db_name" {
  description = "Name of the Athena and Glue catalog database"
  type        = string
}

variable "athena_results_prefix" {
  description = "S3 prefix used to store Athena query results"
  type        = string
}