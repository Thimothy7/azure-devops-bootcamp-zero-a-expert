@minLength(3) // decorateur pour valider la longueur minimale du nom du compte de stockage
@maxLength(24) // decorateur pour valider la longueur maximale du nom du compte de stockage
@description('Nom du compte de stockage') // description du paramètre 
param storageAccountName string // nom du paramètre

@description('Région Azure') // description du paramètre
param location string = resourceGroup().location // valeur par défaut de la région

@allowed([ // liste des valeurs autorisées
  'Standard_LRS'
  'Standard_GRS'
  'Premium_LRS'
])
param sku string = 'Standard_LRS'

@description('Tags applicables')
param tags object = {}

var storageKind = 'StorageV2' // valeur par défaut de la ressource

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: { name: sku }
  kind: storageKind
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

output storageId string = storageAccount.id
output storageEndpoint string = storageAccount.properties.primaryEndpoints.blob
