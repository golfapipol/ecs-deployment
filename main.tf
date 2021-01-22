provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region
}

# ALB
resource "aws_alb" "main" {
  name            = var.aws_alb_name
  subnets         = [var.subnet_id1,var.subnet_id2]
  security_groups = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "default" {
  name        = var.aws_alb_target_group
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
  }
}

resource "aws_alb_listener" "app_listener" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.default.id
    type             = "forward"
  }
}

resource "aws_security_group" "lb" {
  name = "load-balancer-sg-test"

  description = "controls access to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "80"
    to_port     = "80"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ECS
data "aws_ecs_cluster" "main" {
  cluster_name = var.cluster_name
}

module "container" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.21.0"
  container_name               = var.container_name
  container_image              = var.app_image
  container_cpu                = var.fargate_cpu
  container_memory             = var.fargate_memory
  container_memory_reservation = var.fargate_memory
  port_mappings = [
    {
      "containerPort" = var.app_port
      "hostPort"      = var.app_port
      "protocol"      = "tcp"
    }
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.default.name
      "awslogs-region"        = var.aws_region
      "awslogs-stream-prefix" = "ecs"
    }
    secretOptions = null
  }
  environment = [
    # {
    #     name  = k
    #     value = v
    # }
  ]
  secrets = []
}
resource "aws_ecs_task_definition" "default" {
  family                   = var.task_definition
  container_definitions    = module.container.json
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
}

resource "aws_ecs_service" "main" {
  launch_type = "FARGATE"

  task_definition = aws_ecs_task_definition.default.arn
  cluster         = aws_ecs_cluster.main.id
  name            = var.service_name
  desired_count   = 1

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = [var.private_subnet_id1, var.private_subnet_id2]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.default.id
    container_name   = var.container_name
    container_port   = var.app_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.default.0.arn
  }

  depends_on = [aws_alb_listener.app_listener]
}


resource "aws_service_discovery_private_dns_namespace" "default" {
  name        = "test"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "default" {
  count = 1
  name  = var.service_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.default.id
    
    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}



resource "aws_cloudwatch_log_group" "default" {
  name = "/ecs/${var.container_name}"

  tags = {
    Name = "/ecs/${var.container_name}"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = var.ecs_task_sg
  description = "allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = []
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_iam_role" "ecs_task_execution_role" {
  name = var.ecs_task_execution_role_name
}


