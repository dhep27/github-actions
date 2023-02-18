variable "application" {
  type        = string
  description = "Name of the application"
}

variable "owner" {
  type        = string
  description = "Owner of the application"
}

variable "environment" {
  type        = string
  description = "The environment or SDLC stage of the application"
}

variable "location" {
  type        = string
  description = "The Azure region that this application should be deployed to"
  default     = "West Europe"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "The CIDR IP ranges that the Virtual Network should use"
}

variable "subnet_address_space" {
  type        = list(string)
  description = "The CIDR IP ranges that the Subnet should use"
}

variable "project_public_access" {
  type = string
  description = "Whether public access to the Azure Migrate Project is enabled or disabled"
  default = "Disabled"
}

