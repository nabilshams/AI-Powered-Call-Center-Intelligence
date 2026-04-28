@description('Name of the Azure OpenAI account')
param name string

@description('Location for the Azure OpenAI account')
param location string = resourceGroup().location

@description('Tags for the Azure OpenAI account')
param tags object = {}

@description('SKU for the Azure OpenAI account')
param sku string = 'S0'

@description('OpenAI model deployment name')
param modelName string = 'gpt-4.1-mini'

@description('Model version')
param modelVersion string = ''

@description('Deployment capacity (tokens per minute in thousands)')
param deploymentCapacity int = 30

@description('Custom subdomain name for the account')
param customSubDomainName string = ''

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

var subdomainName = !empty(customSubDomainName) ? customSubDomainName : name

resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: subdomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAIAccount
  name: modelName
  sku: {
    name: 'Standard'
    capacity: deploymentCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: !empty(modelVersion) ? modelVersion : null
    }
  }
}

output id string = openAIAccount.id
output name string = openAIAccount.name
output endpoint string = openAIAccount.properties.endpoint
output primaryKey string = openAIAccount.listKeys().key1
output deploymentName string = deployment.name
