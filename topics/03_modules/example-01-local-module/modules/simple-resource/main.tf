# Модуль простого ресурса

resource "null_resource" "this" {
  triggers = {
    name        = var.resource_name
    environment = var.environment
    version     = var.app_version
  }
  
  provisioner "local-exec" {
    command = "echo 'Creating resource: ${var.resource_name} in ${var.environment}'"
  }
}

output "resource_id" {
  value       = null_resource.this.id
  description = "ID созданного ресурса"
}

output "resource_details" {
  value = {
    id          = null_resource.this.id
    name        = var.resource_name
    environment = var.environment
    version     = var.app_version
  }
  description = "Детали ресурса"
}
