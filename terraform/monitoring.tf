resource "aws_cloudwatch_log_group" "listener" {
  name              = "/soar/listener"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "os_secure" {
  name              = "/soar/os-secure"
  retention_in_days = 7
}

# SOAR health (P2-09): every rule match line counts as a processed event
resource "aws_cloudwatch_log_metric_filter" "events_processed" {
  name           = "soar-events-processed"
  log_group_name = aws_cloudwatch_log_group.listener.name
  pattern        = "\"rule=\""
  metric_transformation {
    name          = "EventsProcessed"
    namespace     = "SOAR"
    value         = "1"
    default_value = 0
  }
}

# A failed action appears as False in the rule line
resource "aws_cloudwatch_log_metric_filter" "action_failures" {
  name           = "soar-action-failures"
  log_group_name = aws_cloudwatch_log_group.listener.name
  pattern        = "\"False\""
  metric_transformation {
    name          = "ActionFailures"
    namespace     = "SOAR"
    value         = "1"
    default_value = 0
  }
}

# Second log source: OS authentication log
resource "aws_cloudwatch_log_metric_filter" "os_failed_logins" {
  name           = "soar-os-failed-logins"
  log_group_name = aws_cloudwatch_log_group.os_secure.name
  pattern        = "\"Failed password\""
  metric_transformation {
    name          = "OSFailedLogins"
    namespace     = "SOAR"
    value         = "1"
    default_value = 0
  }
}

# Alerts (P2-07): each one sends to the SNS topic
resource "aws_cloudwatch_metric_alarm" "action_failures" {
  alarm_name          = "soar-action-failures"
  namespace           = "SOAR"
  metric_name         = "ActionFailures"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "os_failed_logins" {
  alarm_name          = "soar-os-failed-logins"
  namespace           = "SOAR"
  metric_name         = "OSFailedLogins"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 3
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "nodes_down" {
  alarm_name          = "soar-nodes-down"
  namespace           = "AWS/AutoScaling"
  metric_name         = "GroupInServiceInstances"
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.soar.name }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 2
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "node_cpu" {
  alarm_name          = "soar-node-cpu-high"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.soar.name }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 70
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Dashboard (P2-09): SOAR health next to platform and database health
resource "aws_cloudwatch_dashboard" "soar" {
  dashboard_name = "soar-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      { type = "metric", x = 0, y = 0, width = 12, height = 6,
        properties = { title = "Node CPU (ASG average)", period = 60, stat = "Average", region = var.region,
      metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.soar.name]] } },
      { type = "metric", x = 12, y = 0, width = 12, height = 6,
        properties = { title = "Nodes in service", period = 60, stat = "Minimum", region = var.region,
      metrics = [["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.soar.name]] } },
      { type = "metric", x = 0, y = 6, width = 12, height = 6,
        properties = { title = "SOAR events processed", period = 300, stat = "Sum", region = var.region,
      metrics = [["SOAR", "EventsProcessed"]] } },
      { type = "metric", x = 12, y = 6, width = 12, height = 6,
        properties = { title = "SOAR action failures", period = 300, stat = "Sum", region = var.region,
      metrics = [["SOAR", "ActionFailures"]] } },
      { type = "metric", x = 0, y = 12, width = 12, height = 6,
        properties = { title = "OS failed logins (second log source)", period = 300, stat = "Sum", region = var.region,
      metrics = [["SOAR", "OSFailedLogins"]] } },
      { type = "metric", x = 12, y = 12, width = 12, height = 6,
        properties = { title = "Database CPU and free storage", period = 300, stat = "Average", region = var.region,
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.postgres.identifier],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.postgres.identifier]
      ] } }
    ]
  })
}