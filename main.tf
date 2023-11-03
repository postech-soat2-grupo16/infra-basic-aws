provider "aws" {
  region = var.aws_region
}

#Configuração do Terraform State
terraform {
  backend "s3" {
    bucket = "terraform-state-soat"
    key    = "infra-basic-aws/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-soat-locking"
    encrypt        = true
  }
}

### VPC CONFIG ###

resource "aws_vpc" "vpc_soat" {
  cidr_block           = "10.0.0.0/23"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name  = "vpc-soat"
    infra = "vpc-soat"
  }
}

output "vpc_soat_id" {
  value = aws_vpc.vpc_soat.id
}

resource "aws_route_table" "route_table_a" {
  vpc_id = aws_vpc.vpc_soat.id
}

resource "aws_route_table" "route_table_b" {
  vpc_id = aws_vpc.vpc_soat.id
}

resource "aws_subnet" "soat_subnet_private1_us_east_1a" {
  vpc_id                  = aws_vpc.vpc_soat.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = var.aws_az_a
  map_public_ip_on_launch = false
  tags = {
    Name  = "soat-subnet-private1-us-east-1a"
    infra = "vpc-soat"
  }
}

output "subnet_a_id" {
  value = aws_subnet.soat_subnet_private1_us_east_1a.id
}

resource "aws_route_table_association" "subnet_association_a" {
  subnet_id      = aws_subnet.soat_subnet_private1_us_east_1a.id
  route_table_id = aws_route_table.route_table_a.id
}

output "route_table_a" {
  value = aws_route_table_association.subnet_association_a.id
}

resource "aws_subnet" "soat_subnet_private1_us_east_1b" {
  vpc_id                  = aws_vpc.vpc_soat.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws_az_b
  map_public_ip_on_launch = false
  tags = {
    Name  = "soat-subnet-private1-us-east-1b"
    infra = "vpc-soat"
  }
}

output "subnet_b_id" {
  value = aws_subnet.soat_subnet_private1_us_east_1b.id
}

resource "aws_route_table_association" "subnet_association_b" {
  subnet_id      = aws_subnet.soat_subnet_private1_us_east_1b.id
  route_table_id = aws_route_table.route_table_b.id
}

output "route_table_b" {
  value = aws_route_table_association.subnet_association_b.id
}

#Security Group LB
resource "aws_security_group" "security_group_load_balancer" {
  name_prefix = "security-group-load-balancer"
  description = "load balancer SG"
  vpc_id      = aws_vpc.vpc_soat.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    infra = "vpc-soat"
    Name  = "security-group-load-balancer"
  }
}

#Security Group ECS
resource "aws_security_group" "security_group_cluster_ecs" {
  name_prefix = "security-group-cluster-ecs"
  description = "cluster ecs SG"
  vpc_id      = aws_vpc.vpc_soat.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_load_balancer.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    infra = "vpc-soat"
    Name  = "security-group-cluster-ecs"
  }
}

output "security_group_ecs_id" {
  value = aws_security_group.security_group_cluster_ecs.id
}

resource "aws_security_group_rule" "security_group_cluster_ecs_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group_cluster_ecs.id
  depends_on        = [aws_ecs_cluster.cluster_ecs_soat]
}

#Security Group DB
resource "aws_security_group" "security_group_db" {
  name_prefix = "security-group-fastfood-db"
  description = "cluster ecs SG"
  vpc_id      = aws_vpc.vpc_soat.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_load_balancer.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    infra = "vpc-soat"
    Name  = "security-group-fastfood-db"
  }
}
