param location string = resourceGroup().location
param environmentName string
param webAppName string
param registryFunctionName string
param sampleFunctionName string

// App Service Plan for Web App
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${environmentName}'
  location: location
  sku: {
    name: 'D1'
    tier: 'Shared'
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

// Storage Account for Functions
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'st${environmentName}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Function App Service Plan (Consumption)
resource functionAppServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-func-${environmentName}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Registry Function App
resource registryFunction 'Microsoft.Web/sites@2022-09-01' = {
  name: registryFunctionName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionAppServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
      ]
    }
  }
}

// Sample Function App
resource sampleFunction 'Microsoft.Web/sites@2022-09-01' = {
  name: sampleFunctionName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionAppServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
      ]
    }
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output registryFunctionUrl string = 'https://${registryFunction.properties.defaultHostName}'
output sampleFunctionUrl string = 'https://${sampleFunction.properties.defaultHostName}'
