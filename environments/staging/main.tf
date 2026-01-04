# Staging Environment Main Configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Local variables
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  az_count                 = var.az_count
  enable_nat_gateway       = true
  single_nat_gateway       = false
  enable_flow_logs         = true
  flow_logs_retention_days = 14
  common_tags              = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  application_port   = 80
  enable_https       = var.enable_https
  enable_ssh_access  = false
  create_database_sg = false
  common_tags        = local.common_tags
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name                     = var.project_name
  environment                      = var.environment
  vpc_id                           = module.vpc.vpc_id
  public_subnet_ids                = module.vpc.public_subnet_ids
  alb_security_group_id            = module.security_groups.alb_security_group_id
  enable_deletion_protection       = false
  enable_https                     = var.enable_https
  certificate_arn                  = var.certificate_arn
  create_route53_record            = var.create_route53_record
  route53_zone_id                  = var.route53_zone_id
  domain_name                      = var.domain_name
  health_check_path                = "/"
  health_check_interval            = 30
  health_check_timeout             = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3
  deregistration_delay             = 60
  enable_stickiness                = false
  log_retention_days               = 30
  common_tags                      = local.common_tags
}

# ASG Module
module "asg" {
  source = "../../modules/asg"

  project_name                  = var.project_name
  environment                   = var.environment
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnet_ids
  application_security_group_id = module.security_groups.application_security_group_id
  target_group_arns             = [module.alb.target_group_arn]
  ami_id                        = var.ami_id
  instance_type                 = var.instance_type
  key_name                      = var.key_name
  min_size                      = var.asg_min_size
  max_size                      = var.asg_max_size
  desired_capacity              = var.asg_desired_capacity
  health_check_type             = "ELB"
  health_check_grace_period     = 300
  enable_monitoring             = true
  enable_scaling_policies       = true
  scale_up_threshold            = 70
  scale_down_threshold          = 30
  root_volume_size              = 30
  enable_instance_refresh       = true
  common_tags                   = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name             = var.project_name
  environment              = var.environment
  alb_arn_suffix           = module.alb.alb_arn
  target_group_arn_suffix  = module.alb.target_group_arn
  asg_name                 = module.asg.asg_name
  sns_email_endpoints      = var.sns_email_endpoints
  enable_alarms            = true
  unhealthy_host_threshold = 1
  response_time_threshold  = 1.5
  http_5xx_threshold       = 10
  http_4xx_threshold       = 50
  common_tags              = local.common_tags
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = module.alb.alb_zone_id
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = module.alb.target_group_arn
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg.asg_name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = module.monitoring.sns_topic_arn
}

output "dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = module.monitoring.dashboard_name
}

output "route53_fqdn" {
  description = "Route53 FQDN"
  value       = module.alb.route53_fqdn
}
