output "cosmosdb_connection_string" {
  value     = azurerm_cosmosdb_account.example.primary_sql_connection_string
  sensitive = true
}

output "blob_connection_string" {
  value     = azurerm_storage_account.example.primary_connection_string
  sensitive = true
}
