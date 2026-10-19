#################### STORAGE ####################

# Off-VM Hermes backups in the same resource group and region as the VM.
# A stable suffix provides a globally unique name without another provider.
resource "azurerm_storage_account" "hermes_backup" {
  name                     = "sthermes${substr(sha256(azurerm_resource_group.openclaw.id), 0, 16)}"
  resource_group_name      = azurerm_resource_group.openclaw.name
  location                 = azurerm_resource_group.openclaw.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true // required for subnet service endpoints
  default_to_oauth_authentication = true

  # No private endpoint charge; data access is limited to the VM subnet.
  network_rules {
    default_action             = "Deny"
    bypass                     = ["None"]
    virtual_network_subnet_ids = [azurerm_subnet.snet_openclaw.id]
  }

  blob_properties {
    versioning_enabled = false

    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "hermes_backup" {
  name                  = "hermes-backups"
  storage_account_id    = azurerm_storage_account.hermes_backup.id
  container_access_type = "private"
}

# AzureRM can retain a null principal_id while enabling an existing VM's identity.
# Defer this lookup until the VM update has completed instead of using that null.
data "azurerm_virtual_machine" "hermes_backup_identity" {
  name                = azurerm_linux_virtual_machine.openclaw.name
  resource_group_name = azurerm_linux_virtual_machine.openclaw.resource_group_name

  depends_on = [azurerm_linux_virtual_machine.openclaw]
}

# The upload job uses the VM identity, not storage keys or a SAS token.
resource "azurerm_role_assignment" "hermes_backup" {
  scope                = azurerm_storage_container.hermes_backup.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_virtual_machine.hermes_backup_identity.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
