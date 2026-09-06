# Тема 3: Modules (15% экзамена)

## Обзор темы

Эта тема покрывает работу с **модулями Terraform**:
- Создание локальных модулей
- Использование модулей из реестра
- Передача переменных в модули
- Выходные значения модулей
- Версионирование модулей
- Best practices для модулей

## Примеры в этой теме

| № | Пример | Концепции | Статус |
|---|--------|-----------|--------|
| 1 | `example-01-local-module` | Создание простого локального модуля | ✅ Создан |
| 2 | `example-02-module-variables` | Переменные и outputs в модулях | ✅ Создан |
| 3 | `example-03-module-versioning` | Версионирование и best practices | ✅ Создан |

## Ключевые концепции для экзамена

### 1. Структура модуля
```
modules/
└── my-module/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### 2. Вызов модуля
```hcl
module "web_server" {
  source = "./modules/web-server"
  
  instance_count = 3
  instance_type  = "t3.micro"
}
```

### 3. Источники модулей
- Локальные: `./modules/name`
- Terraform Registry: `hashicorp/consul/aws`
- GitHub: `github.com/org/repo`
- Git (общий): `git::https://...`

### 4. Версионирование
```hcl
module "app" {
  source  = "app-terraform.io/org/app/aws"
  version = "~> 1.0"
}
```

## Быстрый старт

```bash
# Запустить все примеры темы
cd topics/03_modules
./run_all.sh

# Или отдельный пример
cd example-01-local-module
./run.sh
```
