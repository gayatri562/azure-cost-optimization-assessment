provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "example" {
  name     = "billing-optimization-rg"
  location = var.location
}

resource "azurerm_cosmosdb_account" "example" {
  name                = "billing-cosmosdb-${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.example.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_cosmosdb_sql_database" "example" {
  name                = "billing-db"
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
}

resource "azurerm_cosmosdb_sql_container" "example" {
  name                = "billing-records"
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
  database_name       = azurerm_cosmosdb_sql_database.example.name
  partition_key_paths = ["/customerId"]
  default_ttl         = 7776000 # 3 months
}

resource "azurerm_cosmosdb_sql_container" "leases" {
  name                = "leases"
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
  database_name       = azurerm_cosmosdb_sql_database.example.name
  partition_key_paths = ["/id"]
}

resource "azurerm_storage_account" "example" {
  name                     = "billingarchive${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}

resource "azurerm_storage_container" "example" {
  name                  = "billing-archive"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_service_plan" "example" {
  name                = "billing-functions-plan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "archival" {
  name                       = "billing-archival-function"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  service_plan_id            = azurerm_service_plan.example.id
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"   = "python"
    "COSMOSDB_CONNECTION_STRING" = azurerm_cosmosdb_account.example.primary_sql_connection_string
    "BLOB_CONNECTION_STRING"     = azurerm_storage_account.example.primary_connection_string
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

resource "azurerm_linux_function_app" "retrieval" {
  name                       = "billing-retrieval-function"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  service_plan_id            = azurerm_service_plan.example.id
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"   = "python"
    "COSMOSDB_CONNECTION_STRING" = azurerm_cosmosdb_account.example.primary_sql_connection_string
    "BLOB_CONNECTION_STRING"     = azurerm_storage_account.example.primary_connection_string
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}
