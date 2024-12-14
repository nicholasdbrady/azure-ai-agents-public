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

@description('The name of the virtual network')
param vnetName string = 'agents-vnet-${suffix}'

@description('The name of Agents Subnet')
param agentsSubnetName string = 'agents-subnet-${suffix}'

@description('The name of Customer Hub subnet')
param cxSubnetName string = 'hub-subnet-${suffix}'

param userAssignedIdentityName string

var cxSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, cxSubnetName)
var agentSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, agentsSubnetName)


resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: userAssignedIdentityName
  scope: resourceGroup()
}


// Step1: Create User Assigned Identity and configure role based access assignment
// Tutorial: Create a user-assigned-identity & role-assignment
// Documentation: https://github.com/Azure/azure-quickstart-templates/blob/master/modules/Microsoft.ManagedIdentity/user-assigned-identity-role-assignment/1.0/main.bicep

// 1a. Create a user-assigned-identity
// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities?pivots=deployment-language-bicep

// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.network/virtualnetworks?pivots=deployment-language-bicep
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
      ]
    }
    subnets: [
      {
        name: cxSubnetName
        properties: {
          addressPrefix: '172.16.0.0/24'
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
        name: agentsSubnetName
        properties: {
          addressPrefix: '172.16.101.0/24'
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
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
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

module storageAccessAssignment './storage-role-assignments.bicep' = {
  name: 'dependencies-${suffix}-storage-rbac'
  params: {
    suffix: suffix
    storageName: storageNameCleaned
    UAIPrincipalId: uai.properties.principalId
    }
  dependsOn: [
    storage
  ]
}

module keyVaultAccessAssignment './keyvault-role-assignments.bicep' = {
  name: 'dependencies-${suffix}-keyvault-rbac'
  params: {
    suffix: suffix
    keyvaultName: keyvaultName
    UAIPrincipalId: uai.properties.principalId
    }
  dependsOn: [ keyVault ]
}

module cognitiveServicesAccessAssignment './cognitive-services-role-assignments.bicep' = {
  name: 'dependencies-${suffix}-cogsvc-rbac'
  params: {
    suffix: suffix
    UAIPrincipalId: uai.properties.principalId
    }
  dependsOn: [ keyVault ]
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
