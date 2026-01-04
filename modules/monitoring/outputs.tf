# Monitoring Module Outputs

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "unhealthy_hosts_alarm_arn" {
  description = "ARN of the unhealthy hosts alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.unhealthy_hosts[0].arn : null
}

output "response_time_alarm_arn" {
  description = "ARN of the response time alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.target_response_time[0].arn : null
}

output "http_5xx_alarm_arn" {
  description = "ARN of the HTTP 5xx alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.http_5xx[0].arn : null
}

output "http_4xx_alarm_arn" {
  description = "ARN of the HTTP 4xx alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.http_4xx[0].arn : null
}
