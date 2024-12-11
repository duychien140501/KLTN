resource "aws_cloudwatch_dashboard" "shopizer_dashboard" {
  dashboard_name = "shopizer-dashboard-${var.region}"

  dashboard_body = jsonencode({
    widgets = [
      # frontend graphs
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## Frontend Metric"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["Frontend_Metric", aws_cloudwatch_log_metric_filter.http_latency_fe.name, { "region" : "${var.region}" }]
          ]
          view     = "timeSeries"
          stacked  = false
          title    = "http_latency_fe"
          period   = 60
          stat     = "Average"
          width    = 1500
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "(m2+m3)/m1*100", "label" : "Expression1", "id" : "e1", "region" : "${var.region}" }],
            [{ "expression" : "m3/m1", "label" : "Expression2", "id" : "e2", "region" : "${var.region}", "visible" : false }],
            ["Frontend_Metric", aws_cloudwatch_log_metric_filter.http_200_fe.name, { "id" : "m1", "visible" : false, "region" : "${var.region}" }],
            ["Frontend_Metric", aws_cloudwatch_log_metric_filter.http_4xx_fe.name, { "id" : "m2", "visible" : false, "region" : "${var.region}" }],
            ["Frontend_Metric", aws_cloudwatch_log_metric_filter.http_5xx_fe.name, { "id" : "m3", "visible" : false, "region" : "${var.region}" }]
          ]
          sparkline = true
          view      = "timeSeries"
          stacked   = false
          stat      = "Sum"
          period    = 60
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          title    = "http_error_percent_fe"
          width    = 1500
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["Frontend_Metric", aws_cloudwatch_log_metric_filter.http_request_fe.name, { "region" : "${var.region}" }]
          ]
          view     = "timeSeries"
          stacked  = false
          period   = 60
          stat     = "Sum"
          title    = "http_request_fe"
          width    = 1500
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [for id in var.frontend_instance_ids :
          ["CWAgent", "mem_used_percent", "InstanceId", id, { "region" : "${var.region}" }]]
          view     = "timeSeries"
          stacked  = false
          title    = "Mem_used_percent_fe"
          period   = 60
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            for id in var.frontend_instance_ids :
            ["CWAgent", "disk_used_percent", "InstanceId", id, { "region" : "${var.region}" }]
          ]
          view     = "timeSeries"
          stacked  = false
          title    = "Disk_used_percent_fe"
          period   = 60
          width    = 1500
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            for id in var.frontend_instance_ids :
            ["AWS/EC2", "CPUUtilization", "InstanceId", id, { "region" : "${var.region}" }]
          ]
          view     = "timeSeries"
          stacked  = false
          title    = "CPUUtilization_fe"
          period   = 60
          width    = 1500
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      # backend graphs
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## Backend Metric"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "m2/m1*100", "label" : "Expression1", "id" : "m3", "region" : "${var.region}" }],
            ["Backend_Metric", aws_cloudwatch_log_metric_filter.http_request_be.name, { "region" : "${var.region}", "id" : "m1", "visible" : false }],
            ["Backend_Metric", aws_cloudwatch_log_metric_filter.http_request_error_be.name, { "region" : "${var.region}", "id" : "m2", "visible" : false }]
          ]
          view     = "timeSeries"
          stacked  = false
          stat     = "Sum"
          period   = 60
          title    = "http_error_percent_be"
          width    = 1695
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["Backend_Metric", aws_cloudwatch_log_metric_filter.number_exception_be.name, { "region" : "${var.region}" }]
          ]
          view     = "timeSeries"
          stacked  = false
          period   = 60
          stat     = "Sum"
          title    = "number_exception_be"
          width    = 1695
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [for id in var.backend_instance_ids :
          ["CWAgent", "mem_used_percent", "InstanceId", id, { "region" : "${var.region}" }]]
          view     = "timeSeries"
          stacked  = false
          title    = "Mem_used_percent_be"
          period   = 60
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            for id in var.backend_instance_ids :
            ["CWAgent", "disk_used_percent", "InstanceId", id, { "region" : "${var.region}" }]
          ]
          view     = "timeSeries"
          stacked  = false
          title    = "Disk_used_percent_be"
          period   = 60
          width    = 1500
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            for id in var.backend_instance_ids :
            ["AWS/EC2", "CPUUtilization", "InstanceId", id, { "region" : "${var.region}" }]
          ]
          view     = "timeSeries"
          stacked  = false
          title    = "CPUUtilization_be"
          period   = 60
          width    = 1500
          height   = 200
          start    = "-PT3H"
          end      = "P0D"
          timezone = "+0700"
          region   = "${var.region}"
        }
      },
    ]
  })
}
