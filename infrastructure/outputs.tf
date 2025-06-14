output "cosmosdb_connection_string" {
  value = azurerm_cosmosdb_account.example.connection_strings[0]
  sensitive = true
}
output "blob_connection_string" {
  value = azurerm_storage_account.example.primary_connection_string
  sensitive = true
}
