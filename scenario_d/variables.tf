variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "Existing resource group name. Leave empty to create a new one."
  type        = string
  default     = ""
}

variable "ai_services_name_prefix" {
  description = "Prefix for the AI Foundry account name"
  type        = string
  default     = "foundry"
}

# =============================================
# PROJECTS — add or remove entries freely
# =============================================

variable "projects" {
  description = "Map of Foundry projects to create. Each entry provisions a project, its connections, capability host and RBAC assignments against the shared dependencies."
  type = map(object({
    project_name = string
  }))
  default = {
    team_a = { project_name = "project-team-a" }
    team_b = { project_name = "project-team-b" }
  }
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
# NETWORKING
# =============================================

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "agent_subnet_address_prefix" {
  description = "Address prefix for the agent subnet (delegated to Microsoft.App/environments)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_endpoint_subnet_address_prefix" {
  description = "Address prefix for the private endpoint subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# =============================================
# SHARED DEPENDENT SERVICES
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
  description = "The model to deploy (shared across all projects)"
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
