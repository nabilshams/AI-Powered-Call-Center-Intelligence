targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The Azure Speech Services region')
@allowed([
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westcentralus'
  'westus'
  'westus2'
  'canadacentral'
  'brazilsouth'
  'eastasia'
  'southeastasia'
  'australiaeast'
  'centralindia'
  'japaneast'
  'japanwest'
  'koreacentral'
  'northeurope'
  'westeurope'
  'francecentral'
  'uksouth'
])
param speechRegion string = 'eastus'

@description('The locale for transcription')
@allowed([
  'ar-BH'
  'ar-EG'
  'ar-SY'
  'de-DE'
  'en-AU'
  'en-CA'
  'en-GB'
  'en-IN'
  'en-NZ'
  'en-US'
  'es-ES'
  'es-MX'
  'fi-FI'
  'fr-CA'
  'fr-FR'
  'gu-IN'
  'hi-IN'
  'it-IT'
  'ja-JP'
  'ko-KR'
  'mr-IN'
  'nb-NO'
  'nl-NL'
  'pl-PL'
  'pt-BR'
  'pt-PT'
  'ru-RU'
  'sv-SE'
  'ta-IN'
  'te-IN'
  'th-TH'
  'tr-TR'
  'zh-CN'
  'zh-HK'
  'zh-TW'
])
param locale string = 'en-US'

@description('Enable profanity filtering')
@allowed([
  'None'
  'Removed'
  'Tags'
  'Masked'
])
param profanityFilterMode string = 'Masked'

@description('Enable punctuation mode')
@allowed([
  'None'
  'Dictated'
  'Automatic'
  'DictatedAndAutomatic'
])
param punctuationMode string = 'DictatedAndAutomatic'

@description('Enable diarization (speaker identification)')
param addDiarization bool = true

@description('Enable word-level timestamps')
param addWordLevelTimestamps bool = true

@description('Enable sentiment analysis')
param sentimentAnalysis bool = true

@description('Enable PII redaction')
param piiRedaction bool = true

@description('Deploy Azure OpenAI for summarization')
param deployOpenAI bool = true

@description('OpenAI model deployment name')
param openAIModelName string = 'gpt-4.1-mini'

// Generate unique suffix for resource names
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  project: 'call-center-intelligence'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Azure Speech Services
module speechServices './modules/cognitive-services.bicep' = {
  name: 'speech-${resourceToken}'
  scope: rg
  params: {
    name: '${abbrs.cognitiveServicesAccounts}speech-${resourceToken}'
    location: speechRegion
    tags: tags
    kind: 'SpeechServices'
    sku: 'S0'
  }
}

// Azure Language Services (Text Analytics)
module languageServices './modules/cognitive-services.bicep' = {
  name: 'language-${resourceToken}'
  scope: rg
  params: {
    name: '${abbrs.cognitiveServicesAccounts}lang-${resourceToken}'
    location: location
    tags: tags
    kind: 'TextAnalytics'
    sku: 'S'
  }
}

// Azure OpenAI (optional)
module openAI './modules/openai.bicep' = if (deployOpenAI) {
  name: 'openai-${resourceToken}'
  scope: rg
  params: {
    name: '${abbrs.cognitiveServicesAccounts}oai-${resourceToken}'
    location: location
    tags: tags
    modelName: openAIModelName
  }
}

// App Service Plan for web apps
module appServicePlan './modules/app-service-plan.bicep' = {
  name: 'appserviceplan-${resourceToken}'
  scope: rg
  params: {
    name: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    skuName: 'B1'
    skuTier: 'Basic'
  }
}

// Frontend App Service (ReactJS)
module frontendApp './modules/app-service.bicep' = {
  name: 'frontend-${resourceToken}'
  scope: rg
  params: {
    name: '${abbrs.webSitesAppService}frontend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'frontend' })
    appServicePlanId: appServicePlan.outputs.id
    linuxFxVersion: 'NODE|18-lts'
    appSettings: [
      {
        name: 'REACT_APP_BACKEND_URL'
        value: 'https://${abbrs.webSitesAppService}backend-${resourceToken}.azurewebsites.net'
      }
    ]
  }
}

// Backend App Service (ExpressJS)
module backendApp './modules/app-service.bicep' = {
  name: 'backend-${resourceToken}'
  scope: rg
  params: {
    name: '${abbrs.webSitesAppService}backend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'backend' })
    appServicePlanId: appServicePlan.outputs.id
    linuxFxVersion: 'NODE|18-lts'
    appSettings: [
      {
        name: 'SPEECH_KEY'
        value: speechServices.outputs.primaryKey
      }
      {
        name: 'SPEECH_REGION'
        value: speechRegion
      }
      {
        name: 'LANGUAGE_KEY'
        value: languageServices.outputs.primaryKey
      }
      {
        name: 'LANGUAGE_ENDPOINT'
        value: languageServices.outputs.endpoint
      }
      {
        name: 'OPENAI_API_KEY'
        value: deployOpenAI ? openAI.outputs.primaryKey : ''
      }
      {
        name: 'OPENAI_ENDPOINT'
        value: deployOpenAI ? openAI.outputs.endpoint : ''
      }
    ]
  }
}

// Outputs for azd
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP string = rg.name

// Speech Services outputs
output AZURE_SPEECH_SERVICES_KEY string = speechServices.outputs.primaryKey
output AZURE_SPEECH_SERVICES_REGION string = speechRegion
output AZURE_SPEECH_SERVICES_ENDPOINT string = speechServices.outputs.endpoint

// Language Services outputs
output AZURE_LANGUAGE_SERVICES_KEY string = languageServices.outputs.primaryKey
output AZURE_LANGUAGE_SERVICES_ENDPOINT string = languageServices.outputs.endpoint

// OpenAI outputs (conditional)
output AZURE_OPENAI_ENDPOINT string = deployOpenAI ? openAI.outputs.endpoint : ''
output AZURE_OPENAI_KEY string = deployOpenAI ? openAI.outputs.primaryKey : ''

// Configuration outputs
output TRANSCRIPTION_LOCALE string = locale
output PROFANITY_FILTER_MODE string = profanityFilterMode
output PUNCTUATION_MODE string = punctuationMode
output ADD_DIARIZATION string = string(addDiarization)
output ADD_WORD_LEVEL_TIMESTAMPS string = string(addWordLevelTimestamps)
output SENTIMENT_ANALYSIS string = string(sentimentAnalysis)
output PII_REDACTION string = string(piiRedaction)

// App Service outputs
output AZURE_APP_SERVICE_PLAN_NAME string = appServicePlan.outputs.name
output FRONTEND_APP_NAME string = frontendApp.outputs.name
output FRONTEND_APP_URL string = frontendApp.outputs.url
output BACKEND_APP_NAME string = backendApp.outputs.name
output BACKEND_APP_URL string = backendApp.outputs.url
