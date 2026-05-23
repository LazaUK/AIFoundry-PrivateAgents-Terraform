########## Private Network + Agent VNet Injection for Microsoft Foundry   ##########
########## Scenario E: Multi-Account Foundry with Shared AI Search        ##########
########## Each account has its own Storage, CosmosDB, subnet and project ##########
########## All accounts share a single AI Search resource                 ##########

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
## NETWORKING
## =============================================

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aifoundry${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  address_space       = var.vnet_address_space
}

# One agent subnet per Foundry account — delegation is account-level
resource "azurerm_subnet" "agent" {
  for_each             = var.accounts
  name                 = "snet-agent-${each.key}"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.agent_subnet_prefix]

  delegation {
    name = "agent-delegation"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Single shared PE subnet for all private endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.private_endpoint_subnet_address_prefix]
}

## =============================================
## PRIVATE DNS ZONES
## =============================================

resource "azurerm_private_dns_zone" "cognitiveservices" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = local.rg_name
}

resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = local.rg_name
}

resource "azurerm_private_dns_zone" "services_ai" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = local.rg_name
}

resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.rg_name
}

resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = local.rg_name
}

resource "azurerm_private_dns_zone" "cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = local.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "all" {
  for_each = {
    cognitiveservices = azurerm_private_dns_zone.cognitiveservices.name
    openai            = azurerm_private_dns_zone.openai.name
    services_ai       = azurerm_private_dns_zone.services_ai.name
    storage           = azurerm_private_dns_zone.storage.name
    search            = azurerm_private_dns_zone.search.name
    cosmos            = azurerm_private_dns_zone.cosmos.name
  }

  name                  = "link-${each.key}-${random_string.unique.result}"
  resource_group_name   = local.rg_name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

## =============================================
## SHARED AI SEARCH (SINGLE INSTANCE)
## =============================================

resource "azurerm_search_service" "search" {
  name                = replace("aifoundry-${random_string.unique.result}-search", "_", "-")
  resource_group_name = local.rg_name
  location            = var.location
  sku                 = "standard"

  local_authentication_enabled  = true
  authentication_failure_mode   = "http401WithBearerChallenge"
  public_network_access_enabled = var.search_public_access

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "search" {
  count               = var.search_public_access ? 0 : 1
  name                = "pe-search-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-search"
    private_connection_resource_id = azurerm_search_service.search.id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "search-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.search.id]
  }
}

## =============================================
## PER-ACCOUNT STORAGE
## =============================================

resource "azurerm_storage_account" "storage" {
  for_each                 = var.accounts
  name                     = lower("aifoundry${random_string.unique.result}${each.key}st")
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
  for_each              = var.accounts
  name                  = "foundry-data"
  storage_account_id    = azurerm_storage_account.storage[each.key].id
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "storage" {
  for_each            = var.storage_public_access ? {} : var.accounts
  name                = "pe-storage-${each.key}-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-storage-${each.key}"
    private_connection_resource_id = azurerm_storage_account.storage[each.key].id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

## =============================================
## PER-ACCOUNT COSMOS DB
## =============================================

resource "azurerm_cosmosdb_account" "cosmos" {
  for_each                          = var.accounts
  name                              = lower("aifoundry${random_string.unique.result}${each.key}cos")
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
  for_each            = var.cosmos_public_access ? {} : var.accounts
  name                = "pe-cosmos-${each.key}-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-cosmos-${each.key}"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos[each.key].id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmos-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos.id]
  }
}

## =============================================
## PER-ACCOUNT AI FOUNDRY + PRIVATE ENDPOINT
## =============================================

resource "azapi_resource" "ai_foundry" {
  for_each  = var.accounts
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = lower("${var.ai_services_name_prefix}${random_string.unique.result}${each.key}")
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
      customSubDomainName    = lower("${var.ai_services_name_prefix}${random_string.unique.result}${each.key}")
      publicNetworkAccess    = var.ai_foundry_public_access
      disableLocalAuth       = true

      networkAcls = {
        defaultAction = "Deny"
      }

      networkInjections = [
        {
          scenario                   = "agent"
          subnetArmId                = azurerm_subnet.agent[each.key].id
          useMicrosoftManagedNetwork = false
        }
      ]
    }
  }

  depends_on = [
    azurerm_subnet.agent,
    azapi_resource_action.purge_ai_foundry
  ]
}

resource "time_sleep" "wait_for_ai_foundry" {
  for_each        = var.accounts
  depends_on      = [azapi_resource.ai_foundry]
  create_duration = "60s"
}

resource "azurerm_private_endpoint" "ai_foundry" {
  for_each            = var.ai_foundry_public_access == "Disabled" ? var.accounts : {}
  name                = "pe-ai-foundry-${each.key}-${random_string.unique.result}"
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  depends_on = [time_sleep.wait_for_ai_foundry]

  private_service_connection {
    name                           = "psc-ai-foundry-${each.key}"
    private_connection_resource_id = azapi_resource.ai_foundry[each.key].id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "ai-foundry-dns"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.cognitiveservices.id,
      azurerm_private_dns_zone.services_ai.id,
      azurerm_private_dns_zone.openai.id
    ]
  }
}

## =============================================
## PER-ACCOUNT PROJECTS
## =============================================

resource "azapi_resource" "ai_project" {
  for_each  = var.accounts
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = each.value.project_name
  location  = var.location
  parent_id = azapi_resource.ai_foundry[each.key].id

  identity {
    type = "SystemAssigned"
  }

  body = { properties = {} }

  response_export_values = ["identity.principalId"]
}

resource "time_sleep" "wait_for_project_identity" {
  for_each        = var.accounts
  depends_on      = [azapi_resource.ai_project]
  create_duration = "15s"
}

## =============================================
## PER-ACCOUNT CONNECTIONS
## =============================================

resource "azapi_resource" "storage_connection" {
  for_each  = var.accounts
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = "storage-connection"
  parent_id = azapi_resource.ai_project[each.key].id

  body = {
    properties = {
      category      = "AzureStorageAccount"
      target        = azurerm_storage_account.storage[each.key].primary_blob_endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_storage_account.storage[each.key].id
        location   = var.location
      }
    }
  }
}

resource "azapi_resource" "search_connection" {
  for_each  = var.accounts
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = "search-connection"
  parent_id = azapi_resource.ai_project[each.key].id

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
  for_each  = var.accounts
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = "cosmosdb-connection"
  parent_id = azapi_resource.ai_project[each.key].id

  body = {
    properties = {
      category      = "CosmosDb"
      target        = azurerm_cosmosdb_account.cosmos[each.key].endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_cosmosdb_account.cosmos[each.key].id
        location   = var.location
      }
    }
  }
}

## =============================================
## PER-ACCOUNT CAPABILITY HOSTS
## =============================================

resource "azapi_resource" "ai_foundry_project_capability_host" {
  for_each                  = var.accounts
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  name                      = "caphostproj"
  parent_id                 = azapi_resource.ai_project[each.key].id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
      vectorStoreConnections = [
        azapi_resource.search_connection[each.key].name
      ]
      storageConnections = [
        azapi_resource.storage_connection[each.key].name
      ]
      threadStorageConnections = [
        azapi_resource.cosmosdb_connection[each.key].name
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

## =============================================
## PER-ACCOUNT MODEL DEPLOYMENTS
## =============================================

resource "azapi_resource" "model_deployment" {
  for_each  = var.accounts
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview"
  name      = var.model_name
  parent_id = azapi_resource.ai_foundry[each.key].id

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
## PER-ACCOUNT RBAC
## =============================================

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  for_each             = var.accounts
  scope                = azurerm_storage_account.storage[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.ai_project[each.key].output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  for_each             = var.accounts
  scope                = azurerm_search_service.search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azapi_resource.ai_project[each.key].output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

resource "azurerm_role_assignment" "search_service_contributor" {
  for_each             = var.accounts
  scope                = azurerm_search_service.search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azapi_resource.ai_project[each.key].output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_contributor" {
  for_each            = var.accounts
  resource_group_name = local.rg_name
  account_name        = azurerm_cosmosdb_account.cosmos[each.key].name
  role_definition_id  = "${azurerm_cosmosdb_account.cosmos[each.key].id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_project[each.key].output.identity.principalId
  scope               = azurerm_cosmosdb_account.cosmos[each.key].id
  depends_on          = [time_sleep.wait_for_project_identity]
}

resource "azurerm_role_assignment" "cosmos_operator" {
  for_each             = var.accounts
  scope                = azurerm_cosmosdb_account.cosmos[each.key].id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = azapi_resource.ai_project[each.key].output.identity.principalId
  depends_on           = [time_sleep.wait_for_project_identity]
}

## =============================================
## TIMERS AND PURGE MECHANICAL ACTIONS
## =============================================

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
  for_each    = var.accounts
  method      = "DELETE"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${var.location}/deletedAccounts/${lower("${var.ai_services_name_prefix}${random_string.unique.result}${each.key}")}"
  type        = "Microsoft.CognitiveServices/locations/deletedAccounts@2023-05-01"
  when        = "destroy"

  depends_on = [time_sleep.purge_ai_foundry_cooldown]
}

resource "time_sleep" "purge_ai_foundry_cooldown" {
  destroy_duration = "900s"
  depends_on       = [azurerm_subnet.agent]
}
