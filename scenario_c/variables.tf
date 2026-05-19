variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "swedencentral"
}

variable "search_location" {
  description = "Azure region for AI Search (can differ from primary location for capacity reasons)"
  type        = string
  default     = "centralus"
}

variable "ai_services_name_prefix" {
  description = "Prefix for AI Foundry account name"
  type        = string
  default     = "foundry"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "private-agent-project"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_endpoint_subnet_address_prefix" {
  description = "Address prefix for Private Endpoints subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "agent_subnet_address_prefix" {
  description = "Address prefix for the Agent subnet (VNet Injection)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ai_foundry_public_access" {
  description = "Whether AI Foundry should have public access (Enabled/Disabled)"
  type        = string
  default     = "Enabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.ai_foundry_public_access)
    error_message = "Must be Enabled or Disabled"
  }
}

variable "storage_public_access" {
  description = "Whether Storage should have public access (true/false)"
  type        = bool
  default     = false
}

variable "search_public_access" {
  description = "Whether AI Search should have public access (true/false)"
  type        = bool
  default     = true
}

variable "cosmos_public_access" {
  description = "Whether Cosmos DB should have public access (true/false)"
  type        = bool
  default     = true
}

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
  description = "The capacity of the model deployment"
  type        = number
  default     = 40
}

# =============================================
# NEW VARIABLE - For using existing Resource Group
# =============================================
variable "resource_group_name" {
  description = "Existing resource group name to use. Leave empty to create a new one."
  type        = string
  default     = ""
}