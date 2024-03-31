resource "aws_cloudwatch_log_metric_filter" "http_200_adm" {
  name           = "http_200_adm"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code=2*, size]"
  log_group_name = "adm-access.log"

  metric_transformation {
    name      = "http_200_adm"
    namespace = "Admin_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_5xx_adm" {
  name           = "http_5xx_adm"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code=5*, size]"
  log_group_name = "adm-error.log"

  metric_transformation {
    name      = "http_5xx_adm"
    namespace = "Admin_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_4xx_adm" {
  name           = "http_4xx_adm"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code=4*, size]"
  log_group_name = "adm-error.log"

  metric_transformation {
    name      = "http_4xx_adm"
    namespace = "Admin_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_latency_adm" {
  name           = "http_latency_adm"
  pattern        = "[ip, id, user, timestamp, request_time, request, status_code, size]"
  log_group_name = "adm-access.log"

  metric_transformation {
    name      = "http_latency_adm"
    namespace = "Admin_Metric"
    value     = "$request_time"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_request_adm" {
  name           = "http_request_adm"
  pattern        = "[ip, id, user, timestamp, request_time, request=*HTTP*, status_code, size]"
  log_group_name = "adm-access.log"

  metric_transformation {
    name      = "http_request_adm"
    namespace = "Admin_Metric"
    value     = "1"
  }
}
