# ── Core ──────────────────────────────────────────────────────────────────────
location            = "swedencentral"
resource_group_name = "AAA_myTFResourceGroup" # Leave "" to auto-create

# ── AI Foundry ────────────────────────────────────────────────────────────────
ai_services_name_prefix  = "foundry"          # Account key appended automatically e.g. foundry1234account1
ai_foundry_public_access = "Disabled"         # "Enabled" | "Disabled"

# ── Accounts ──────────────────────────────────────────────────────────────────
accounts = {
  account1 = {
    project_name        = "project-account1"
    agent_subnet_prefix = "10.0.1.0/24"
  }
  account2 = {
    project_name        = "project-account2"
    agent_subnet_prefix = "10.0.2.0/24"
  }
}

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space                     = ["10.0.0.0/16"]
private_endpoint_subnet_address_prefix = "10.0.3.0/24"  # Shared across all accounts

# ── Model Deployment (one per Foundry account) ────────────────────────────────
model_name     = "gpt-4.1-mini"
model_version  = "2025-04-14"
model_capacity = 40

# ── Public Access ---──────────────────────────────────────────────────────────
search_public_access  = false
storage_public_access = false
cosmos_public_access  = false
