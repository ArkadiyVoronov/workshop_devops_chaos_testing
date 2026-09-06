# Версия 1.0.0 - Базовая функциональность

resource "null_resource" "app" {
  triggers = {
    name    = var.app_name
    version = "1.0.0"
  }
  
  provisioner "local-exec" {
    command = "echo '[v1.0.0] Deploying ${var.app_name}'"
  }
}

output "app_id" {
  value       = null_resource.app.id
  description = "ID приложения (v1)"
}

output "version" {
  value       = "1.0.0"
  description = "Версия модуля"
}
