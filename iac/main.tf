resource "azurerm_resource_group" "main" {
  name     = "AzDevOps"
  location = "Brazil South"
}

resource "azurerm_mssql_server" "main" {
  name                         = "azapp-dbserver"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sawork"
  administrator_login_password = "67001223Work"
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "AlllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "main" {
  name         = "azapp-db"
  server_id    = azurerm_mssql_server.main.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 1
  sku_name     = "Basic"
}

resource "azurerm_container_registry" "main" {
  name                = "azdevrpf"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
}

resource "azurerm_service_plan" "main" {
  name                = "az-devrpf-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_user_assigned_identity" "main" {
  name                = "webappacr"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "main" {
  role_definition_name = "acrpull"
  scope                = azurerm_container_registry.main.id
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}

resource "azurerm_linux_web_app" "main" {
  name                                     = "azapprpc-appservice"
  location                                 = azurerm_resource_group.main.location
  resource_group_name                      = azurerm_resource_group.main.name
  service_plan_id                          = azurerm_service_plan.main.id
  ftp_publish_basic_authentication_enabled = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  site_config {
    always_on                                     = true
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.main.client_id

    application_stack {
      docker_registry_url = "https://${azurerm_container_registry.main.login_server}"
      docker_image_name   = "azapp:latest"
    }
  }

  app_settings = {
    "WEBSITES_PORT"                       = "8080"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_ENABLE_CI"                    = "true"
  }

  connection_string {
    name  = "AzApp"
    type  = "SQLServer"
    value = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password=${azurerm_mssql_server.main.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
}

resource "azurerm_container_registry_task" "mytask" {
  name                  = "az-app-task"
  container_registry_id = azurerm_container_registry.main.id

  platform {
    os = "Linux"
  }

  docker_step {
    dockerfile_path      = "Dockerfile"
    context_path         = "https://github.com/reniciuspagotto/az-app-container#main:."
    context_access_token = var.github_pat
    image_names          = ["azapp:{{.Run.Commit}}", "azapp:latest"]
  }

  source_trigger {
    name            = "code-change-main"
    events          = ["commit"]
    repository_url  = "https://github.com/reniciuspagotto/az-app-container.git"
    branch          = "main"
    source_type     = "Github"

    authentication {
      token      = var.github_pat 
      token_type = "PAT"
      scope      = "repo" 
    }
  }

  source_trigger {
    name            = "code-change-feature"
    events          = ["commit"]
    repository_url  = "https://github.com/reniciuspagotto/az-app-container.git"
    branch          = "feature-*"
    source_type     = "Github"

    authentication {
      token      = var.github_pat 
      token_type = "PAT"
      scope      = "repo" 
    }
  }
}

resource "azurerm_container_registry_webhook" "app_webhook" {
  name                = "webhookappservice"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  registry_name       = azurerm_container_registry.main.name
  
  service_uri         = "https://${azurerm_linux_web_app.main.site_credential.0.name}:${azurerm_linux_web_app.main.site_credential.0.password}@${lower(azurerm_linux_web_app.main.name)}.scm.azurewebsites.net/api/registry/webhook"
  
  status              = "enabled"
  scope               = "azapp:*"
  actions             = ["push"]
  
  custom_headers = {
    "Content-Type" = "application/json"
  }
}