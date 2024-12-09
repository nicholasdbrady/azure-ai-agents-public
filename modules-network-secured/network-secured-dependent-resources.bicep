// Creates Azure dependent resources for Azure AI studio

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('Tags to add to the resources')
param suffix string

@description('AI services name')
param aiServicesName string

@description('The name of the Key Vault')
param keyvaultName string

@description('The name of the AI Search resource')
param aiSearchName string

@description('Name of the storage account')
param storageName string

var storageNameCleaned = replace(storageName, '-', '')

@description('Model name for deployment')
param modelName string 

@description('Model format for deployment')
param modelFormat string 

@description('Model version for deployment')
param modelVersion string 

@description('Model deployment SKU name')
param modelSkuName string 

@description('Model deployment capacity')
param modelCapacity int 

@description('Model/AI Resource deployment location')
param modelLocation string 

@description('The AI Service Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiServiceAccountResourceId string

@description('The AI Search Service full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiSearchServiceResourceId string 

@description('The AI Storage Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiStorageAccountResourceId string 

@description('The name of the virtual network')
param vnetName string = 'agents-vnet'

@description('The name of Agents Subnet')
param agentsSubnetName string = 'agents-subnet'

@description('The name of Customer Hub subnet')
param cxSubnetName string = 'hub-subnet'

@description('The name of User Assigned Identity')
param userAssignedIdentityName string = 'secured-agents-identity'

@description('The name of UAI Role Assignments')
param userAssignedIdentityRoleAssignmentName string

@description('The name of the role definition')
param roleDefinitionRuleName string = 'b27b48ac-a1a0-4c9e-bcc1-618787217b05'


var cxSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, cxSubnetName)
var agentSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, agentsSubnetName)
var numberOfInstances = 1

// Step1: Create User Assigned Identity and configure role based access assignment
// Tutorial: Create a user-assigned-identity & role-assignment
// Documentation: https://github.com/Azure/azure-quickstart-templates/blob/master/modules/Microsoft.ManagedIdentity/user-assigned-identity-role-assignment/1.0/main.bicep

// 1a. Create a user-assigned-identity
// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities?pivots=deployment-language-bicep
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  location: location
  name: '${userAssignedIdentityName}-${suffix}'
}

//1b. Create role Definitions for UAI
//Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roledefinitions?pivots=deployment-language-bicep
resource roleDefinitions 'Microsoft.Authorization/roleDefinitions@2022-04-01' =  {
  name: roleDefinitionRuleName
  properties: {
    roleName: 'Network Secured Agents Role Definition'
    description: 'Role definition for user assigned identity'
    type: 'CustomRole'
    assignableScopes: [
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}'
    ]
    permissions: [
      {
        actions: [
          //TODO: Restrict to exact permissions required
          'Microsoft.Storage/storageAccounts/queueServices/queues/delete'
          'Microsoft.Storage/storageAccounts/queueServices/queues/read'
          'Microsoft.Storage/storageAccounts/queueServices/queues/write'
          'Microsoft.Storage/storageAccounts/blobServices/containers/delete'
          'Microsoft.Storage/storageAccounts/blobServices/containers/read'
          'Microsoft.Storage/storageAccounts/blobServices/containers/write'
          'Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action'
          'Microsoft.MachineLearningServices/workspaces/*/read'
          'Microsoft.MachineLearningServices/workspaces/*/action'
          'Microsoft.MachineLearningServices/workspaces/*/delete'
          'Microsoft.MachineLearningServices/workspaces/*/write'
          'Microsoft.MachineLearningServices/locations/*/read'
          'Microsoft.Authorization/*/read'
          'Microsoft.Resources/deployments/*'
        ]
        notActions: [
          'Microsoft.MachineLearningServices/workspaces/delete'
          'Microsoft.MachineLearningServices/workspaces/write'
          'Microsoft.MachineLearningServices/workspaces/listKeys/action'
          'Microsoft.MachineLearningServices/workspaces/hubs/write'
          'Microsoft.MachineLearningServices/workspaces/hubs/delete'
          'Microsoft.MachineLearningServices/workspaces/featurestores/write'
          'Microsoft.MachineLearningServices/workspaces/featurestores/delete'
        ]
        dataActions: [
          'Microsoft.Storage/storageAccounts/queueServices/queues/messages/delete'
          'Microsoft.Storage/storageAccounts/queueServices/queues/messages/read'
          'Microsoft.Storage/storageAccounts/queueServices/queues/messages/write'
          'Microsoft.Storage/storageAccounts/queueServices/queues/messages/process/action'
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete'
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write'
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action'
          'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action'
          'Microsoft.CognitiveServices/accounts/OpenAI/*'
          'Microsoft.CognitiveServices/accounts/SpeechServices/*'
          'Microsoft.CognitiveServices/accounts/ContentSafety/*'
        ]
        notDataActions: []
      }
    ]
  }
}

// 1b. Create a role assignment for the user-assigned-identity
// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?pivots=deployment-language-bicep
resource userAssignedIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: userAssignedIdentityRoleAssignmentName
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: roleDefinitions.id
    principalType: 'ServicePrincipal'
  }
}

// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-bicep
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${vnetName}-${suffix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${cxSubnetName}-${suffix}'
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.CognitiveServices'
              locations: [
                modelLocation
              ]
            }
          ]
        }
      }
      {
        name: '${agentsSubnetName}-${suffix}'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'Microsoft.app/environments'
              properties: {
                serviceName: 'Microsoft.app/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-bicep
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyvaultName
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    enableRbacAuthorization: true
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules:[
        {
          id: cxSubnetRef
        }
      ]
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
  dependsOn: [
    virtualNetwork
  ]
}


// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts?pivots=deployment-language-bicep
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: aiServicesName
  location: modelLocation
  sku: {
    name: 'S0'
  }
  kind: 'AIServices' // or 'OpenAI'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: toLower('${(aiServicesName)}')
    apiProperties: {
      statisticsEnabled: false
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules:[
        {
          id: cxSubnetRef
        }
      ]
    }
    publicNetworkAccess: 'Disabled'
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts/deployments?pivots=deployment-language-bicep
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview'= {
  parent: aiServices
  name: modelName
  sku : {
    capacity: modelCapacity
    name: modelSkuName
  }
  properties: {
    model:{
      name: modelName
      format: modelFormat
      version: modelVersion
    }
  }
}

// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.search/searchservices?pivots=deployment-language-bicep
resource aiSearch 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: aiSearchName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    disableLocalAuth: false
    authOptions: { aadOrApiKey: { aadAuthFailureMode: 'http401WithBearerChallenge'}}
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    partitionCount: 1
    publicNetworkAccess: 'Disabled'
    replicaCount: 1
    semanticSearch: 'disabled'
  }
  sku: {
    name: 'standard'
  }
}

// Some regions doesn't support Standard Zone-Redundant storage, need to use Geo-redundant storage
param noZRSRegions array = ['southindia', 'westus']
param sku object = contains(noZRSRegions, location) ? { name: 'Standard_GRS' } : { name: 'Standard_ZRS' }

// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageNameCleaned
  location: location
  kind: 'StorageV2'
  sku: sku
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: cxSubnetRef
        }
      ]
    }
    allowSharedKeyAccess: false
  }
  dependsOn: [
    virtualNetwork
  ]
}

output aiServicesName string =  aiServicesName
output aiservicesID string = aiServices.id
output aiservicesTarget string = aiServices.properties.endpoint
output aiServiceAccountResourceGroupName string = resourceGroup().name
output aiServiceAccountSubscriptionId string = subscription().subscriptionId 

output aiSearchName string = aiSearch.name
output aisearchID string = aiSearch.id
output aiSearchServiceResourceGroupName string = resourceGroup().name
output aiSearchServiceSubscriptionId string = subscription().subscriptionId

output storageAccountName string = storage.name
output storageId string =  storage.id
output storageAccountResourceGroupName string = resourceGroup().name
output storageAccountSubscriptionId string = subscription().subscriptionId

output virtualNetworkName string = virtualNetwork.name
output virtualNetworkId string = virtualNetwork.id
output cxSubnetId string = cxSubnetRef
output agentSubnetId string = agentSubnetRef

output keyvaultId string = keyVault.id

output uaiId string = userAssignedIdentity.id
output uaiPrincipalId string = userAssignedIdentity.properties.principalId
output uaiClientId string = userAssignedIdentity.properties.clientId
