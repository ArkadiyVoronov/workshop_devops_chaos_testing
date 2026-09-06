variable "app_name" {
  description = "Имя приложения"
  type        = string
}

variable "replicas" {
  description = "Количество реплик"
  type        = number
  default     = 1
}

variable "region" {
  description = "Регион развертывания"
  type        = string
  default     = "us-east-1"
}
