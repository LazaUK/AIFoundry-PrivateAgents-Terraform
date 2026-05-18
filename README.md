# Microsoft Foundry: Deploying Foundry Agents with Network Isolation

This repo contains Terraform configurations and code templates to deploy Foundry Agents using network isolation. The setup implements VNet Injection (delegated to `Microsoft.App/environments`) and *Private Endpoints* to keep all traffic inside your private network fabric.

Each deployment topology is organized into its own sub-folder containing the respective Terraform files.

## 📑 Table of Contents
- [Part 1: Prerequisites](#part-1-prerequisites)
- [Part 2: Environment Setup]()
- [Part 3: Infrastructure Deployment Scenarios]()
  - [Scenario A: New Resources]()
  - [Scenario B: BYO VNet]()
  - [Scenario C: BYO VNet and AI Search]()
  - [Scenario D: Managed VNet]()
- [Part 4: Deploy to Foundry]()
- [Part 5: Testing and Infrastructure Cleanup]()

## Part 1: Prerequisites

Ensure you have the following tools installed locally:
- **Azure CLI** (authenticated to your subscription)
- **Terraform CLI** (v1.5.0+)

## Part 2: Environment Setup

### 2.1 Configuration

<TBU>

## Part 3: Infrastructure Deployment Scenarios

Navigate into the sub-folder that matches your targeted architecture scenario before running Terraform.

### Scenario A: New Resources

> [!NOTE]
> **Sub-folder**: `/scenario_a`

Provisions a new resource group, new *VNet* and standalone *Storage Account*, *AI Search* and *CosmosDB* resources.

Update terraform.tfvars:

``` Terraform
<TBU>
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_a
terraform init
terraform apply --auto-approve
```

