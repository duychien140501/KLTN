resource "aws_cloudwatch_log_metric_filter" "http_request_be" {
  name           = "http_request_be"
  pattern        = "\"http-nio\""
  log_group_name = "backend.log"

  metric_transformation {
    name      = "http_request_be"
    namespace = "Backend_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_request_error_be" {
  name           = "http_request_error_be"
  pattern        = "\"ERROR\" \"http-nio\""
  log_group_name = "backend.log"

  metric_transformation {
    name      = "http_request_error_be"
    namespace = "Backend_Metric"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "number_exception_be" {
  name           = "number_exception_be"
  pattern        = "exception"
  log_group_name = "backend.log"

  metric_transformation {
    name      = "number_exception_be"
    namespace = "Backend_Metric"
    value     = "1"
  }
}
