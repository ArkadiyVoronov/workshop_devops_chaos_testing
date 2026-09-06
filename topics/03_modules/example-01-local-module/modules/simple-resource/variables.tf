variable "resource_name" {
  description = "Имя ресурса"
  type        = string
}

variable "environment" {
  description = "Окружение"
  type        = string
  default     = "dev"
}

variable "app_version" {
  description = "Версия приложения"
  type        = string
  default     = "1.0.0"
}
