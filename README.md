# Terraform Associate (004) Certification Prep

Репозиторий для подготовки к сертификации **HashiCorp Certified: Terraform Associate (004)**.

## 🎯 Цель

Покрыть все темы экзамена с практическими примерами, которые:
- ✅ Работают в GitHub Codespaces (минимальные ресурсы)
- ✅ Используют локальный бекенд и mock-провайдеры
- ✅ Быстро выполняются (без создания реальной инфраструктуры)
- ✅ Содержат подробные объяснения: что проверяем, что получаем

## 📚 Структура тем

### 1. Infrastructure as Code (IaC)
- `topics/01_infrastructure_as_code/` - Преимущества IaC, паттерны

### 2. Terraform Basics
- `topics/02_terraform_basics/` - Синтаксис, ресурсы, переменные, state

### 3. Modules
- `topics/03_modules/` - Создание и использование модулей

### 4. Interact with Terraform
- `topics/04_interact_with_terraform/` - CLI, workspace, import, state management

## 🚀 Быстрый старт

```bash
# Инициализация Terraform в примере
cd topics/02_terraform_basics/example-01-basic-resource
terraform init

# Проверка конфигурации
terraform validate

# Просмотр плана (без применения)
terraform plan

# Очистка
terraform destroy -auto-approve
```

## 📋 Темы экзамена (004)

| № | Тема | Вес | Статус |
|---|------|-----|--------|
| 1 | Understand infrastructure as code (IaC) concepts | 10% | 🟡 В работе |
| 2 | Understand Terraform's purpose | 10% | 🟡 В работе |
| 3 | Understand Terraform basics | 25% | 🔴 Не начато |
| 4 | Use the Terraform CLI | 15% | 🔴 Не начато |
| 5 | Interact with Terraform modules | 15% | 🔴 Не начато |
| 6 | Navigate Terraform workflow | 15% | 🔴 Не начато |
| 7 | Implement and maintain state | 10% | 🔴 Не начато |
| 8 | Read, generate, and modify configuration | 10% | 🔴 Не начато |

🟢 Готово | 🟡 В работе | 🔴 Не начато

## 🛠️ Требования

- Terraform >= 1.5.0
- GitHub Codespaces (рекомендуется) или локальная установка Terraform

## 📝 Формат каждого примера

Каждый пример содержит:
1. `main.tf` - Конфигурация Terraform
2. `README.md` - Объяснение:
   - Что проверяем
   - Ключевые концепции
   - Ожидаемый результат
3. `run.sh` - Скрипт для быстрого запуска
4. `expected_output.txt` - Пример вывода

## 🤝 Contributing

Этот репозиторий создан для обучения. Pull requests приветствуются!

## 📄 License

MIT License
