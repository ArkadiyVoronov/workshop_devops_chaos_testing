# Пример 2.1: Basic Resource - Синтаксис и структура

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

# Ресурс 1: Имитация веб-сервера
resource "null_resource" "web_server" {
  triggers = {
    image  = "ubuntu-22.04"
    cpu    = "2"
    memory = "4GB"
  }
  
  provisioner "local-exec" {
    command = "echo 'Web server created with Ubuntu 22.04'"
  }
}

# Ресурс 2: Имитация базы данных (зависит от веб-сервера)
resource "null_resource" "database" {
  triggers = {
    engine = "postgresql"
    version = "15"
  }
  
  depends_on = [null_resource.web_server]
  
  provisioner "local-exec" {
    command = "echo 'Database created after web server'"
  }
}

# Ресурс 3: Имитация сети
resource "null_resource" "network" {
  triggers = {
    cidr = "10.0.0.0/16"
  }
  
  provisioner "local-exec" {
    command = "echo 'Network configured'"
  }
}

# Выходные значения
output "infrastructure_info" {
  value = {
    message        = "Basic resources created successfully!"
    resource_count = 3
    web_server_id  = null_resource.web_server.id
    database_id    = null_resource.database.id
    network_id     = null_resource.network.id
  }
}

output "web_server_details" {
  value = {
    id     = null_resource.web_server.id
    image  = null_resource.web_server.triggers.image
    cpu    = null_resource.web_server.triggers.cpu
    memory = null_resource.web_server.triggers.memory
  }
}
