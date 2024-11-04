resource "aws_wafv2_web_acl" "waf_fe_alb" {
  # Cấu hình Web ACL
  name        = "waf-fe-alb"
  description = "WAFv2 Web ACL with AWS Managed Rule Groups for FE ALB"
  scope       = "REGIONAL" 

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-fe-alb"
    sampled_requests_enabled   = true
  }

 # Thêm Managed Rule Group - AWSManagedRulesCommonRuleSet
  rule {
    name     = "AWS-Managed-CommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRuleSet"
    }
  }

  # Thêm Managed Rule Group - AWSManagedRulesKnownBadInputsRuleSet
  rule {
    name     = "AWS-Managed-KnownBadInputsRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSKnownBadInputsRuleSet"
    }
  }

  # Thêm Managed Rule Group - AWSManagedRulesSQLiRuleSet
  rule {
    name     = "AWS-Managed-SQLiRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSSQLiRuleSet"
    }
  }

  # Thêm Managed Rule Group - AWSManagedRulesLinuxRuleSet
  rule {
    name     = "AWS-Managed-LinuxRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesLinuxRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSLinuxRuleSet"
    }
  }

  # Thêm Managed Rule Group - AWSManagedRulesBotControlRuleSet
  rule {
    name     = "AWS-Managed-BotControlRuleSet"
    priority = 5
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesBotControlRuleSet"
      }
    }
    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSBotControlRuleSet"
    }
  }
}

resource "aws_wafv2_web_acl_association" "waf_fe_alb_association" {
  resource_arn = var.fe_alb_arn
  web_acl_arn  = aws_wafv2_web_acl.waf_fe_alb.arn
}