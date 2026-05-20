output "account_name" {
  description = "The name of the AI Foundry account"
  value       = local.account_name
}

output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry account"
  value       = azapi_resource.ai_foundry.id
}

output "ai_project_ids" {
  description = "The resource IDs of all provisioned AI Foundry projects"
  value       = { for k, v in azapi_resource.ai_project : k => v.id }
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = local.rg_name
}

output "resource_group_id" {
  description = "The resource ID of the resource group"
  value       = local.rg_id
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "storage_account_id" {
  description = "The resource ID of the shared Storage Account"
  value       = azurerm_storage_account.storage.id
}

output "search_service_id" {
  description = "The resource ID of the shared AI Search service"
  value       = azurerm_search_service.search.id
}

output "cosmos_db_id" {
  description = "The resource ID of the shared Cosmos DB account"
  value       = azurerm_cosmosdb_account.cosmos.id
}

output "deployment_summary" {
  description = "Summary of network access configuration"
  value = {
    ai_foundry_access = var.ai_foundry_public_access
    storage_access    = var.storage_public_access ? "Public" : "Private"
    search_access     = var.search_public_access ? "Public" : "Private"
    cosmos_access     = var.cosmos_public_access ? "Public" : "Private"
    projects          = { for k, v in var.projects : k => v.project_name }
  }
}
