########## Private Network + Agent VNet Injection for Microsoft Foundry ##########
########## Scenario B: BYO VNet (existing VNet and subnets)             ##########

data "azurerm_client_config" "current" {}

resource "random_string" "unique" {
  length      = 4
  min_numeric = 4
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

locals {
  account_name = lower("${var.ai_services_name_prefix}${random_string.unique.result}")

  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "rg-aifoundry${random_string.unique.result}"
  rg_name             = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.rg[0].name
  rg_id               = var.resource_group_name != "" ? data.azurerm_resource_group.existing[0].id : azurerm_resource_group.rg[0].id
}

data "azurerm_resource_group" "existing" {
  count = var.resource_group_name != "" ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.resource_group_name == "" ? 1 : 0
  name     = local.resource_group_name
  location = var.location
}

## =============================================
## BYO NETWORKING — DATA SOURCES
## =============================================

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

data "azurerm_subnet" "agent" {
  name                 = var.agent_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

data "azurerm_subnet" "private_endpoints" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

## =============================================
## PRIVATE DNS ZONES
## Look up existing zones — shared with other scenarios in the same RG
## =============================================

data "azurerm_private_dns_zone" "cognitiveservices" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_private_dns_zone" "services_ai" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.dns_zone_resource_group_name
}

# VNet links are skipped when the DNS zones are already linked to the BYO VNet
# (e.g. from a prior Scenario A deployment). Set create_dns_zone_links = true
# only if your existing VNet has no links to these DNS zones yet.
resource "azurerm_private_dns_zone_virtual_network_link" "all" {
  for_each = var.create_dns_zone_links ? {
    cognitiveservices = data.azurerm_private_dns_zone.cognitiveservices.name
    openai            = data.azurerm_private_dns_zone.openai.name
    services_ai       = data.azurerm_private_dns_zone.services_ai.name
    storage           = data.azurerm_private_dns_zone.storage.name
    search            = data.azurerm_private_dns_zone.search.name
    cosmos            = data.azurerm_private_dns_zone.cosmos.name
  } : {}

  name                  = "link-${each.key}-${random_string.unique.result}"
  resource_group_name   = var.dns_zone_resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

## =============================================
## STORAGE
## =============================================

resource "azurerm_storage_account" "storage" {
  name                     = "aifoundry${random_string.unique.result}stor"
  resource_group_name      = local.rg_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  shared_access_key_enabled       = false
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = var.storage_public_access

  network_rules {
    default_action = var.storage_public_access ? "Allow" : "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "aifoundry_container" {
  name                  = "foundry-data"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "storage" {
  count               = var.storage_public_access ? 0 : 1
  name                = "pe-storage-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = data.azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-storage"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-dns"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage.id]
  }
}

## =============================================
## AI SEARCH
## =============================================

resource "azurerm_search_service" "search" {
  name                = replace("aifoundry-${random_string.unique.result}-search", "_", "-")
  resource_group_name = local.rg_name
  location            = var.location
  sku                 = "standard"

  local_authentication_enabled  = true
  authentication_failure_mode   = "http401WithBearerChallenge"
  public_network_access_enabled = var.search_public_access
}

resource "azurerm_private_endpoint" "search" {
  count               = var.search_public_access ? 0 : 1
  name                = "pe-search-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = data.azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-search"
    private_connection_resource_id = azurerm_search_service.search.id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "search-dns"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.search.id]
  }
}

## =============================================
## COSMOS DB
## =============================================

resource "azurerm_cosmosdb_account" "cosmos" {
  name                              = "aifoundry${random_string.unique.result}cosmos"
  location                          = var.location
  resource_group_name               = local.rg_name
  offer_type                        = "Standard"
  kind                              = "GlobalDocumentDB"
  public_network_access_enabled     = var.cosmos_public_access
  is_virtual_network_filter_enabled = !var.cosmos_public_access
  local_authentication_disabled     = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_private_endpoint" "cosmos" {
  count               = var.cosmos_public_access ? 0 : 1
  name                = "pe-cosmos-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = data.azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-cosmos"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmos-dns"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.cosmos.id]
  }
}

## =============================================
## AI FOUNDRY ACCOUNT + NETWORK INJECTION
## =============================================

resource "azapi_resource" "ai_foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = local.account_name
  location  = var.location
  parent_id = local.rg_id

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = local.account_name
      publicNetworkAccess    = var.ai_foundry_public_access
      disableLocalAuth       = true

      networkAcls = {
        defaultAction = "Deny"
      }

      networkInjections = [
        {
          scenario                   = "agent"
          subnetArmId                = data.azurerm_subnet.agent.id
          useMicrosoftManagedNetwork = false
        }
      ]
    }
  }

  depends_on = [
    data.azurerm_subnet.agent,
    azapi_resource_action.purge_ai_foundry
  ]
}

resource "azurerm_private_endpoint" "ai_foundry" {
  count               = var.ai_foundry_public_access == "Disabled" ? 1 : 0
  name                = "pe-ai-foundry-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = data.azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-ai-foundry"
    private_connection_resource_id = azapi_resource.ai_foundry.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "ai-foundry-dns"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.cognitiveservices.id,
      data.azurerm_private_dns_zone.services_ai.id,
      data.azurerm_private_dns_zone.openai.id
    ]
  }
}

## =============================================
## AI PROJECT, CONNECTIONS & MODEL
## =============================================

resource "azapi_resource" "ai_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = var.project_name
  location  = var.location
  parent_id = azapi_resource.ai_foundry.id

  identity {
    type = "SystemAssigned"
  }

  body = { properties = {} }

  response_export_values = [
    "identity.principalId"
  ]
}

resource "azapi_resource" "storage_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = "storage-connection"
  parent_id = azapi_resource.ai_project.id

  body = {
    properties = {
      category      = "AzureStorageAccount"
      target        = azurerm_storage_account.storage.primary_blob_endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_storage_account.storage.id
        location   = var.location
      }
    }
  }
}

resource "azapi_resource" "search_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = "search-connection"
  parent_id = azapi_resource.ai_project.id

  body = {
    properties = {
      category      = "CognitiveSearch"
      target        = "https://${azurerm_search_service.search.name}.search.windows.net"
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.search.id
        location   = var.location
      }
    }
  }
}

resource "azapi_resource" "cosmosdb_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = "cosmosdb-connection"
  parent_id = azapi_resource.ai_project.id

  body = {
    properties = {
      category      = "CosmosDb"
      target        = azurerm_cosmosdb_account.cosmos.endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_cosmosdb_account.cosmos.id
        location   = var.location
      }
    }
  }
}

resource "azapi_resource" "ai_foundry_project_capability_host" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  name                      = "caphostproj"
  parent_id                 = azapi_resource.ai_project.id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
      vectorStoreConnections = [
        azapi_resource.search_connection.name
      ]
      storageConnections = [
        azapi_resource.storage_connection.name
      ]
      threadStorageConnections = [
        azapi_resource.cosmosdb_connection.name
      ]
    }
  }

  depends_on = [
    azapi_resource.search_connection,
    azapi_resource.storage_connection,
    azapi_resource.cosmosdb_connection,
    time_sleep.wait_for_rbac
  ]
}

resource "azapi_resource" "model_deployment" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview"
  name      = var.model_name
  parent_id = azapi_resource.ai_foundry.id

  body = {
    sku = {
      capacity = var.model_capacity
      name     = "GlobalStandard"
    }
    properties = {
      model = {
        name    = var.model_name
        format  = "OpenAI"
        version = var.model_version
      }
    }
  }

  depends_on = [azapi_resource.ai_project]
}

## =============================================
## SECURITY & ROLE ASSIGNMENTS
## =============================================

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.ai_project.output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  scope                = azurerm_search_service.search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azapi_resource.ai_project.output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

resource "azurerm_role_assignment" "search_service_contributor" {
  scope                = azurerm_search_service.search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azapi_resource.ai_project.output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_contributor" {
  resource_group_name = local.rg_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  role_definition_id  = "${azurerm_cosmosdb_account.cosmos.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_project.output.identity.principalId
  scope               = azurerm_cosmosdb_account.cosmos.id
  depends_on          = [time_sleep.wait_for_project_identity]
}

resource "azurerm_role_assignment" "cosmos_operator" {
  scope                = azurerm_cosmosdb_account.cosmos.id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = azapi_resource.ai_project.output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

## =============================================
## TIMERS AND PURGE MECHANICAL ACTIONS
## =============================================

resource "time_sleep" "wait_for_project_identity" {
  depends_on      = [azapi_resource.ai_project]
  create_duration = "15s"
}

resource "time_sleep" "wait_for_rbac" {
  depends_on = [
    azurerm_role_assignment.storage_blob_data_contributor,
    azurerm_role_assignment.search_index_data_contributor,
    azurerm_role_assignment.search_service_contributor,
    azurerm_cosmosdb_sql_role_assignment.cosmos_contributor,
    azurerm_role_assignment.cosmos_operator
  ]
  create_duration = "60s"
}

resource "azapi_resource_action" "purge_ai_foundry" {
  method      = "DELETE"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${var.location}/resourceGroups/${local.rg_name}/deletedAccounts/${local.account_name}"
  type        = "Microsoft.Resources/resourceGroups/deletedAccounts@2021-04-30"
  when        = "destroy"

  depends_on = [time_sleep.purge_ai_foundry_cooldown]
}

resource "time_sleep" "purge_ai_foundry_cooldown" {
  destroy_duration = "900s"
  depends_on       = [data.azurerm_subnet.agent]
}
