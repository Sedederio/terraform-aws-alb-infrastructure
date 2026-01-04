# Monitoring Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "sns_email_endpoints" {
  description = "List of email addresses for SNS notifications"
  type        = list(string)
  default     = []
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "unhealthy_host_threshold" {
  description = "Threshold for unhealthy host count alarm"
  type        = number
  default     = 1
}

variable "response_time_threshold" {
  description = "Threshold for target response time in seconds"
  type        = number
  default     = 1
}

variable "http_5xx_threshold" {
  description = "Threshold for HTTP 5xx errors"
  type        = number
  default     = 10
}

variable "http_4xx_threshold" {
  description = "Threshold for HTTP 4xx errors"
  type        = number
  default     = 50
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
