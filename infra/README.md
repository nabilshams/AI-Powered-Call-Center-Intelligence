# Azure Developer CLI Deployment Guide

This guide explains how to deploy the AI-Powered Call Center Intelligence solution using Azure Developer CLI (azd).

## Prerequisites

1. **Azure Developer CLI (azd)** - Install from [https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)

2. **Azure CLI** - Install from [https://learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli)

3. **Azure Subscription** - You need an active Azure subscription with appropriate permissions

## Quick Start

### 1. Initialize the environment

```bash
# Login to Azure
azd auth login

# Initialize a new environment
azd init

# Or create with a specific environment name
azd env new <environment-name>
```

### 2. Configure environment variables (optional)

Copy the sample environment file and customize:

```bash
# Copy sample env file
cp .azure/.env.sample .azure/<environment-name>/.env

# Edit the values as needed
```

Key configuration options:
- `AZURE_LOCATION`: Azure region for deployment (default: eastus)
- `AZURE_SPEECH_REGION`: Region for Speech Services (default: eastus)
- `TRANSCRIPTION_LOCALE`: Language for transcription (default: en-US)
- `DEPLOY_AZURE_OPENAI`: Set to `false` to skip Azure OpenAI deployment (default: true)
- `AZURE_OPENAI_MODEL_NAME`: Model to deploy (default: gpt-4.1-mini)

### 3. Deploy the infrastructure

```bash
# Provision Azure resources and deploy
azd up
```

This command will:
- Create a resource group
- Deploy Azure Speech Services
- Deploy Azure Language Services (Text Analytics)
- Deploy Azure OpenAI with gpt-4.1-mini model
- Deploy App Service Plan with Frontend and Backend web apps
- Build and deploy the ReactJS frontend
- Build and deploy the ExpressJS backend
- Deploy batch transcription pipeline (ArmTemplateBatch.json)

### 4. View deployment outputs

```bash
# Get all environment values
azd env get-values

# Get specific values
azd env get-values | grep AZURE_SPEECH
```

## Resource Overview

| Resource | Purpose |
|----------|---------|
| Azure Speech Services | Speech-to-text transcription |
| Azure Language Services | Sentiment analysis, PII detection, key phrase extraction |
| Azure OpenAI | Call summarization using GPT models (gpt-4.1-mini by default) |
| App Service Plan | Hosts the frontend and backend web applications |
| Frontend App Service | ReactJS web UI for call center interface |
| Backend App Service | ExpressJS API backend for audio processing |

> **Note:** Storage Account, Service Bus, Key Vault, App Insights, SQL Database, and Azure Functions are created separately via `ArmTemplateBatch.json` for the batch transcription pipeline.

## Using with ArmTemplateBatch.json

After deploying with `azd up`, you can deploy the batch transcription pipeline using the ARM template:

```bash
# Get the Speech and Language keys from azd
azd env get-values

# Deploy ARM template with the keys
az deployment group create \
  --resource-group rg-<environment-name> \
  --template-file call-intelligence-realtime/ai-app-backend/Template/ArmTemplateBatch.json \
  --parameters AzureSpeechServicesKey=<AZURE_SPEECH_SERVICES_KEY> \
               AzureSpeechServicesRegion=<AZURE_SPEECH_SERVICES_REGION> \
               TextAnalyticsKey=<AZURE_LANGUAGE_SERVICES_KEY> \
               TextAnalyticsEndpoint=<AZURE_LANGUAGE_SERVICES_ENDPOINT>
```

## Common Commands

```bash
# Provision only (no deployment)
azd provision

# Tear down all resources
azd down

# Show current environment
azd env list

# Switch environments
azd env select <environment-name>

# Refresh environment values from Azure
azd env refresh
```

## Configuration Options

### Disable Azure OpenAI

```bash
azd env set DEPLOY_AZURE_OPENAI false
azd up
```

### Change OpenAI Model

```bash
azd env set AZURE_OPENAI_MODEL_NAME gpt-4o
azd up
```

### Change Speech Region

```bash
azd env set AZURE_SPEECH_REGION westeurope
azd up
```

### Change Transcription Language

```bash
azd env set TRANSCRIPTION_LOCALE de-DE
azd up
```

## Post-Deployment Configuration

After running `azd up`, configure your application:

1. Get the environment values:
   ```bash
   azd env get-values > .env
   ```

2. Update `call-intelligence-realtime/ai-app-backend/config.json` with the values from the deployment outputs.

3. The following keys are stored in Azure Key Vault:
   - `AzureSpeechServicesKey`
   - `TextAnalyticsKey`

## Troubleshooting

### View deployment logs
```bash
azd provision --debug
```

### Check resource status
```bash
az resource list --resource-group rg-<environment-name>
```

### Re-deploy after changes
```bash
azd up
```

### Clean up failed deployment
```bash
azd down --force --purge
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Resource Group                               │
├─────────────────────────────────────────────────────────────────────┤
│  Deployed by azd (Bicep):                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │    Speech    │  │   Language   │  │ Azure OpenAI │               │
│  │   Services   │  │   Services   │  │(gpt-4.1-mini)│               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │ App Service  │  │   Frontend   │  │   Backend    │               │
│  │    Plan      │  │  (ReactJS)   │  │ (ExpressJS)  │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
├─────────────────────────────────────────────────────────────────────┤
│  Deployed by ArmTemplateBatch.json:                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │   Storage    │  │  Service Bus │  │  Key Vault   │               │
│  │   Account    │  │  (Queues)    │  │  (Secrets)   │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │   Functions  │  │  Event Grid  │  │ App Insights │               │
│  │  (2 Apps)    │  │ (Triggers)   │  │ (Monitoring) │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
│                                                                      │
│  ┌──────────────┐                                                   │
│  │ SQL Database │                                                   │
│  │ (Optional)   │                                                   │
│  └──────────────┘                                                   │
└─────────────────────────────────────────────────────────────────────┘
```

## Related Documentation

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Speech Services](https://learn.microsoft.com/azure/cognitive-services/speech-service/)
- [Azure Language Services](https://learn.microsoft.com/azure/cognitive-services/language-service/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/cognitive-services/openai/)
