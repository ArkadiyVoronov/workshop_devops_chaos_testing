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

# Использование версии 1.0.0 (старая версия)
module "app_v1" {
  source   = "./modules/simple-app/v1"
  app_name = "legacy-app"
}

# Использование версии 2.0.0 (новая версия с расширенными возможностями)
module "app_v2" {
  source   = "./modules/simple-app/v2"
  app_name = "modern-app"
  region   = "eu-central-1"
  replicas = 3
}

output "v1_app_id" {
  value       = module.app_v1.app_id
  description = "ID приложения v1"
}

output "v2_app_info" {
  value       = module.app_v2.app_info
  description = "Информация о приложении v2"
}

output "versions_used" {
  value = {
    v1_version = module.app_v1.version
    v2_version = module.app_v2.version
  }
  description = "Версии модулей"
}
