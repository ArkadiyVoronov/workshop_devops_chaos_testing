# Пример 2.3: State Management

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

# Ресурс 1
resource "null_resource" "resource1" {
  triggers = {
    name = "resource-1"
    type = "primary"
  }
  
  provisioner "local-exec" {
    command = "echo 'Resource 1 created'"
  }
}

# Ресурс 2
resource "null_resource" "resource2" {
  triggers = {
    name = "resource-2"
    type = "secondary"
  }
  
  depends_on = [null_resource.resource1]
  
  provisioner "local-exec" {
    command = "echo 'Resource 2 created'"
  }
}

# Ресурс 3
resource "null_resource" "resource3" {
  triggers = {
    name = "resource-3"
    type = "tertiary"
  }
  
  depends_on = [null_resource.resource2]
  
  provisioner "local-exec" {
    command = "echo 'Resource 3 created'"
  }
}

output "resources_created" {
  value = {
    count = 3
    ids = [
      null_resource.resource1.id,
      null_resource.resource2.id,
      null_resource.resource3.id
    ]
    names = [
      null_resource.resource1.triggers.name,
      null_resource.resource2.triggers.name,
      null_resource.resource3.triggers.name
    ]
  }
}
