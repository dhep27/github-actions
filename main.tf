

resource "azurerm_resource_group" "rg" {
  name = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.subnet_address_space
}

resource "azurerm_subnet" "subnet" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_space
  private_endpoint_network_policies_enabled = true
}

# This Private DNS Zone has to be created in the same Resource Group as the Azure Migrate project for it to work
resource "azurerm_private_dns_zone" "dns-zone" {
  name                = local.azure_migrate_private_dns_zone
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_endpoint" "pe" {
  name                = local.private_endpoint_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id
  tags = {
    MigrateProject = local.azure_migrate_project_name
  }

  private_service_connection {
    name                           = local.private_endpoint_name
    private_connection_resource_id = azapi_resource.az-migrate-project.id
    subresource_names              = ["Default"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = local.dns_zone_group_name
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns-zone.id
    ]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-zone-link" {
  name                  = local.azure_migrate_private_dns_zone
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns-zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Azure Migrate Project
resource "azapi_resource" "az-migrate-project" {
  type                      = "Microsoft.Migrate/migrateProjects@2020-06-01-preview"
  name                      = local.azure_migrate_project_name
  location                  = azurerm_resource_group.rg.location
  parent_id                 = azurerm_resource_group.rg.id
  schema_validation_enabled = false
  body = jsonencode({
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      publicNetworkAccess = var.project_public_access
    }
    tags = {
      MigrateProject = local.azure_migrate_project_name
    }
  })
}

# Azure Migrate -  Assessment Project
resource "azapi_resource" "az-migrate-serverassessment" {
  type                      = "Microsoft.Migrate/MigrateProjects/Solutions@2020-06-01-preview"
  name                      = "Servers-Assessment-ServerAssessment"
  parent_id                 = azapi_resource.az-migrate-project.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      tool    = "ServerAssessment"
      purpose = "Assessment"
      goal    = "Servers"
      status  = "Active"
    }
  })
}

# Azure Migrate - Migrate & Modernise Project 
resource "azapi_resource" "az-migrate-servermigration" {
  type                      = "Microsoft.Migrate/MigrateProjects/Solutions@2020-06-01-preview"
  name                      = "Servers-Migration-ServerMigration"
  parent_id                 = azapi_resource.az-migrate-project.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      tool    = "ServerMigration"
      purpose = "Discovery"
      goal    = "Servers"
      status  = "Active"
    }
  })
}

# Azure Migrate - Discovery Project
resource "azapi_resource" "az-migrate-serverdiscovery" {
  type                      = "Microsoft.Migrate/MigrateProjects/Solutions@2020-06-01-preview"
  name                      = "Servers-Discovery-ServerDiscovery"
  parent_id                 = azapi_resource.az-migrate-project.id
  schema_validation_enabled = false
  body = jsonencode({
    properties = {
      tool    = "ServerDiscovery"
      purpose = "Discovery"
      goal    = "Servers"
      status  = "Inactive"
    }
  })
}


# This is required to update the existing Discovery Project resource once the Private Endpoint details are available
resource "azapi_update_resource" "az-migrate-serverdiscovery" {
  type        = "Microsoft.Migrate/MigrateProjects/Solutions@2020-06-01-preview"
  resource_id = azapi_resource.az-migrate-serverdiscovery.id
  body = jsonencode({
    properties = {
      tool    = "ServerDiscovery"
      purpose = "Discovery"
      goal    = "Servers"
      status  = "Inactive"
      details = {
        extendedDetails = {
          privateEndpointDetails = "{\"subnetId\":\"${azurerm_subnet.subnet.id}\",\"virtualNetworkLocation\":\"${azurerm_resource_group.rg.location}\",\"skipPrivateDnsZoneCreation\":false}"
        }
      }
    }
  })
  depends_on = [
    azurerm_private_endpoint.pe
  ]
}