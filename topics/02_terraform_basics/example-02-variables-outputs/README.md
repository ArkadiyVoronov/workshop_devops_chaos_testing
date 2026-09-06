# Пример 2.2: Variables and Outputs - Переменные и типы данных

## 🎯 Что проверяем

Этот пример демонстрирует работу с **переменными, locals и outputs**:
- Объявление переменных разных типов (string, number, bool, list, map)
- Значения по умолчанию и переопределение через `-var`
- Локальные переменные (`locals`)
- Выходные значения с различными типами
- Валидация переменных

## 📚 Концепции для экзамена

### 1. Типы переменных
```hcl
variable "instance_count" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {
    Environment = "dev"
    Owner       = "team-a"
  }
}
```

### 2. Locals (локальные переменные)
```hcl
locals {
  common_tags = merge(var.tags, {
    Project     = "certification-prep"
    ManagedBy   = "terraform"
  })
}
```

### 3. Переопределение переменных
```bash
# Через флаг -var
terraform apply -var "instance_count=5"

# Через файл .tfvars
terraform apply -var-file="production.tfvars"

# Через переменные окружения
export TF_VAR_instance_count=5
```

### 4. Валидация
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

## 🔧 Запуск примера

```bash
# Базовый запуск (с значениями по умолчанию)
./run.sh

# С переопределением переменных
terraform apply -var "environment=prod" -var "instance_count=5"

# С файлом переменных
terraform apply -var-file="custom.tfvars"
```

## 📊 Ожидаемый результат

### После `terraform plan`:
```
Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + resource_config = {
      + count        = 2
      + environment  = "dev"
      + full_name    = "Project: myapp | Env: dev"
      + instance_type = "t3.micro"
      + tags         = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Owner"       = "team-a"
          + "Project"     = "certification-prep"
        }
    }
```

### После `terraform apply`:
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

resource_config = {
  "count" = 2
  "environment" = "dev"
  "full_name" = "Project: myapp | Env: dev"
  "instance_type" = "t3.micro"
  "tags" = {
    "Environment" = "dev"
    "ManagedBy" = "terraform"
    "Owner" = "team-a"
    "Project" = "certification-prep"
  }
}
```

## 💡 Ключевые моменты для экзамена

1. **Приоритет переменных** (от высшего к низшему):
   - `-var` flag
   - `-var-file`
   - `*.auto.tfvars`
   - `terraform.tfvars`
   - Переменные окружения `TF_VAR_*`
   - Значения по умолчанию в `variables.tf`

2. **Типы данных**:
   - Примитивные: `string`, `number`, `bool`
   - Коллекции: `list`, `map`, `set`, `tuple`, `object`

3. **Locals vs Variables**:
   - `variable` - входные параметры (можно переопределить)
   - `locals` - вычисляемые значения внутри конфигурации

## ❓ Вопросы для самопроверки

1. Какой приоритет у `-var` флага?
   - Ответ: Самый высокий

2. Как передать переменную через окружение?
   - Ответ: `export TF_VAR_name=value`

3. В чем разница между `var.name` и `local.name`?
   - Ответ: `var` - входные данные, `local` - вычисляемые внутри

4. Можно ли изменить тип переменной после объявления?
   - Ответ: Нет, тип должен быть совместим
