# Версия 2.0.0 - Добавлена поддержка регионов и реплик

resource "null_resource" "app" {
  triggers = {
    name     = var.app_name
    region   = var.region
    replicas = var.replicas
    version  = "2.0.0"
  }
  
  provisioner "local-exec" {
    command = "echo '[v2.0.0] Deploying ${var.replicas} replicas of ${var.app_name} to ${var.region}'"
  }
}

output "app_id" {
  value       = null_resource.app.id
  description = "ID приложения (v2)"
}

output "version" {
  value       = "2.0.0"
  description = "Версия модуля"
}

output "app_info" {
  value = {
    id       = null_resource.app.id
    name     = var.app_name
    region   = var.region
    replicas = var.replicas
  }
  description = "Информация о приложении"
}
