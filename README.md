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
  - [Scenario C: BYO VNet and AI Search](#scenario-c-byo-vnet-and-ai-search)
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

Update terraform.tfvars:

``` JSON
<DETAILS TO BE PROVIDED SOON>
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

``` JSON
<DETAILS TO BE PROVIDED SOON>
```

Deploy the environment with these Terraform commands:

``` PowerShell
cd scenario_b
terraform init
terraform apply --auto-approve
```

### Scenario C: BYO VNet and AI Search

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
