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

# Вызов модуля для dev окружения
module "app_server_dev" {
  source = "./modules/simple-resource"
  
  resource_name = "app-server-dev"
  environment   = "dev"
  app_version   = "1.0.0"
}

# Вызов модуля для prod окружения
module "app_server_prod" {
  source = "./modules/simple-resource"
  
  resource_name = "app-server-prod"
  environment   = "production"
  app_version   = "2.0.0"
}

# Вывод информации о всех ресурсах
output "all_resources" {
  value = [
    module.app_server_dev.resource_details,
    module.app_server_prod.resource_details
  ]
  description = "Информация о всех созданных ресурсах"
}

output "dev_server_id" {
  value       = module.app_server_dev.resource_id
  description = "ID dev сервера"
}

output "prod_server_id" {
  value       = module.app_server_prod.resource_id
  description = "ID prod сервера"
}
