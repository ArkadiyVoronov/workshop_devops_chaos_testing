# Пример 2.1: Basic Resource - Синтаксис и структура

## 🎯 Что проверяем

Этот пример демонстрирует **базовый синтаксис Terraform** и работу с ресурсами:
- Структура блока `terraform` и `provider`
- Объявление ресурсов с помощью `resource`
- Использование `null_provider` для локальной работы без облака
- Зависимости между ресурсами (`depends_on`)
- Базовые выходы (`output`)

## 📚 Концепции для экзамена

### 1. Блок terraform
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
```
**Зачем:** Определяет версию Terraform и требуемых провайдеров.

### 2. Блок provider
```hcl
provider "null" {}
```
**Зачем:** Инициализирует провайдер (в данном случае null - для тестов).

### 3. Блок resource
```hcl
resource "null_resource" "example" {
  triggers = {
    key = "value"
  }
}
```
**Зачем:** Описывает инфраструктурный объект. `null_resource` не создает реальных ресурсов.

### 4. Зависимости
```hcl
depends_on = [null_resource.parent]
```
**Зачем:** Явно указывает порядок создания ресурсов.

## 🔧 Запуск примера

```bash
# Инициализация (загружает провайдер null)
terraform init

# Проверка конфигурации
terraform validate

# Просмотр плана выполнения
terraform plan

# Применение конфигурации
terraform apply -auto-approve

# Проверка состояния
terraform show

# Уничтожение ресурсов
terraform destroy -auto-approve
```

## 📊 Ожидаемый результат

### После `terraform plan`:
```
Terraform will perform the following actions:

  # null_resource.web_server will be created
  + resource "null_resource" "web_server" {
      + id       = (known after apply)
      + triggers = {
          + image  = "ubuntu-22.04"
          + cpu    = "2"
          + memory = "4GB"
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

### После `terraform apply`:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

infrastructure_info = {
  "message" = "Basic resources created successfully!"
  "resource_count" = 3
  "web_server_id" = "1234567890"
}
```

### После `terraform show`:
```
# null_resource.web_server:
resource "null_resource" "web_server" {
    id = "1234567890"
    triggers = {
        "cpu" = "2"
        "image" = "ubuntu-22.04"
        "memory" = "4GB"
    }
}
```

## 💡 Ключевые моменты для экзамена

1. **Идемпотентность**: Повторный `terraform apply` не вносит изменений, если конфигурация не изменилась.
2. **State файл**: Создается `terraform.tfstate` после применения.
3. **Провайдеры**: Загружаются при `terraform init`.
4. **Ресурсы**: Создаются в порядке зависимостей.

## ❓ Вопросы для самопроверки

1. Какой командой загружаются провайдеры?
   - Ответ: `terraform init`

2. Где хранится состояние инфраструктуры?
   - Ответ: В файле `terraform.tfstate`

3. Что делает `depends_on`?
   - Ответ: Явно задает порядок создания ресурсов

4. Почему используем `null_resource`?
   - Ответ: Для тестирования без создания реальной инфраструктуры
