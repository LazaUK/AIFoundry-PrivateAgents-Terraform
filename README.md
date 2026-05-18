# Microsoft Foundry: Deploying Foundry Agents with Network Isolation

This repo contains Terraform configurations and code templates to deploy Foundry Agents using network isolation. The setup implements VNet Injection (delegated to `Microsoft.App/environments`) and *Private Endpoints* to keep all traffic inside your private network fabric.

Each deployment topology is organized into its own sub-folder containing the respective Terraform files.

## 📑 Table of Contents
- [Part 1: Prerequisites]()
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

