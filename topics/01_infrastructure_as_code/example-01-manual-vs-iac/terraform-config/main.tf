# Пример 1: Manual vs IaC - Terraform конфигурация

# Эта конфигурация использует null_resource для имитации создания реальной инфраструктуры.
# Не требует облачных провайдеров и работает локально.

terraform {
  required_version = ">= 1.5.0"
}

# Имитация виртуальной машины
resource "null_resource" "web_server" {
  triggers = {
    image     = "ubuntu-22.04"
    cpu       = "2"
    memory    = "4GB"
    disk      = "50GB"
  }
  
  provisioner "local-exec" {
    command = "echo 'Creating web server...'"
  }
}

# Имитация группы безопасности
resource "null_resource" "security_group" {
  triggers = {
    name = "web-sg"
  }
  
  depends_on = [null_resource.web_server]
  
  provisioner "local-exec" {
    command = "echo 'Configuring security group...'"
  }
}

# Имитация хранилища
resource "null_resource" "storage_account" {
  triggers = {
    name = "appdata-storage"
    type = "Standard_LRS"
  }
  
  provisioner "local-exec" {
    command = "echo 'Creating storage account...'"
  }
}

# Вывод информации о созданных ресурсах
output "infrastructure_summary" {
  value = {
    web_server_id      = null_resource.web_server.id
    security_group_id  = null_resource.security_group.id
    storage_account_id = null_resource.storage_account.id
    message            = "Infrastructure created successfully!"
  }
}
