// Creates an Azure AI resource with proxied endpoints for the Azure AI services provider

@description('Azure region of the deployment')
param location string = 'westus2'

@description('Tags to add to the resources')
param tags object

@description('AI Project name')
param aiProjectName string = 'project-demo-qklu-deployment'

@description('AI Project display name')
param aiProjectFriendlyName string = 'Agents Project resource'

@description('AI Project description')
param aiProjectDescription string = 'This is an example AI Project resource for use in Azure AI Studio.'

@description('Resource ID of the AI Hub resource')
param aiHubId string = '/subscriptions/921496dc-987f-410f-bd57-426eb2611356/resourceGroups/agents-bicep-test-e2e/providers/Microsoft.MachineLearningServices/workspaces/hub-demo-qklu'

@description('Name for capabilityHost.')
param capabilityHostName string = 'project-demo-qklu-caphost1'

@description('Name for ACS connection.')
param acsConnectionName string = 'hub-demo-qklu-connection-AISearch'

@description('Name for ACS connection.')
param aoaiConnectionName string = 'hub-demo-qklu-connection-AIServices_aoai'

param uaiName string = 'secured-agents-identity-qklu'
param subnetId string = '/subscriptions/921496dc-987f-410f-bd57-426eb2611356/resourceGroups/agents-bicep-test-e2e/providers/Microsoft.Network/virtualNetworks/agents-vnet-qklu/subnets/agents-subnet-qklu'

//for constructing endpoint
var subscriptionId = subscription().subscriptionId
var resourceGroupName = resourceGroup().name

var projectConnectionString = '${location}.api.azureml.ms;${subscriptionId};${resourceGroupName};${aiProjectName}'


var storageConnections = ['${aiProjectName}/workspaceblobstore']
var aiSearchConnection = ['${acsConnectionName}']
var aiServiceConnections = ['${aoaiConnectionName}']

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: uaiName
  scope: resourceGroup()
}


// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces?tabs=bicep
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: aiProjectName
  location: location
  tags: union(tags, {
    ProjectConnectionString: projectConnectionString
  })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
  }
  properties: {
    // organization
    friendlyName: aiProjectFriendlyName
    description: aiProjectDescription
    primaryUserAssignedIdentity: uai.id

    // dependent resources
    hubResourceId: aiHubId
  }
  kind: 'project'

  // Resource definition for the capability host
  // Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/workspaces/capabilityhosts?tabs=bicep
  resource capabilityHost 'capabilityHosts@2024-10-01-preview' = {
    name: '${aiProjectName}-${capabilityHostName}'
    properties: {
      capabilityHostKind: 'Agents'
      aiServicesConnections: aiServiceConnections
      vectorStoreConnections: aiSearchConnection
      storageConnections: storageConnections
    }
  }
}
