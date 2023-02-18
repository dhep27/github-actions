locals {
  tags = {
    owner       = var.owner
    environment = var.environment
    application = var.application
  }

  location_no_space = replace(var.location, "/\\s+/", "")

  resource_name_pattern = lower("${var.application}-${var.environment}-${local.location_no_space}")
  resource_group_name = "rg-${local.resource_name_pattern}-01"
  azure_migrate_project_name = "migr-${local.resource_name_pattern}-01"
  virtual_network_name = "vnet-${local.resource_name_pattern}-01"
  subnet_name = "snet-privateendpoint"

  # Resource names have to have the following suffixes for Azure Migrate to work
  private_endpoint_name = "pep-${local.resource_name_pattern}-019452pe"
  dns_zone_group_name = "dnszg-${local.resource_name_pattern}-019452dnszonegroup"

  azure_migrate_private_dns_zone = "privatelink.prod.migration.windowsazure.com"

}
