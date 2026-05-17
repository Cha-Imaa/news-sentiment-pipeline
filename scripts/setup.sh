#!/bin/bash

echo "Setting up Terraform environment variables..."

# Project settings
export TF_VAR_project_name="news-sentiment-pipeline"

# AWS settings
export TF_VAR_region=$(aws configure get region)

if [ -z "$TF_VAR_region" ]; then
  export TF_VAR_region="us-east-1"
fi

export TF_VAR_account_id=$(aws sts get-caller-identity --query Account --output text)

# RDS settings
export TF_VAR_db_name="newsdb"
export TF_VAR_db_username="admin"
export TF_VAR_db_password="adminpwrd"
export TF_VAR_db_instance_identifier="news-sentiment-rds"

# S3 settings
export TF_VAR_s3_bucket_name="news-sentiment-datalake-${TF_VAR_account_id}"

# Glue settings
export TF_VAR_glue_job_name="news-sentiment-etl-job"

# Athena settings
export TF_VAR_athena_db_name="news_analytics"
export TF_VAR_athena_results_prefix="athena-results"

echo ""
echo "Terraform environment variables have been set:"
env | grep TF_VAR_ | sort