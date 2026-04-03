variable "project_name" {
  default = "ecs-devops-project"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "app_port" {
  default = 5000
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  default     = 5
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  default     = 10
}
