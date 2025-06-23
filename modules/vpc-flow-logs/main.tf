resource "aws_cloudwatch_log_group" "flow_logs" {
  name = var.log_group_name

  tags = var.common_tags
}

resource "aws_flow_log" "this" {
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id

  tags = var.common_tags
} 