// Resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

// Virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

// Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

// Public IP address
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

// Main network interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

// Internal network interface
resource "azurerm_network_interface" "internal" {
  name                      = "${var.prefix}-nic2"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}
// add key virtual_network_name
output "virtual_network_name" {
  value = azurerm_virtual_network.main.name
}

// security group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

// main network interface security group association
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

// virtual machine
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm1"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-vm1"
    admin_username = "adminuser"
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}


resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.prefix}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
}


resource "azurerm_application_insights" "main" {
  name                = "${var.prefix}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

resource "azurerm_storage_account" "main" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "main" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}


resource "azurerm_app_service" "react_frontend" {
  name                = "${var.prefix}-react-frontend"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id

  site_config {
    app_command_line = "npm start"
    linux_fx_version = "NODE|14-lts"
  }

  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "14-lts"
    APPINSIGHTS_INSTRUMENTATIONKEY = var.app_insights_instrumentation_key
  }

  depends_on = [
    azurerm_app_service_plan.main
  ]
}
resource "azurerm_function_app" "function_app" {
  name                = "${var.prefix}-function-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id
  storage_account_name = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = var.app_insights_instrumentation_key
    SQL_CONNECTION_STRING          = var.sql_connection_string
    AzureWebJobsStorage            = azurerm_storage_account.main.primary_connection_string
    FUNCTIONS_WORKER_RUNTIME       = "dotnet"
    FUNCTION_EXTENSION_VERSION     = "~3"
  }

  depends_on = [
    azurerm_app_service_plan.main,
    azurerm_storage_account.main
  ]
}

module "sql" {
  source              = "./sql"
  sql_admin_username  = var.sql_admin_username
  sql_admin_password  = var.admin_password
  environment         = var.environment
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location  # Add this line
}