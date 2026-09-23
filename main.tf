#################### MAIN ####################
##### RESOURCES

# Create the OpenClaw resource group
resource "azurerm_resource_group" "openclaw" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

# Generate the SSH key pair for the VM (private key is emitted as an output)
resource "tls_private_key" "openclaw_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Static public IP for direct SSH (and optionally the gateway) access
resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-${var.project_name}-vm"
  domain_name_label   = "${var.project_name}008"
  resource_group_name = local.rg_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network interface for the VM (subnet NSG handles security)
resource "azurerm_network_interface" "vm_nic" {
  name                           = "nic-${var.project_name}-vm"
  resource_group_name            = local.rg_name
  location                       = var.location
  accelerated_networking_enabled = false

  ip_configuration {
    name                          = "ipconfig-${var.project_name}"
    subnet_id                     = azurerm_subnet.snet_openclaw.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.vm_private_ip
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }

  tags = var.tags
}

# Linux VM running OpenClaw via cloud-init bootstrap
resource "azurerm_linux_virtual_machine" "openclaw" {
  name                  = local.vm_common_name
  resource_group_name   = local.rg_name
  location              = var.location
  size                  = var.vm_size
  computer_name         = "${var.project_name}008"
  admin_username        = var.vm_localadmin_user
  admin_password        = var.vm_localadmin_pswd
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  admin_ssh_key {
    username   = var.vm_localadmin_user
    public_key = tls_private_key.openclaw_ssh.public_key_openssh
  }

  os_disk {
    name                 = "disk-${var.project_name}-os"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS" // cheaper than Premium; fine for a light install
    disk_size_gb         = var.vm_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username    = var.vm_localadmin_user
    admin_password    = var.vm_localadmin_pswd
    openvpn_port      = var.openvpn_port
    openvpn_public_ip = azurerm_public_ip.vm_pip.ip_address
    vm_private_ip     = local.vm_private_ip
    vm_common_name    = local.vm_common_name
  }))

  boot_diagnostics {}

  tags = var.tags
}
