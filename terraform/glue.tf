resource "aws_iam_role" "glue_role" {
  name = "${var.project_name}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "glue.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-glue-role"
    Project     = var.project_name
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_policy" "glue_custom_policy" {
  name        = "${var.project_name}-glue-custom-policy"
  description = "Custom permissions for Glue ETL job and crawler"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_custom_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_custom_policy.arn
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.data_lake.id
  key    = "scripts/glue_job.py"
  source = "${path.module}/assets/glue_job.py"

  etag = filemd5("${path.module}/assets/glue_job.py")
}

resource "aws_glue_connection" "rds_connection" {
  name = "${var.project_name}-rds-connection"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${aws_db_instance.news_db.address}:${aws_db_instance.news_db.port}/${var.db_name}"
    USERNAME            = var.db_username
    PASSWORD            = var.db_password
  }

  physical_connection_requirements {
    availability_zone      = data.aws_availability_zones.available.names[0]
    security_group_id_list = [aws_security_group.rds.id]
    subnet_id              = data.aws_subnets.default.ids[0]
  }
}

resource "aws_glue_catalog_database" "analytics_db" {
  name = var.athena_db_name
}

resource "aws_glue_job" "news_sentiment_etl" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.glue_role.arn

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.data_lake.id}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }

  connections = [
    aws_glue_connection.rds_connection.name
  ]

  default_arguments = {
    "--job-language"    = "python"
    "--connection_name" = aws_glue_connection.rds_connection.name
    "--database_name"   = var.db_name
    "--s3_output_path"  = "s3://${aws_s3_bucket.data_lake.id}/processed/"
  }

  tags = {
    Name        = var.glue_job_name
    Project     = var.project_name
    Environment = "dev"
  }

  depends_on = [
    aws_s3_object.glue_script,
    aws_iam_role_policy_attachment.glue_service_role,
    aws_iam_role_policy_attachment.glue_custom_policy_attachment
  ]
}

resource "aws_glue_crawler" "processed_data_crawler" {
  name          = "${var.project_name}-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.analytics_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.id}/processed/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  tags = {
    Name        = "${var.project_name}-crawler"
    Project     = var.project_name
    Environment = "dev"
  }

  depends_on = [
    aws_glue_catalog_database.analytics_db
  ]
}