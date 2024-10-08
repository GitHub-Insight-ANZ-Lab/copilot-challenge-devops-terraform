variable "prefix" {
  description = "Prefix for all resources"
}

variable "location" {
  description = "Region to create resources"
}

variable "admin_password" {
  description = "Virtual Machine admin password"
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  type        = string
}

variable "sql_connection_string" {
  description = "SQL Database connection string"
  type        = string
}

variable "sql_server_name" {
  description = "The name of the SQL Server."
  type        = string
}

variable "sql_database_name" {
  description = "The name of the SQL Database."
  type        = string
}

variable "sql_admin_username" {
  description = "The administrator username for the SQL Server."
  type        = string
}

variable "sql_admin_password" {
  description = "The administrator password for the SQL Server."
  type        = string
}

variable "environment" {
  description = "The environment for resource deployment (e.g., dev, staging, prod)"
  type        = string
}