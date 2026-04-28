@description('Name of the Cognitive Services account')
param name string

@description('Location for the Cognitive Services account')
param location string = resourceGroup().location

@description('Tags for the Cognitive Services account')
param tags object = {}

@description('Kind of Cognitive Services account')
@allowed([
  'SpeechServices'
  'TextAnalytics'
  'ComputerVision'
  'Face'
  'FormRecognizer'
  'ContentModerator'
  'CustomVision.Training'
  'CustomVision.Prediction'
  'LUIS'
  'QnAMaker'
  'Personalizer'
  'AnomalyDetector'
  'ImmersiveReader'
  'Bing.Search.v7'
])
param kind string

@description('SKU for the Cognitive Services account')
param sku string = 'S0'

@description('Custom subdomain name for the account (optional)')
param customSubDomainName string = ''

@description('Whether to disable local authentication')
param disableLocalAuth bool = false

@description('Network ACLs for the Cognitive Services account')
param networkAcls object = {
  defaultAction: 'Allow'
  ipRules: []
  virtualNetworkRules: []
}

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

resource cognitiveServicesAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: !empty(customSubDomainName) ? customSubDomainName : null
    disableLocalAuth: disableLocalAuth
    networkAcls: networkAcls
    publicNetworkAccess: publicNetworkAccess
  }
}

output id string = cognitiveServicesAccount.id
output name string = cognitiveServicesAccount.name
output endpoint string = cognitiveServicesAccount.properties.endpoint
output primaryKey string = cognitiveServicesAccount.listKeys().key1
output secondaryKey string = cognitiveServicesAccount.listKeys().key2
