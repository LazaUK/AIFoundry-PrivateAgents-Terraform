# Microsoft Foundry: Deploying Foundry Agents with Network Isolation

This repo contains Terraform configurations and code templates to deploy Foundry Agents using network isolation. The setup implements VNet Injection (delegated to `Microsoft.App/environments`) and *Private Endpoints* to keep all traffic inside your private network fabric.

Each deployment topology is organized into its own sub-folder containing the respective Terraform files.

> [!NOTE]
> These Terraform templates were adopted from the official Microsoft samples. You can access the original files [here](https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-terraform).

## 📑 Table of Contents
- [Part 1: Prerequisites](#part-1-prerequisites)
- [Part 2: Environment Setup](#part-2-environment-setup)
- [Part 3: Infrastructure Deployment Scenarios](#part-3-infrastructure-deployment-scenarios)
  - [Scenario A: New Resources](#scenario-a-new-resources)
  - [Scenario B: BYO VNet](#scenario-b-byo-vnet)
  - [Scenario C: Cross-Region BYO AI Search](#scenario-c-cross-region-byo-ai-search)
  - [Scenario D: Managed VNet](#scenario-d-managed-vnet)
- [Part 4: Infrastructure Cleanup](#part-4-infrastructure-cleanup)

## Part 1: Prerequisites

Ensure you have the following tools installed locally:
- **Azure CLI** (authenticated to your subscription)
- **Terraform CLI** (v1.5.0+)

## Part 2: Environment Setup

### 2.1 Authentication

Before running the Terraform scripts, authenticate your local terminal session to your target Azure subscription:

``` PowerShell
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID_OR_NAME>"
```

## Part 3: Infrastructure Deployment Scenarios

Navigate into the sub-folder that matches your targeted architecture scenario before running Terraform.

### Scenario A: New Resources

> [!TIP]
> Provisions a new resource group, new *VNet* and standalone *Storage Account*, *AI Search* and *CosmosDB* resources.

Update terraform.tfvars with your custom values:

``` Terraform
# ── Core ──────────────────────────────────────────────────────────────────────
location                = "swedencentral"         # Azure region for all resources
resource_group_name     = "My_Resource_Group"     # Leave "" to auto-create

# ── AI Foundry ────────────────────────────────────────────────────────────────
ai_services_name_prefix  = "foundry-pr-swc"       # Suffix with 4 random digits auto-appended
project_name             = "agent-new-res"
ai_foundry_public_access = "Disabled"             # "Enabled" | "Disabled"

# ── Model Deployment ──────────────────────────────────────────────────────────
model_name     = "gpt-4o"
model_version  = "2024-11-20"
model_capacity = 10

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space                     = ["10.0.0.0/16"]
agent_subnet_address_prefix            = "10.0.1.0/24"   # Delegated to Microsoft.App/environments
private_endpoint_subnet_address_prefix = "10.0.2.0/24"

# ── Dependent Services (all private) ──────────────────────────────────────────
storage_public_access = false
search_public_access  = false
cosmos_public_access  = false
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_a
terraform init
terraform apply --auto-approve
```

### Scenario B: BYO VNet
> [!TIP]
> Deploys the Microsoft Foundry resources and use VNet injection of agent service with an existing Azure virtual network / subnet.

Update terraform.tfvars:

``` Terraform
# ── Core ──────────────────────────────────────────────────────────────────────
location            = "swedencentral"         # Azure region for all new resources
resource_group_name = "My_Resource_Group"     # Leave "" to auto-create

# ── AI Foundry ────────────────────────────────────────────────────────────────
ai_services_name_prefix  = "foundry-pr-swc"   # Suffix with 4 random digits auto-appended
project_name             = "agent-byo-vnet"
ai_foundry_public_access = "Disabled"         # "Enabled" | "Disabled"

# ── BYO Networking ────────────────────────────────────────────────────────────
# The VNet and both subnets must already exist before running terraform apply.
# The agent subnet must be delegated to Microsoft.App/environments.
vnet_name                    = "my-existing-vnet"
vnet_resource_group_name     = "my-networking-rg"
agent_subnet_name            = "snet-agent"
private_endpoint_subnet_name = "snet-private-endpoints"
dns_zone_resource_group_name = "my-networking-rg"   # RG where private DNS zones already exist

# ── Model Deployment ──────────────────────────────────────────────────────────
model_name     = "gpt-4.1"
model_version  = "2025-04-14"
model_capacity = 40

# ── Dependent Services ────────────────────────────────────────────────────────
storage_public_access = false
search_public_access  = false
cosmos_public_access  = false
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_b
terraform init
terraform apply --auto-approve
```
> [!WARNING]
> The agent subnet must have a `Microsoft.App/environments` delegation configured before running `terraform apply`.

### Scenario C: Cross-Region BYO AI Search

> [!TIP]
> Capacity limitations or design constraints may require the use of resources across differenet Azure regions. This scenario contains Terraform templates for the Foundry project that utilises Azure AI Search located in another Azure region.

Update terraform.tfvars:

``` JSON
<DETAILS TO BE PROVIDED SOON>
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_c
terraform init
terraform apply --auto-approve
```

### Scenario D: Managed VNet

> [!TIP]
> Offloads virtual network routing to the platform. Azure implicitly manages the private network boundaries on your behalf.

Update terraform.tfvars:

``` JSON
<DETAILS TO BE PROVIDED SOON>
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_d
terraform init
terraform apply --auto-approve
```

## Part 4: Infrastructure Cleanup

### 4.1 Clean Teardown

VNet-injected standard agents register hidden service association links (`legionservicelink`) inside your subnets. Trying to drop the infrastructure manually will trigger *InUseSubnetCannotBeDeleted* errors.

To cleanly remove the resources, run the teardown process via Terraform. The setup uses an automated purger context and a *15-minute* (`900s`) cooldown timer to safely disconnect and release network dependencies before deleting the virtual network.

``` Terraform
terraform destroy --auto-approve
```
