# --- CloudWatch Dashboard para Monitoramento da Aplicação ---

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # --- Widget de Cabeçalho ---
      {
        type   = "text",
        width  = 24,
        height = 1,
        properties = {
          markdown = "## Dashboard de Monitoramento: ${var.project_name} (${var.environment})"
        }
      },
      # --- Métricas do Application Load Balancer ---
      {
        type   = "metric",
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/NetworkELB", "ActiveFlowCount", "LoadBalancer", aws_lb.main.name, { "label" = "Conexões Ativas" }],
            [".", "ConsumedLCUs", ".", ".", { "label" = "LCUs Consumidas" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          title   = "NLB: Conexões e Uso"
        }
      },
      {
        type   = "metric",
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/NetworkELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.nginx.name, { "label" = "Hosts Saudáveis (Nginx)" }],
            [".", "UnHealthyHostCount", ".", ".", { "label" = "Hosts Não Saudáveis (Nginx)" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          title   = "NLB: Saúde do Target Group (Nginx)"
        }
      },
      # --- Métricas do ECS Service (Nginx) ---
      {
        type   = "metric",
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.nginx.name, { "label" = "Uso de CPU (%)" }],
            [".", "MemoryUtilization", ".", ".", ".", ".", { "label" = "Uso de Memória (%)" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          title   = "ECS Service: Nginx Gateway"
        }
      },
      # --- Métricas do ECS Service (API) ---
      {
        type   = "metric",
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.api.name, { "label" = "Uso de CPU (%)" }],
            [".", "MemoryUtilization", ".", ".", ".", ".", { "label" = "Uso de Memória (%)" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          title   = "ECS Service: API Python"
        }
      },
      # --- Métricas do WAF ---
      {
        type   = "metric",
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "Region", var.aws_region, "WebACL", aws_wafv2_web_acl.main.name, "Rule", "ALL", { "label" = "Total de Requisições Bloqueadas" }],
            [".", "AllowedRequests", ".", ".", ".", ".", ".", ".", { "label" = "Total de Requisições Permitidas" }]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = var.aws_region,
          title   = "WAF: Requisições Bloqueadas vs Permitidas"
        }
      }
    ]
  })
}
