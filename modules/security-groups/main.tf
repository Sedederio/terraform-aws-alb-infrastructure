# Security Groups Module - Creates security groups for ALB and EC2 instances

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )
}

# ALB Ingress Rule - HTTP
resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic from specified CIDR blocks"
}

# ALB Ingress Rule - HTTPS
resource "aws_security_group_rule" "alb_https_ingress" {
  count             = var.enable_https ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.alb_ingress_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS traffic from specified CIDR blocks"
}

# ALB Egress Rule - Allow all outbound to application instances
resource "aws_security_group_rule" "alb_egress" {
  type                     = "egress"
  from_port                = var.application_port
  to_port                  = var.application_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow traffic to application instances"
}

# Application Security Group
resource "aws_security_group" "application" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-app-sg"
    }
  )
}

# Application Ingress Rule - From ALB
resource "aws_security_group_rule" "app_alb_ingress" {
  type                     = "ingress"
  from_port                = var.application_port
  to_port                  = var.application_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.application.id
  description              = "Allow traffic from ALB"
}

# Application Ingress Rule - SSH (optional, for debugging)
resource "aws_security_group_rule" "app_ssh_ingress" {
  count             = var.enable_ssh_access ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  security_group_id = aws_security_group.application.id
  description       = "Allow SSH access from specified CIDR blocks"
}

# Application Egress Rule - Allow all outbound traffic
resource "aws_security_group_rule" "app_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application.id
  description       = "Allow all outbound traffic"
}

# Database Security Group (optional, for future use)
resource "aws_security_group" "database" {
  count       = var.create_database_sg ? 1 : 0
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for database instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-sg"
    }
  )
}

# Database Ingress Rule - From Application
resource "aws_security_group_rule" "db_app_ingress" {
  count                    = var.create_database_sg ? 1 : 0
  type                     = "ingress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.database[0].id
  description              = "Allow traffic from application instances"
}

# Database Egress Rule - Allow all outbound traffic
resource "aws_security_group_rule" "db_egress" {
  count             = var.create_database_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database[0].id
  description       = "Allow all outbound traffic"
}
