provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "md_rg" {
  name     = "MD-RG1"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "md_vnet" {
  name                = "MD-RG1-VNET1"
  location            = azurerm_resource_group.md_rg.location
  resource_group_name = azurerm_resource_group.md_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_app_service_plan" "md_app_service_plan" {
  name                = "MD-AppServicePlan"
  location            = azurerm_resource_group.md_rg.location
  resource_group_name = azurerm_resource_group.md_rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "md_web_app" {
  name                = "MD-WebApp"
  location            = azurerm_resource_group.md_rg.location
  resource_group_name = azurerm_resource_group.md_rg.name
  app_service_plan_id = azurerm_app_service_plan.md_app_service_plan.id

  site_config {
    linux_fx_version = "DOCKER|https://github.com/JohnLacson/API-PoC.git#Dockerfile1"
  }
}

resource "azurerm_public_ip" "md_public_ip" {
  name                = "MD-PublicIP"
  location            = azurerm_resource_group.md_rg.location
  resource_group_name = azurerm_resource_group.md_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "md_network_interface" {
  name                = "MD-NetworkInterface"
  location            = azurerm_resource_group.md_rg.location
  resource_group_name = azurerm_resource_group.md_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_virtual_network.md_vnet.subnets[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.md_public_ip.id
  }
}

resource "azurerm_application_gateway" "md_app_gateway" {
  name                = "MD-AppGateway"
  location            = azurerm_resource_group.md_rg.location
  resource_group_name = azurerm_resource_group.md_rg.name
  sku {
    name     = "Standard_Medium"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gatewayIpConfig"
    subnet_id = azurerm_virtual_network.md_vnet.subnets[0].id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "publicIpAddress"
    public_ip_address_id = azurerm_public_ip.md_public_ip.id
  }

  backend_address_pool {
    name = "backendAddressPool"
    backend_addresses = [azurerm_app_service.md_web_app.default_site_hostname]
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  http_listener {
    name                  = "httpListener"
    frontend_ip_configuration_name = "publicIpAddress"
    frontend_port_name     = "httpPort"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = azurerm_application_gateway.md_app_gateway.http_listener[0].name
    backend_address_pool_name  = azurerm_application_gateway.md_app_gateway.backend_address_pool[0].name
    backend_http_settings_name = azurerm_application_gateway.md_app_gateway.backend_http_settings[0].name
  }
}

resource "azurerm_application_gateway_backend_http_settings" "md_app_gateway_backend_http_settings" {
  name                  = "appGatewayBackendHttpSettings"
  cookie_based_affinity = "Disabled"
  path                  = "/"
  port                  = 80
  protocol              = "Http"
  request_timeout       = 30
}
