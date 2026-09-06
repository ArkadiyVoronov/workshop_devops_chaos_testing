# Модуль простого приложения с переменными

resource "null_resource" "app" {
  triggers = {
    name     = var.app_name
    replicas = var.replicas
    region   = var.region
  }
  
  provisioner "local-exec" {
    command = "echo 'Deploying ${var.replicas} replicas of ${var.app_name} to ${var.region}'"
  }
}

output "app_id" {
  value       = null_resource.app.id
  description = "ID приложения"
}

output "app_info" {
  value = {
    id       = null_resource.app.id
    name     = var.app_name
    replicas = var.replicas
    region   = var.region
  }
  description = "Информация о приложении"
}
