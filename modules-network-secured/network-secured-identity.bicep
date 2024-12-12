param location string
param userAssignedIdentityName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  location: location
  name: userAssignedIdentityName
}

output uaiId string = userAssignedIdentity.id
output uaiPrincipalId string = userAssignedIdentity.properties.principalId
output uaiClientId string = userAssignedIdentity.properties.clientId
