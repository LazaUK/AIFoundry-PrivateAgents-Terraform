# ── Core ──────────────────────────────────────────────────────────────────────
location            = "swedencentral"
resource_group_name = "AAA_myTFResourceGroup" # Leave "" to auto-create

# ── AI Foundry ────────────────────────────────────────────────────────────────
ai_services_name_prefix  = "foundry"          # 4 random digits auto-appended
ai_foundry_public_access = "Disabled"         # "Enabled" | "Disabled"

# ── Projects ──────────────────────────────────────────────────────────────────
projects = {
  team_a = { project_name = "project-team-a" }
  team_b = { project_name = "project-team-b" }
}

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space                     = ["10.0.0.0/16"]
agent_subnet_address_prefix            = "10.0.1.0/24"  # Delegated to Microsoft.App/environments
private_endpoint_subnet_address_prefix = "10.0.2.0/24"

# ── Model Deployment (shared across all projects) ─────────────────────────────
model_name     = "gpt-4.1"
model_version  = "2025-04-14"
model_capacity = 40

# ── Shared Dependent Services ─────────────────────────────────────────────────
storage_public_access = false
search_public_access  = false
cosmos_public_access  = false
