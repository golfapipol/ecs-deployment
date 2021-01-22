#REGION
variable "access_key" {

}
variable "secret_key" {

}
variable "aws_region" {
  default = "ap-northeast-1"
}
variable "vpc_id" {

}
# ALB
variable "aws_alb_name" {

}
variable "aws_alb_target_group" {

}

# Cluster
variable "cluster_name" {

}
variable "lb_group_id" {

}

#ECS
variable "command" {

}
variable "service_name" {

}
variable "container_name" {

}
variable "ecs_task_execution_role_name" {

}
variable "ecs_task_sg" {

}
variable "aws_vpc_id" {

}
variable "app_image" {

}
variable "fargate_cpu" {

}
variable "fargate_memory" {

}
variable "app_port" {

}
variable "secrets" {

}