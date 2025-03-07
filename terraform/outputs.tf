output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.acr.admin_password
  sensitive = true
}

output "app_service_backend_dev_url" {
  value = "https://${azurerm_linux_web_app.backend_dev.default_hostname}"
}

output "app_service_frontend_dev_url" {
  value = "https://${azurerm_linux_web_app.frontend_dev.default_hostname}"
}

output "app_service_backend_prod_url" {
  value = "https://${azurerm_linux_web_app.backend_prod.default_hostname}"
}

output "app_service_frontend_prod_url" {
  value = "https://${azurerm_linux_web_app.frontend_prod.default_hostname}"
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
