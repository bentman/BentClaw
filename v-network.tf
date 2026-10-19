#################### V-NETWORK ####################

##### NETWORK
# Virtual network for the OpenClaw deployment
resource "azurerm_virtual_network" "vnet_openclaw" {
  name                = "vnet-${var.project_name}"
  resource_group_name = local.rg_name
  location            = var.location
  address_space       = [var.vnet_prefix]
  tags                = var.tags
}

# Subnet hosting the OpenClaw VM
resource "azurerm_subnet" "snet_openclaw" {
  name                 = "snet-${var.project_name}-vm"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.vnet_openclaw.name
  address_prefixes     = [var.subnet_prefix]
  service_endpoints    = ["Microsoft.Storage"]
}

##### SECURITY
# NSG: SSH locked to the deployer's IP; gateway port optional
resource "azurerm_network_security_group" "nsg_openclaw" {
  name                = "nsg-${var.project_name}-vm"
  resource_group_name = local.rg_name
  location            = var.location
  tags                = var.tags

  # SSH - only from where you run terraform
  security_rule {
    name                       = "allow-ssh-from-myip"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.my_ip
    destination_address_prefix = "*"
  }

  # OpenVPN - open to any public IP
  security_rule {
    name                       = "allow-openvpn-public"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.openvpn_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # OpenClaw gateway - only when allow_openclaw_gateway_public = true
  security_rule {
    name                       = "allow-openclaw-gateway-from-myip"
    priority                   = 110
    direction                  = "Inbound"
    access                     = var.allow_openclaw_gateway_public ? "Allow" : "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.openclaw_gateway_port)
    source_address_prefix      = local.my_ip
    destination_address_prefix = "*"
  }

  # Hermes gateway - only when allow_hermes_gateway_public = true
  security_rule {
    name                       = "allow-hermes-gateway-from-myip"
    priority                   = 130
    direction                  = "Inbound"
    access                     = var.allow_hermes_gateway_public ? "Allow" : "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.hermes_gateway_port)
    source_address_prefix      = local.my_ip
    destination_address_prefix = "*"
  }

  # Hermes WebUI - only when allow_hermes_webui_public = true
  security_rule {
    name                       = "allow-hermes-webui-from-myip"
    priority                   = 140
    direction                  = "Inbound"
    access                     = var.allow_hermes_webui_public ? "Allow" : "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.hermes_webui_port)
    source_address_prefix      = local.my_ip
    destination_address_prefix = "*"
  }
}

# Apply the NSG at the subnet level (no per-NIC NSG needed)
resource "azurerm_subnet_network_security_group_association" "openclaw" {
  subnet_id                 = azurerm_subnet.snet_openclaw.id
  network_security_group_id = azurerm_network_security_group.nsg_openclaw.id
}
