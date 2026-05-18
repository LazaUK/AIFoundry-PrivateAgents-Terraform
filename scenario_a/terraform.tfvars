# Example configuration for private resources agent setup

# Azure region
location = "swedencentral"

# AI Foundry configuration
ai_services_name_prefix = "foundry-pr-swc"
project_name            = "agent-new-res"

# Use your existing Resource Group
resource_group_name = "AAA_myTFResourceGroup"

# Network configuration
vnet_address_space    = ["10.0.0.0/16"]
private_endpoint_subnet_address_prefix = "10.0.1.0/24"
agent_subnet_address_prefix           = "10.0.2.0/24"

# Hybrid configuration - mix of public and private
ai_foundry_public_access = "Disabled"
storage_public_access    = false
search_public_access     = false
cosmos_public_access     = false

# Model configuration
model_name     = "gpt-4.1"
model_version  = "2025-04-14"
model_capacity = 40
