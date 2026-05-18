# Microsoft Foundry: Deploying Foundry Agents with Network Isolation

This repo contains Terraform configurations and code templates to deploy Foundry Agents using network isolation. The setup implements VNet Injection (delegated to `Microsoft.App/environments`) and *Private Endpoints* to keep all traffic inside your private network fabric.

Each deployment topology is organized into its own sub-folder containing the respective Terraform files.

## 📑 Table of Contents
- [Part 1: Prerequisites](#part-1-prerequisites)
- [Part 2: Environment Setup](#part-2-environment-setup)
- [Part 3: Infrastructure Deployment Scenarios](#part-3-infrastructure-deployment-scenarios)
  - [Scenario A: New Resources](#scenario-a-new-resources)
  - [Scenario B: BYO VNet]()
  - [Scenario C: BYO VNet and AI Search]()
  - [Scenario D: Managed VNet]()
- [Part 4: Infrastructure Cleanup]()

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

> [!NOTE]
> **Sub-folder**: `/scenario_a`

Provisions a new resource group, new *VNet* and standalone *Storage Account*, *AI Search* and *CosmosDB* resources.

Update terraform.tfvars:

``` Terraform
location                = "swedencentral"
ai_services_name_prefix = "fndrysnbox"
project_name            = "sandbox-project"
model_name              = "gpt-4.1-mini"
resource_group_name     = "" # Leave empty to force a new creation
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_a
terraform init
terraform apply --auto-approve
```

### Scenario B: BYO VNet
> [!NOTE]
> **Sub-folder**: `/scenario_b`

Deploys the Microsoft Foundry resources and use VNet injection of agent service with an existing Azure virtual network / subnet.

Update terraform.tfvars:

``` Terraform
location                             = "eastus2"
resource_group_name                  = "existing-corporate-rg"
vnet_address_space                   = ["10.240.0.0/16"]
agent_subnet_address_prefix          = "10.240.10.0/24"
private_endpoint_subnet_address_prefix = "10.240.20.0/24"
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_b
terraform init
terraform apply --auto-approve
```

