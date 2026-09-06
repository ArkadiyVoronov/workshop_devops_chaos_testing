# Пример 2.2: Variables and Outputs

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "null" {}

# ============================================
# ПЕРЕМЕННЫЕ (variables.tf)
# ============================================

variable "project_name" {
  description = "Название проекта"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Окружение (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  description = "Количество инстансов"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "instance_type" {
  description = "Тип инстанса"
  type        = string
  default     = "t3.micro"
}

variable "enabled_features" {
  description = "Список включенных функций"
  type        = list(string)
  default     = ["monitoring"]
}

variable "custom_tags" {
  description = "Дополнительные теги"
  type        = map(string)
  default     = {}
}

variable "enable_backup" {
  description = "Включить резервное копирование"
  type        = bool
  default     = true
}

# ============================================
# ЛОКАЛЬНЫЕ ПЕРЕМЕННЫЕ (locals.tf)
# ============================================

locals {
  # Объединение тегов
  common_tags = merge(
    var.custom_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      CreatedAt   = timestamp()
    }
  )
  
  # Вычисляемое имя ресурса
  resource_name = "${var.project_name}-${var.environment}"
  
  # Конфигурация в виде объекта
  config = {
    name           = local.resource_name
    count          = var.instance_count
    type           = var.instance_type
    features       = var.enabled_features
    backup_enabled = var.enable_backup
    tags           = local.common_tags
    hash           = md5(local.summary)
  }
  
  # Форматированный вывод
  summary = "Project: ${var.project_name} | Env: ${var.environment} | Instances: ${var.instance_count}"
}

# ============================================
# РЕСУРСЫ
# ============================================

# Ресурс 1: Основной конфигурационный ресурс
resource "null_resource" "main_config" {
  triggers = {
    project      = var.project_name
    environment  = var.environment
    instance_type = var.instance_type
    config_hash  = md5(local.summary)
  }
  
  provisioner "local-exec" {
    command = "echo 'Main config created for ${local.resource_name}'"
  }
}

# Ресурс 2: Инстансы (с использованием count)
resource "null_resource" "instances" {
  count = var.instance_count
  
  triggers = {
    instance_id  = count.index
    instance_type = var.instance_type
    features     = join(",", var.enabled_features)
  }
  
  depends_on = [null_resource.main_config]
  
  provisioner "local-exec" {
    command = "echo 'Instance ${count.index} of type ${var.instance_type} created'"
  }
}

# ============================================
# ВЫХОДНЫЕ ЗНАЧЕНИЯ (outputs.tf)
# ============================================

output "resource_config" {
  description = "Полная конфигурация ресурсов"
  value = {
    project       = var.project_name
    environment   = var.environment
    instance_type = var.instance_type
    count         = var.instance_count
    features      = var.enabled_features
    tags          = local.common_tags
    backup_enabled = var.enable_backup
  }
}

output "instance_ids" {
  description = "ID созданных инстансов"
  value       = null_resource.instances[*].id
}

output "summary" {
  description = "Краткая сводка"
  value       = local.summary
}

output "detailed_info" {
  description = "Подробная информация"
  value = {
    resource_name  = local.resource_name
    main_id        = null_resource.main_config.id
    instance_count = length(null_resource.instances)
    instance_ids   = null_resource.instances[*].id
    config_hash    = local.config.hash
  }
}
