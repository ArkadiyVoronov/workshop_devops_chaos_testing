# Пример 2.3: State Management - Работа с состоянием

## 🎯 Что проверяем

Этот пример демонстрирует **управление state файлом** в Terraform:
- Структура state файла (`terraform.tfstate`)
- Команды работы с state (`terraform state list`, `show`, `mv`, `rm`)
- Backup state файла
- Refresh состояния
- Import ресурсов (симуляция)

## 📚 Концепции для экзамена

### 1. State файл
```json
{
  "version": 4,
  "terraform_version": "1.9.0",
  "resources": [
    {
      "mode": "managed",
      "type": "null_resource",
      "name": "example",
      "provider": "provider[\"registry.terraform.io/hashicorp/null\"]",
      "instances": [...]
    }
  ]
}
```

### 2. Основные команды state
```bash
# Показать все ресурсы в state
terraform state list

# Показать детали ресурса
terraform state show null_resource.example

# Переименовать ресурс в state
terraform state mv null_resource.old null_resource.new

# Удалить ресурс из state (не уничтожая)
terraform state rm null_resource.example
```

### 3. Refresh
```bash
# Обновить state без изменения инфраструктуры
terraform refresh

# Plan с refresh (по умолчанию в TF 1.1+)
terraform plan
```

### 4. Backup
- Автоматический backup: `terraform.tfstate.backup`
- Создается при каждом изменении state

## 🔧 Запуск примера

```bash
# Запустить полный пример
./run.sh

# Отдельные команды
terraform init
terraform apply -auto-approve
terraform state list
terraform state show null_resource.resource1
terraform refresh
```

## 📊 Ожидаемый результат

### После `terraform state list`:
```
null_resource.resource1
null_resource.resource2
null_resource.resource3
```

### После `terraform state show null_resource.resource1`:
```
resource "null_resource" "resource1" {
    id = "1234567890"
    triggers = {
        "name" = "resource-1"
    }
}
```

### После `terraform refresh`:
```
null_resource.resource1: Refreshing state... [id=...]
null_resource.resource2: Refreshing state... [id=...]
null_resource.resource3: Refreshing state... [id=...]

No changes. Your infrastructure matches the configuration.
```

## 💡 Ключевые моменты для экзамена

1. **State файл хранит**:
   - Метаданные ресурсов
   - Значения атрибутов
   - Зависимости между ресурсами
   - Версию Terraform

2. **Локальный vs удаленный state**:
   - Локальный: файл на диске
   - Удаленный: S3, Azure Blob, GCS, Terraform Cloud

3. **Безопасность state**:
   - Содержит чувствительные данные
   - Требует защиты (шифрование, доступ)

4. **Locking**:
   - Предотвращает одновременные изменения
   - Автоматически при использовании удаленного бекенда

## ❓ Вопросы для самопроверки

1. Где хранится состояние по умолчанию?
   - Ответ: В локальном файле `terraform.tfstate`

2. Что делает `terraform refresh`?
   - Ответ: Обновляет state данными из реальной инфраструктуры

3. Зачем нужен backup state?
   - Ответ: Для восстановления при ошибках

4. Что происходит при `terraform state rm`?
   - Ответ: Ресурс удаляется из state, но не уничтожается физически
