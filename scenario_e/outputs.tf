output "ai_foundry_ids" {
  description = "Resource IDs of all provisioned AI Foundry accounts"
  value       = { for k, v in azapi_resource.ai_foundry : k => v.id }
}

output "ai_project_ids" {
  description = "Resource IDs of all provisioned AI Foundry projects"
  value       = { for k, v in azapi_resource.ai_project : k => v.id }
}

output "search_service_id" {
  description = "Resource ID of the shared AI Search service"
  value       = azurerm_search_service.search.id
}

output "storage_account_ids" {
  description = "Resource IDs of per-account Storage Accounts"
  value       = { for k, v in azurerm_storage_account.storage : k => v.id }
}

output "cosmos_db_ids" {
  description = "Resource IDs of per-account CosmosDB accounts"
  value       = { for k, v in azurerm_cosmosdb_account.cosmos : k => v.id }
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

output "deployment_summary" {
  description = "Summary of the deployment topology"
  value = {
    ai_foundry_access = var.ai_foundry_public_access
    search_access     = var.search_public_access ? "Public" : "Private (Shared)"
    storage_access    = var.storage_public_access ? "Public" : "Private (Per-Account)"
    cosmos_access     = var.cosmos_public_access ? "Public" : "Private (Per-Account)"
    accounts          = { for k, v in var.accounts : k => v.project_name }
  }
}
