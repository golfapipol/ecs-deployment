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

#ECS
variable "service_name" {

}
variable "container_name" {

}
variable "ecs_task_execution_role_name" {
  default = "ECSTaskExecutionRole"
}
variable "ecs_task_sg" {

}
variable "app_image" {

}
variable "fargate_cpu" {

}
variable "fargate_memory" {

}
variable "app_port" {

}
variable "host_zone_id" {
  
}
variable "subnet_id1" {
  
}
variable "subnet_id2" {
  
}