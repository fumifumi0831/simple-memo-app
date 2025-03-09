provider "azurerm" {
  subscription_id = ""
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "simple-memo-app-rg"
  location = var.location
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "simplememoappacr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = true
}

# App Service Plan for Development
resource "azurerm_service_plan" "dev" {
  name                = "simple-memo-app-sp-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# App Service Plan for Production
resource "azurerm_service_plan" "prod" {
  name                = "simple-memo-app-sp-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

# Development Backend App Service
resource "azurerm_linux_web_app" "backend_dev" {
  name                = "simple-memo-app-backend-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.dev.id

  site_config {
    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = "simple-memo-app-backend:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ENVIRONMENT"                         = "development"
    "SECRET_KEY"                          = var.secret_key
  }
}

# Development Frontend App Service
resource "azurerm_linux_web_app" "frontend_dev" {
  name                = "simple-memo-app-frontend-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.dev.id

  site_config {
    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = "simple-memo-app-frontend:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "NEXT_PUBLIC_API_URL"                 = "https://simple-memo-app-backend-dev.azurewebsites.net"
  }
}

# Production Backend App Service
resource "azurerm_linux_web_app" "backend_prod" {
  name                = "simple-memo-app-backend-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.prod.id

  site_config {
    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = "simple-memo-app-backend:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ENVIRONMENT"                         = "production"
    "SECRET_KEY"                          = var.secret_key
  }
}

# Production Frontend App Service
resource "azurerm_linux_web_app" "frontend_prod" {
  name                = "simple-memo-app-frontend-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.prod.id

  site_config {
    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = "simple-memo-app-frontend:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "NEXT_PUBLIC_API_URL"                 = "https://simple-memo-app-backend-prod.azurewebsites.net"
  }
}

# Staging Slot for Production Backend
resource "azurerm_linux_web_app_slot" "backend_prod_staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.backend_prod.id

  site_config {
    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = "simple-memo-app-backend:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ENVIRONMENT"                         = "staging"
    "SECRET_KEY"                          = var.secret_key
  }
}

# Staging Slot for Production Frontend
resource "azurerm_linux_web_app_slot" "frontend_prod_staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.frontend_prod.id

  site_config {
    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
      docker_image_name = "simple-memo-app-frontend:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "NEXT_PUBLIC_API_URL"                 = "https://simple-memo-app-backend-prod.azurewebsites.net"
  }
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "simple-memo-app-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}
