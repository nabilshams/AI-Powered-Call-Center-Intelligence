using './main.bicep'

// Required parameters
param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus')

// Speech Services configuration
param speechRegion = readEnvironmentVariable('AZURE_SPEECH_REGION', 'eastus')
param locale = readEnvironmentVariable('TRANSCRIPTION_LOCALE', 'en-US')

// Transcription options
param profanityFilterMode = readEnvironmentVariable('PROFANITY_FILTER_MODE', 'Masked')
param punctuationMode = readEnvironmentVariable('PUNCTUATION_MODE', 'DictatedAndAutomatic')
param addDiarization = bool(readEnvironmentVariable('ADD_DIARIZATION', 'true'))
param addWordLevelTimestamps = bool(readEnvironmentVariable('ADD_WORD_LEVEL_TIMESTAMPS', 'true'))
param sentimentAnalysis = bool(readEnvironmentVariable('SENTIMENT_ANALYSIS', 'true'))
param piiRedaction = bool(readEnvironmentVariable('PII_REDACTION', 'true'))

// Azure OpenAI for call summarization
param deployOpenAI = bool(readEnvironmentVariable('DEPLOY_AZURE_OPENAI', 'true'))
param openAIModelName = readEnvironmentVariable('AZURE_OPENAI_MODEL_NAME', 'gpt-4.1-mini')
