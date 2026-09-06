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

# Пример 1: Использование переменных по умолчанию
module "app_default" {
  source   = "./modules/simple-app"
  app_name = "my-app-default"
}

# Пример 2: Переопределение всех переменных
module "app_custom" {
  source   = "./modules/simple-app"
  app_name = "my-app-custom"
  replicas = 5
  region   = "eu-west-1"
}

# Пример 3: Частичное переопределение (только replicas)
module "app_scaled" {
  source   = "./modules/simple-app"
  app_name = "my-app-scaled"
  replicas = 10
  # region использует значение по умолчанию (us-east-1)
}

output "all_apps" {
  value = [
    module.app_default.app_info,
    module.app_custom.app_info,
    module.app_scaled.app_info
  ]
  description = "Информация о всех приложениях"
}
