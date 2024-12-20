param aiServicesName string
param aiSearchName string
param storageName string
param vnetName string
param cxSubnetName string

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiServicesName
  scope: resourceGroup()
}

resource aiSearch 'Microsoft.Search/searchServices@2023-11-01' existing = {
  name: aiSearchName
  scope: resourceGroup()
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource cxSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: cxSubnetName
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageName
  scope: resourceGroup()
}

resource aiServicesPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiServicesName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: cxSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${aiServicesName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiServices.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource aiSearchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiSearchName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: cxSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${aiSearchName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: aiSearch.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${storageName}-private-endpoint'
  location: resourceGroup().location
  properties: {
    subnet: {
      id: cxSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${storageName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource aiServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azureml.ms'
  location: 'global'
}


resource aiSearchPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.search.windows.net'
  location: 'global'
}

resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}
