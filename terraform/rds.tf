data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
resource "aws_db_subnet_group" "news_db" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = var.project_name
    Environment = "dev"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL access for the news sentiment source database"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Project     = var.project_name
    Environment = "dev"
  }
}

resource "aws_db_instance" "news_db" {
  identifier = var.db_instance_identifier

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.news_db.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = true

  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 0

  tags = {
    Name        = var.db_instance_identifier
    Project     = var.project_name
    Environment = "dev"
  }
}