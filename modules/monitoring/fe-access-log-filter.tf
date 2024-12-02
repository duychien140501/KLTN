resource "aws_cloudwatch_log_metric_filter" "http_200_fe" {
  name           = "http_200_fe"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code=2*, size]"
  log_group_name = "fe-access.log"

  metric_transformation {
    name      = "http_200_fe"
    namespace = "Frontend_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_5xx_fe" {
  name           = "http_5xx_fe"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code=5*, size]"
  log_group_name = "fe-error.log"

  metric_transformation {
    name      = "http_5xx_fe"
    namespace = "Frontend_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_4xx_fe" {
  name           = "http_4xx_fe"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code=4*, size]"
  log_group_name = "fe-error.log"

  metric_transformation {
    name      = "http_4xx_fe"
    namespace = "Frontend_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_latency_fe" {
  name           = "http_latency_fe"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code, size]"
  log_group_name = "fe-access.log"

  metric_transformation {
    name      = "http_latency_fe"
    namespace = "Frontend_Metric"
    value     = "$request_time"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_request_fe" {
  name           = "http_request_fe"
  pattern        = "[ip, id, user, timestamp, request_time, request=*HTTP*, status_code, size]"
  log_group_name = "fe-access.log"

  metric_transformation {
    name      = "http_request_fe"
    namespace = "Frontend_Metric"
    value     = "1"
  }
}
