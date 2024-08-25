

data "azurerm_client_config" "current" {}


resource "azurerm_resource_group" "rg" {
  name     = "tq-function-app-rg"
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "tqfunctionappstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "function_app_container" {
  name                  = "zips"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "function_app_package" {
  name                   = "functionapp.zip"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.function_app_container.name
  type                   = "Block"
  source                 = "C:\\Users\\Tarek\\source\\repos\\Terraform_functionapp\\Terraform_functionapp\\Terraform_functionapp.zip"
}


resource "azurerm_service_plan" "asp" {
  name                = "tq-function-app-service-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type = "Windows"
  sku_name = "S1"
 
  
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = "tq-sql-server"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "Admin1234"
  administrator_login_password = "Admin.12345678"
}



resource "azurerm_mssql_database" "sql_database" {
  name           = "tq-product-db"
  server_id      = azurerm_mssql_server.sql_server.id
  sku_name       = "Basic"
  max_size_gb    = 2
  zone_redundant = false
  tags = {
    foo = "bar"
  }
}


resource "azurerm_key_vault" "kv" {
  name                = "tq-restapi-keyvault"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "List"
    ]
  }
}

resource "azurerm_key_vault_secret" "sql_secret" {
  name         = "sql"
  value        = "Server=${azurerm_mssql_server.sql_server.name}.database.windows.net;Database=${azurerm_mssql_database.sql_database.name};User ID=${azurerm_mssql_server.sql_server.administrator_login};Password=${azurerm_mssql_server.sql_server.administrator_login_password};"
  key_vault_id = azurerm_key_vault.kv.id
}



resource "azurerm_windows_function_app" "function_app" {
  name                = "tareksfunctionapptest1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = azurerm_storage_blob.function_app_package.url
  }

  site_config {
    application_stack {
      dotnet_version = "v8.0"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "function_app_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_function_app.function_app.identity[0].principal_id 

  secret_permissions = [
    "Get",
    "List"
  ]
}

