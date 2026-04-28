@description('Name of the App Service')
param name string

@description('Location for the App Service')
param location string = resourceGroup().location

@description('Tags for the App Service')
param tags object = {}

@description('App Service Plan ID')
param appServicePlanId string

@description('Runtime stack')
@allowed([
  'NODE|18-lts'
  'NODE|20-lts'
  'DOTNETCORE|8.0'
  'PYTHON|3.11'
])
param linuxFxVersion string = 'NODE|18-lts'

@description('App settings')
param appSettings array = []

@description('Always On setting')
param alwaysOn bool = false

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: appSettings
    }
  }
}

output id string = appService.id
output name string = appService.name
output defaultHostname string = appService.properties.defaultHostName
output url string = 'https://${appService.properties.defaultHostName}'
