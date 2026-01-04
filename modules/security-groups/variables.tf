# Security Groups Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "application_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 80
  validation {
    condition     = var.application_port > 0 && var.application_port < 65536
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "enable_https" {
  description = "Enable HTTPS listener on ALB"
  type        = bool
  default     = true
}

variable "enable_ssh_access" {
  description = "Enable SSH access to application instances"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to instances"
  type        = list(string)
  default     = []
}

variable "create_database_sg" {
  description = "Create security group for database"
  type        = bool
  default     = false
}

variable "database_port" {
  description = "Port on which the database listens"
  type        = number
  default     = 3306
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
