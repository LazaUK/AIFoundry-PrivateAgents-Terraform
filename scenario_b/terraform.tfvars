# ── Core ──────────────────────────────────────────────────────────────────────
location            = "swedencentral"         # Azure region for all new resources
resource_group_name = "AAA_myTFResourceGroup" # Leave "" to auto-create, or set to existing RG name

# ── AI Foundry ────────────────────────────────────────────────────────────────
ai_services_name_prefix  = "foundry"          # 4 random digits auto-appended
project_name             = "private-agent-project"
ai_foundry_public_access = "Disabled"         # "Enabled" | "Disabled"

# ── BYO Networking ────────────────────────────────────────────────────────────
# The VNet and both subnets must already exist before running terraform apply.
# The agent subnet must be delegated to Microsoft.App/environments.
vnet_name                    = "vnet-aifoundry0400"
vnet_resource_group_name     = "AAA_myTFResourceGroup"
agent_subnet_name            = "snet-agent-b"
private_endpoint_subnet_name = "snet-private-endpoints"
dns_zone_resource_group_name = "AAA_myTFResourceGroup"   # RG where private DNS zones already exist

# ── Model Deployment ──────────────────────────────────────────────────────────
model_name     = "gpt-4.1"
model_version  = "2025-04-14"
model_capacity = 40

# ── Dependent Services (all private by default) ───────────────────────────────
storage_public_access = false
search_public_access  = false
cosmos_public_access  = false
