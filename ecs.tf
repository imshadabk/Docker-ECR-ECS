# Use default VPC & public subnets so the service can be internet-facing
data "aws_vpc" "default" {
default = true
}

data "aws_subnets" "public" {
filter {
name = "vpc-id"
values = [data.aws_vpc.default.id]
}
}

resource "aws_ecs_cluster" "this" {
name = "react-app-cluster"
}

resource "aws_ecs_task_definition" "app" {
family = "react-app-task"
network_mode = "awsvpc"
requires_compatibilities = ["FARGATE"]
cpu = "512"
memory = "1024"
execution_role_arn = aws_iam_role.ecs_task_execution.arn

container_definitions = jsonencode([
{
name = "react-app"
image = "435204303146.dkr.ecr.ap-south-1.amazonaws.com/react-app:latest"
essential = true
portMappings = [
{
containerPort = 80
hostPort = 80
protocol = "tcp"
}
]
}
])
}

resource "aws_security_group" "alb_sg" {
name = "react-app-alb-sg"
vpc_id = data.aws_vpc.default.id

ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
from_port = 3000
to_port = 3000
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}


egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_lb" "alb" {
name = "react-app-alb"
internal = false
load_balancer_type = "application"
security_groups = [aws_security_group.alb_sg.id]
subnets = data.aws_subnets.public.ids
}


resource "aws_lb_target_group" "tg" {
name = "react-app-tg"
port = 80
protocol = "HTTP"
vpc_id = data.aws_vpc.default.id
health_check {
path = "/"
matcher = "200-399"
interval = 30
timeout = 5
healthy_threshold = 2
unhealthy_threshold = 2
}
}

resource "aws_lb_listener" "http" {
load_balancer_arn = aws_lb.alb.arn
port = "80"
protocol = "HTTP"


default_action {
type = "forward"
target_group_arn = aws_lb_target_group.tg.arn
}
}

resource "aws_ecs_service" "app" {
name = "react-app-svc"
cluster = aws_ecs_cluster.this.id
task_definition = aws_ecs_task_definition.app.arn
desired_count = 1
launch_type = "FARGATE"

network_configuration {
subnets = data.aws_subnets.public.ids
assign_public_ip = true
security_groups = [aws_security_group.alb_sg.id]
}


load_balancer {
target_group_arn = aws_lb_target_group.tg.arn
container_name = "react-app"
container_port = 80
}


depends_on = [aws_lb_listener.http]
}