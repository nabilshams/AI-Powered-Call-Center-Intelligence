@description('Name of the App Service Plan')
param name string

@description('Location for the App Service Plan')
param location string = resourceGroup().location

@description('Tags for the App Service Plan')
param tags object = {}

@description('SKU name')
@allowed([
  'F1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
param skuName string = 'B1'

@description('SKU tier')
@allowed([
  'Free'
  'Basic'
  'Standard'
  'Premium'
  'PremiumV2'
  'PremiumV3'
])
param skuTier string = 'Basic'

@description('Kind of App Service Plan')
param kind string = 'linux'

@description('Is Linux')
param reserved bool = true

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    reserved: reserved
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
