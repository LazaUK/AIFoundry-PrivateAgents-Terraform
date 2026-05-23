variable "location" {
  description = "The Azure region where all resources will be deployed"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "Existing resource group name. Leave empty to auto-create."
  type        = string
  default     = ""
}

variable "ai_services_name_prefix" {
  description = "Prefix for AI Foundry account names (account key appended automatically)"
  type        = string
  default     = "foundry"
}

# =============================================
# ACCOUNTS — add or remove entries freely
# =============================================

variable "accounts" {
  description = "Map of Foundry accounts to create. Each entry provisions a Foundry account, agent subnet, project, Storage, CosmosDB, connections, capability host and RBAC. All accounts share the single AI Search instance."
  type = map(object({
    project_name         = string
    agent_subnet_prefix  = string
  }))
  default = {
    account1 = {
      project_name        = "project-account1"
      agent_subnet_prefix = "10.0.1.0/24"
    }
    account2 = {
      project_name        = "project-account2"
      agent_subnet_prefix = "10.0.2.0/24"
    }
  }
}

# =============================================
# AI FOUNDRY
# =============================================

variable "ai_foundry_public_access" {
  description = "Whether AI Foundry accounts should have public access (Enabled/Disabled)"
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.ai_foundry_public_access)
    error_message = "Must be Enabled or Disabled"
  }
}

# =============================================
# NETWORKING
# =============================================

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_endpoint_subnet_address_prefix" {
  description = "Address prefix for the shared private endpoint subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# =============================================
# SHARED AI SEARCH
# =============================================

variable "search_public_access" {
  description = "Whether the shared AI Search should have public access"
  type        = bool
  default     = false
}

# =============================================
# PER-ACCOUNT DEPENDENT SERVICES
# =============================================

variable "storage_public_access" {
  description = "Whether Storage Accounts should have public access"
  type        = bool
  default     = false
}

variable "cosmos_public_access" {
  description = "Whether CosmosDB accounts should have public access"
  type        = bool
  default     = false
}

# =============================================
# MODEL DEPLOYMENT
# =============================================

variable "model_name" {
  description = "The model to deploy on each Foundry account"
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
