variable "project_name" {
  default = "ecs-devops-project"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "app_port" {
  description = "Front-end app port"
  default     = 8079
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  default     = 10
}

# RabbitMQ
variable "rabbitmq_amqp_port" {
  description = "RabbitMQ AMQP port"
  default     = 5672
}

variable "rabbitmq_mgmt_port" {
  description = "RabbitMQ Management UI port"
  default     = 15672
}

# Queue Master
variable "queue_master_port" {
  description = "Queue Master port"
  default     = 80
}

# Payment
variable "payment_port" {
  description = "Payment service port"
  default     = 80
}

# Shipping
variable "shipping_port" {
  description = "Shipping service port"
  default     = 80
}
