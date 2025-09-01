# --- Security Group do ALB ---
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group para o Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# --- Security Group do Nginx ---
resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-nginx-sg"
  description = "Security group para o servico Nginx"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-nginx-sg"
  }
}

# --- Security Group da API ---
resource "aws_security_group" "api" {
  name        = "${var.project_name}-api-sg"
  description = "Security group para o servico da API Python"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5000 # A porta que a aplicação Python escuta
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-api-sg"
  }
}
