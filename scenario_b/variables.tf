variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "Existing resource group name to deploy Foundry resources into. Leave empty to create a new one."
  type        = string
  default     = ""
}

variable "ai_services_name_prefix" {
  description = "Prefix for AI Foundry account name"
  type        = string
  default     = "foundry"
}

variable "project_name" {
  description = "The name of the AI Foundry project"
  type        = string
  default     = "private-agent-project"
}

# =============================================
# BYO NETWORKING
# =============================================

variable "vnet_name" {
  description = "Name of the existing Virtual Network to use"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "Resource group containing the existing Virtual Network (may differ from the Foundry resource group)"
  type        = string
}

variable "agent_subnet_name" {
  description = "Name of the existing subnet delegated to Microsoft.App/environments for VNet injection"
  type        = string
}

variable "private_endpoint_subnet_name" {
  description = "Name of the existing subnet used for private endpoints"
  type        = string
}

variable "dns_zone_resource_group_name" {
  description = "Resource group containing the existing private DNS zones."
  type        = string
}

variable "create_dns_zone_links" {
  description = "Set to true only if the BYO VNet has no existing links to the private DNS zones. Set to false (default) when reusing a VNet already linked by another scenario deployment."
  type        = bool
  default     = false
}

# =============================================
# AI FOUNDRY
# =============================================

variable "ai_foundry_public_access" {
  description = "Whether AI Foundry should have public access (Enabled/Disabled)"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.ai_foundry_public_access)
    error_message = "Must be Enabled or Disabled"
  }
}

# =============================================
# DEPENDENT SERVICES
# =============================================

variable "storage_public_access" {
  description = "Whether Storage Account should have public access"
  type        = bool
  default     = false
}

variable "search_public_access" {
  description = "Whether AI Search should have public access"
  type        = bool
  default     = false
}

variable "cosmos_public_access" {
  description = "Whether Cosmos DB should have public access"
  type        = bool
  default     = false
}

# =============================================
# MODEL DEPLOYMENT
# =============================================

variable "model_name" {
  description = "The model to deploy"
  type        = string
  default     = "gpt-4.1"
}

variable "model_version" {
  description = "The version of the model"
  type        = string
  default     = "2025-04-14"
}

variable "model_capacity" {
  description = "The capacity of the model deployment (thousand tokens per minute)"
  type        = number
  default     = 40
}
