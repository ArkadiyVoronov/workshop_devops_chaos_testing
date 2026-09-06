# Пример 3.1: Local Module - Создание локального модуля

## 🎯 Что проверяем

Этот пример демонстрирует **создание и использование локального модуля**:
- Структура модуля (main.tf, variables.tf, outputs.tf)
- Вызов модуля из основной конфигурации
- Передача переменных в модуль
- Получение выходных значений от модуля
- Множественное использование одного модуля

## 📚 Концепции для экзамена

### 1. Структура модуля
```
modules/
└── simple-resource/
    ├── main.tf        # Ресурсы
    ├── variables.tf   # Входные параметры
    └── outputs.tf     # Выходные значения
```

### 2. Вызов модуля
```hcl
module "web_server" {
  source = "./modules/simple-resource"
  
  resource_name = "web-server-prod"
  environment   = "production"
}
```

### 3. Доступ к output модуля
```hcl
output "server_id" {
  value = module.web_server.resource_id
}
```

### 4. Множественные экземпляры
```hcl
module "server_1" {
  source        = "./modules/simple-resource"
  resource_name = "server-1"
}

module "server_2" {
  source        = "./modules/simple-resource"
  resource_name = "server-2"
}
```

## 🔧 Запуск примера

```bash
# Запустить пример
./run.sh

# Вручную
terraform init
terraform plan
terraform apply
terraform destroy
```

## 📊 Ожидаемый результат

### После `terraform plan`:
```
Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + all_resources = [
      + {
          + environment = "dev"
          + id          = (known after apply)
          + name        = "app-server-1"
        },
      + {
          + environment = "prod"
          + id          = (known after apply)
          + name        = "app-server-2"
        }
    ]
```

### После `terraform apply`:
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

all_resources = [
  {
    "environment" = "dev"
    "id" = "1234567890"
    "name" = "app-server-1"
  },
  {
    "environment" = "prod"
    "id" = "0987654321"
    "name" = "app-server-2"
  }
]
```

## 💡 Ключевые моменты для экзамена

1. **source** - обязательный аргумент модуля
2. **Модули изолированы** - каждый имеет свой namespace
3. **Output модуля** - единственный способ получить данные из модуля
4. **Локальные пути** начинаются с `./` или `../`

## ❓ Вопросы для самопроверки

1. Как указать путь к локальному модулю?
   - Ответ: `source = "./modules/name"`

2. Как получить output из модуля?
   - Ответ: `module.module_name.output_name`

3. Обязательно ли создавать variables.tf в модуле?
   - Ответ: Нет, но это best practice

4. Можно ли использовать один модуль несколько раз?
   - Ответ: Да, с разными параметрами
