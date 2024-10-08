provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "sql_admin_username" {
  description = "The administrator username for the SQL server"
  type        = string
}

variable "sql_admin_password" {
  description = "The administrator password for the SQL server"
  type        = string
}

variable "environment" {
  description = "The environment tag for the resources"
  type        = string
}

resource "azurerm_sql_server" "main" {
  name                         = "${var.prefix}-sql-server"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  tags = {
    environment = var.environment
  }
}

resource "azurerm_sql_database" "main" {
  name                = "${var.prefix}-sql-database"
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_sql_server.main.name
  edition             = "Basic"
  requested_service_objective_name = "Basic"

  tags = {
    environment = var.environment
  }
}

output "sql_connection_string" {
  value = format(
    "%s@%s;password=%s;server=%s;database=%s;",
    azurerm_sql_server.main.administrator_login,
    azurerm_sql_server.main.name,
    var.sql_admin_password,
    azurerm_sql_server.main.fully_qualified_domain_name,
    azurerm_sql_database.main.name
  )
}