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
  cidr_block           = "10.0.0.0/18"
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
  tags = {
    Name = "route_table_a"
  }
}

resource "aws_route_table" "route_table_b" {
  vpc_id = aws_vpc.vpc_soat.id
  tags = {
    Name = "route_table_b"
  }
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

resource "aws_subnet" "soat_subnet_private2_us_east_1b" {
  vpc_id                  = aws_vpc.vpc_soat.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws_az_b
  map_public_ip_on_launch = false
  tags = {
    Name  = "soat-subnet-private2-us-east-1b"
    infra = "vpc-soat"
  }
}

output "subnet_b_id" {
  value = aws_subnet.soat_subnet_private2_us_east_1b.id
}

resource "aws_route_table_association" "subnet_association_b" {
  subnet_id      = aws_subnet.soat_subnet_private2_us_east_1b.id
  route_table_id = aws_route_table.route_table_b.id
}

output "route_table_b" {
  value = aws_route_table_association.subnet_association_b.id
}

resource "aws_subnet" "soat_subnet_public1_us_east_1a" {
  vpc_id                  = aws_vpc.vpc_soat.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.aws_az_a
  map_public_ip_on_launch = true
  tags = {
    Name  = "soat-subnet-public1-us-east-1a"
    infra = "vpc-soat"
  }
}

resource "aws_subnet" "soat_subnet_public2_us_east_1b" {
  vpc_id                  = aws_vpc.vpc_soat.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = var.aws_az_a
  map_public_ip_on_launch = true
  tags = {
    Name  = "soat-subnet-public2-us-east-1b"
    infra = "vpc-soat"
  }
}