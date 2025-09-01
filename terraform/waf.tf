# --- Conjunto de IPs para bloqueio (exemplo) ---
resource "aws_wafv2_ip_set" "blocked_ips" {
  name        = "${var.project_name}-blocked-ips"
  scope       = "REGIONAL"
  ip_address_version = "IPV4"
  addresses   = ["192.0.2.44/32"] # Exemplo de IP a ser bloqueado
}

# --- AWS WAFv2 Web ACL Simplificada ---
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-waf-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Regra para bloquear IPs do nosso IP Set
  rule {
    name     = "BlockFromIPSet"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-waf-ip-block"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-waf-acl"
    Environment = var.environment
  }
}

# --- Associação da WAF com o NLB ---
# Nota: WAFv2 não suporta Network Load Balancer
# resource "aws_wafv2_web_acl_association" "main" {
#   resource_arn = aws_lb.main.arn
#   web_acl_arn  = aws_wafv2_web_acl.main.arn
# }
