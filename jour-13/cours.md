# Formation Complète : Azure Bicep – Infrastructure as Code nouvelle génération

Azure Bicep est le langage d'infrastructure as code (IaC) de nouvelle génération pour Microsoft Azure, conçu pour remplacer les templates ARM en JSON. Avec une syntaxe déclarative, concise et lisible, Bicep permet de déployer, gérer et faire évoluer votre infrastructure cloud de manière fiable et reproductible. 

Bicep offre une prise en charge immédiate de toutes les ressources et versions d'API Azure, une syntaxe simplifiée, une expérience de développement optimisée avec VS Code, et des résultats idempotents. Il permet également d'organiser votre code en modules réutilisables. Ce cours vous guidera à travers l'installation, la syntaxe, les modules, les bonnes pratiques et l'intégration CI/CD, avec des exemples concrets et des instructions de nettoyage pour éviter toute facturation inattendue.


## 1. Introduction à Bicep

### 1.1 Qu’est-ce qu’Azure Bicep ?

Azure Bicep est un langage dédié à la gestion d’infrastructure Azure. Contrairement aux templates ARM en JSON, Bicep offre une syntaxe plus simple, plus concise et plus lisible. 

Le fichier `.bicep` que vous écrivez est transpilé (converti) en JSON ARM avant d’être envoyé à Azure. Mais vous n’avez jamais besoin de manipuler le JSON vous-même.

**Caractéristiques clés :**
- **Support immédiat** : Dès qu’Azure publie une nouvelle ressource ou API, Bicep la supporte immédiatement. 
- **Syntaxe simple** : Plus besoin de maîtriser le JSON. La syntaxe Bicep est intuitive.
- **Orchestration automatique** : ARM gère l’ordre de création des ressources et les dépendances.
- **Modularité** : Découpez votre infrastructure en modules réutilisables.

### 1.2 Pourquoi utiliser Bicep plutôt que ARM JSON ?

| Critère | ARM JSON | Bicep |
| :--- | :--- | :--- |
| **Syntaxe** | Verbose, accolades imbriquées | Propre, lisible |
| **Complexité** | Gestion manuelle des dépendances | Dépendances implicites |
| **Réutilisabilité** | Linked templates complexes | Modules simples |
| **Expérience VS Code** | Validation de base | IntelliSense complet, type safety |
| **Courbe d’apprentissage** | JSON + ARM spécificités | Quelques heures |

### 1.3 Bicep vs Terraform

Bicep est **spécifique à Azure**. Terraform est **multi-cloud**. Bicep est recommandé par Microsoft pour tout nouveau projet Azure.

---

## 2. Installation et configuration

### 2.1 Prérequis

- Un abonnement Azure actif
- Visual Studio Code (recommandé)
- Azure CLI (optionnel mais recommandé)

### 2.2 Installation de Bicep

```bash
# Vérifier si Bicep est installé
az bicep version

# Installer ou mettre à jour Bicep via Azure CLI
az bicep install

# Installer une version spécifique
az bicep install --version v0.39.26
```

### 2.3 Extension VS Code

Installez l’extension **Bicep** depuis le marketplace VS Code (ms-azuretools.vscode-bicep). Cette extension offre :

- Autocomplétion intelligente
- Validation syntaxique en direct
- IntelliSense pour toutes les ressources Azure
- Aperçu de la transpilation

### 2.4 Authentification Azure

```bash
# Se connecter à Azure
az login

# Sélectionner l'abonnement par défaut
az account set --subscription "mon-subscription-id"

# Vérifier
az account show
```

---

## 3. Syntaxe fondamentale

### 3.1 Structure d’un fichier Bicep

```bicep
// Paramètres – valeurs fournies au déploiement
param storageAccountName string
param location string = resourceGroup().location

// Variables – valeurs calculées localement
var storageSku = 'Standard_LRS'

// Ressources – l'infrastructure à déployer
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: { name: storageSku }
  kind: 'StorageV2'
}

// Outputs – valeurs retournées après déploiement
output storageAccountId string = storageAccount.id
```

### 3.2 Types de données

```bicep
param myString string
param myInt int = 10
param myBool bool = true
param myObject object = { name: 'value', count: 5 }
param myArray array = ['dev', 'test', 'prod']
```

### 3.3 Fonctions intégrées courantes

| Fonction | Exemple | Description |
| :--- | :--- | :--- |
| `resourceGroup().location` | `resourceGroup().location` | Région du groupe de ressources |
| `uniqueString()` | `uniqueString(resourceGroup().id)` | Génère une chaîne unique |
| `concat()` | `concat('storage', uniqueString)` | Concatène des chaînes |
| `toUpper()` / `toLower()` | `toUpper('hello')` | Change la casse |

### 3.4 Dépendances implicites

Bicep gère automatiquement les dépendances. Si une ressource utilise une propriété d’une autre (exemple : l’ID d’un VNet), Bicep déduit qu’elle doit être créée après.

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'myVnet'
  // ...
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = {
  parent: vnet                      // Dépendance implicite
  name: 'default'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}
```

> La propriété `parent` lie la ressource enfant à sa ressource parente.

### 3.5 Dépendances explicites

Si nécessaire, vous pouvez forcer une dépendance avec `dependsOn`.

```bicep
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'myVM'
  dependsOn: [ storageAccount ]      // Attendre la création du storage
  // ...
}
```

---

## 4. Paramètres et décorateurs

### 4.1 Décorateurs de paramètres

Les décorateurs permettent d’ajouter des contraintes et métadonnées.

```bicep
@minLength(3)
@maxLength(24)
@description('Nom du compte de stockage')
param storageAccountName string

@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@secure()
param adminPassword string

@secure()
param adminCredentials object
```

Le décorateur `@secure()` protège les valeurs sensibles en les excluant des logs et de l’historique de déploiement.

### 4.2 Valeurs par défaut

```bicep
param location string = resourceGroup().location
param sku string = 'Standard_LRS'
```

> Ne jamais utiliser de valeurs par défaut codées en dur pour des paramètres marqués `@secure()` – cela exposerait les secrets.

### 4.3 Fichier de paramètres (.bicepparam)

Pour isoler les valeurs propres à chaque environnement :

```bicep
// parameters-dev.bicepparam
using 'main.bicep'
param storageAccountName = 'mystoragedev'
param environment = 'dev'
```

```bash
az deployment group create \
  --resource-group rg-project \
  --parameters parameters-dev.bicepparam
```

---

## 5. Variables

Les variables simplifient le code en évitant la répétition d’expressions complexes.

```bicep
param environment string = 'dev'

var storageSku = (environment == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
var resourceTags = {
  Environment: environment
  CreatedBy: 'Bicep'
  CostCenter: 'Finance'
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'mystorage'
  tags: resourceTags
  sku: { name: storageSku }
  // ...
}
```

---

## 6. Boucles et déploiement conditionnel

### 6.1 Boucle `for` pour créer plusieurs ressources

```bicep
param subnetNames array = ['web', 'app', 'data']

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'myVnet'
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [ for name in subnetNames: {
      name: name
      properties: { addressPrefix: '10.0.${indexOf(subnetNames, name) + 1}.0/24' }
    } ]
  }
}
```

### 6.2 Boucle avec condition

```bicep
param deployAdditionalSubnet bool = true

resource additionalSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = if (deployAdditionalSubnet) {
  parent: vnet
  name: 'extra'
  properties: { addressPrefix: '10.0.4.0/24' }
}
```

### 6.3 Déploiement conditionnel de ressources

```bicep
param deployStorage bool = true

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = if (deployStorage) {
  name: 'mystorage'
  // ...
}
```

### 6.4 Choix entre ressource nouvelle ou existante

```bicep
param newOrExisting string = 'new'
param existingStorageName string = ''

resource saNew 'Microsoft.Storage/storageAccounts@2023-05-01' = if (newOrExisting == 'new') {
  name: 'mystorage${uniqueString(resourceGroup().id)}'
  // ...
}

resource saExisting 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (newOrExisting == 'existing') {
  name: existingStorageName
}

output storageId string = (newOrExisting == 'new') ? saNew.id : saExisting.id
```

---

## 7. Modules – Réutiliser et organiser

Un module est un fichier Bicep déployé depuis un autre fichier Bicep. Les modules permettent de découper une infrastructure complexe en composants réutilisables.

### 7.1 Créer un module

`storage-module.bicep` :

```bicep
param storageName string
param location string = resourceGroup().location
param sku string = 'Standard_LRS'

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: { name: sku }
  kind: 'StorageV2'
}

output storageId string = storage.id
```

### 7.2 Utiliser un module

`main.bicep` :

```bicep
param environment string = 'dev'
param projectName string = 'myapp'

var storageName = '${projectName}${environment}storage${uniqueString(resourceGroup().id)}'

module storageModule 'storage-module.bicep' = {
  name: 'storageDeployment'
  params: {
    storageName: storageName
    sku: (environment == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
  }
}

output storageId string = storageModule.outputs.storageId
```

### 7.3 Registre de modules public

Azure met à disposition un registre public de modules vérifiés :

```bicep
module keyVault 'br/public:security/keyvault:1.0.0' = {
  name: 'keyvaultModule'
  params: {
    name: 'myKeyVault'
    // ...
  }
}
```

### 7.4 Registre privé

Pour partager des modules au sein de votre organisation, publiez-les dans un registre de conteneurs Azure (ACR).

```bash
# Publier un module
az bicep publish \
  --file storage-module.bicep \
  --target 'br:myregistry.azurecr.io/bicep/modules/storage:v1'
```

```bicep
// Utiliser depuis le registre privé
module storageModule 'br:myregistry.azurecr.io/bicep/modules/storage:v1' = {
  name: 'storageDeployment'
  params: {
    storageName: storageName
  }
}
```

---

## 8. Déploiement avec Azure CLI

### 8.1 Déploiement de base

```bash
# Au niveau du groupe de ressources
az deployment group create \
  --resource-group rg-bicep-demo \
  --template-file main.bicep \
  --parameters environment=dev

# Avec un fichier de paramètres
az deployment group create \
  --resource-group rg-bicep-demo \
  --template-file main.bicep \
  --parameters parameters-dev.bicepparam
```

### 8.2 Validation avant déploiement (what-if)

```bash
# Simuler les changements sans les appliquer
az deployment group what-if \
  --resource-group rg-bicep-demo \
  --template-file main.bicep
```

L’opération `what-if` prévoit les modifications si le fichier Bicep est déployé, sans rien changer aux ressources existantes.

### 8.3 Modes de déploiement

- **Incrémental (défaut)** : seules les ressources du template sont ajoutées ou modifiées.
- **Complet** : les ressources présentes mais absentes du template sont supprimées.

```bash
az deployment group create \
  --resource-group rg-bicep-demo \
  --template-file main.bicep \
  --mode Complete
```

> Le mode complet peut supprimer des ressources. À utiliser avec précaution.

---

## 9. Bonnes pratiques professionnelles

### 9.1 Nommage et conventions

- Utilisez le **camelCase** : `myResourceGroup`, `storageAccountName`.
- Utilisez `uniqueString(resourceGroup().id)` pour les noms globalement uniques.
- Soyez descriptif et cohérent.

### 9.2 Organisation du code

- **Paramètres en haut** du fichier.
- **Variables ensuite**.
- **Ressources** dans l’ordre logique.
- **Outputs à la fin**.

### 9.3 Sécurité

- Utilisez `@secure()` pour tout paramètre contenant un secret.
- Ne fournissez **jamais** de valeur par défaut codée en dur pour un paramètre sécurisé.
- Pour les mots de passe, passez-les via Azure Key Vault.

### 9.4 Gestion des environnements

- Utilisez des fichiers de paramètres distincts (`parameters-dev.bicepparam`, `parameters-prod.bicepparam`).
- Versionnez vos fichiers Bicep et paramètres dans Git.
- Intégrez le déploiement dans un pipeline CI/CD.

### 9.5 Validation continue

```bash
# Linter intégré
az bicep lint --file main.bicep

# Validation de déploiement (sans appliquer)
az deployment group validate \
  --resource-group rg-bicep-demo \
  --template-file main.bicep
```

---

## 10. Exemples pratiques complets

### 10.1 Exemple 1 : Déployer un compte de stockage

Créons un fichier `storage.bicep` :

```bicep
@minLength(3)
@maxLength(24)
@description('Nom du compte de stockage')
param storageAccountName string

@description('Région Azure')
param location string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Premium_LRS'
])
param sku string = 'Standard_LRS'

@description('Tags applicables')
param tags object = {}

var storageKind = 'StorageV2'

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
```

**Déploiement :**

```bash
az group create --name rg-storage-demo --location francecentral

az deployment group create \
  --resource-group rg-storage-demo \
  --template-file storage.bicep \
  --parameters storageAccountName=monstorageunique tags='{"Environment":"dev","Project":"demo"}'
```

### 10.2 Exemple 2 : VM complète avec VNet, NSG, IP publique

`vm-complete.bicep` :

```bicep
// ===== PARAMÈTRES =====
@description('Nom de la VM')
param vmName string

@description('Nom d’utilisateur administrateur')
param adminUsername string

@secure()
@description('Mot de passe administrateur')
param adminPassword string

@description('Région')
param location string = resourceGroup().location

@description('Taille de la VM')
param vmSize string = 'Standard_B1s'

// ===== VARIABLES =====
var vnetName = '${vmName}-vnet'
var subnetName = 'default'
var publicIpName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'
var nicName = '${vmName}-nic'
var vnetAddressPrefix = '10.0.0.0/16'
var subnetAddressPrefix = '10.0.1.0/24'

// ===== RESSOURCES =====

// Groupe de sécurité réseau
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

// IP publique
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: publicIpName
  location: location
  sku: { name: 'Basic' }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Réseau virtuel
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: [vnetAddressPrefix] }
    subnets: [
      {
        name: subnetName
        properties: { addressPrefix: subnetAddressPrefix }
      }
    ]
  }
}

// Carte réseau
resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: nicName
  location: location
  dependsOn: [ vnet, publicIp, nsg ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: publicIp.id }
          subnet: { id: vnet.properties.subnets[0].id }
        }
      }
    ]
    networkSecurityGroup: { id: nsg.id }
  }
}

// Machine virtuelle
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  dependsOn: [ nic ]
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '22.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        { id: nic.id }
      ]
    }
  }
}

// ===== OUTPUTS =====
output publicIpAddress string = publicIp.properties.ipAddress
output vmId string = vm.id
```

**Déploiement :**

```bash
az group create --name rg-vm-demo --location francecentral

az deployment group create \
  --resource-group rg-vm-demo \
  --template-file vm-complete.bicep \
  --parameters vmName=myvmtest adminUsername=azureuser adminPassword='VotreMotDePasseSecurise123!'
```

### 10.3 Exemple 3 : Architecture multi-environnements

`main.bicep` :

```bicep
param environment string
param location string = resourceGroup().location
param projectName string = 'myapp'

var uniqueString = uniqueString(resourceGroup().id)
var storageName = '${projectName}${environment}stg${uniqueString}'
var vmName = '${projectName}-${environment}-vm'

var storageSku = (environment == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
var vmSize = (environment == 'prod') ? 'Standard_D2s_v3' : 'Standard_B1s'

module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: storageName
    location: location
    sku: storageSku
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vmDeployment'
  params: {
    vmName: vmName
    location: location
    vmSize: vmSize
    adminUsername: 'azureuser'
    adminPassword: adminPassword
  }
}
```

`parameters-dev.bicepparam` :

```bicep
using 'main.bicep'
param environment = 'dev'
```

`parameters-prod.bicepparam` :

```bicep
using 'main.bicep'
param environment = 'prod'
param adminPassword = ''
```

---

## 11. Nettoyage des ressources pour éviter la facturation

Une fois vos exercices terminés, **supprimez toujours vos ressources** pour ne pas être facturé.

### 11.1 Supprimer un groupe de ressources (recommandé)

```bash
# Supprimer un groupe et toutes ses ressources
az group delete --name rg-storage-demo --yes --no-wait

# Supprimer plusieurs groupes
for rg in rg-storage-demo rg-vm-demo rg-bicep-demo; do
  az group delete --name $rg --yes --no-wait
done
```

### 11.2 Supprimer des ressources individuelles

```bash
# Supprimer une VM
az vm delete --name myvmtest --resource-group rg-vm-demo --yes

# Supprimer un compte de stockage
az storage account delete --name monstorageunique --resource-group rg-storage-demo --yes
```

### 11.3 Nettoyage automatique via tags

Ajoutez un tag `Cleanup` à vos ressources de test :

```bicep
tags: {
  Cleanup: 'Auto'
  Environment: 'dev'
}
```

Puis scriptez la suppression :

```bash
# Supprimer les groupes taggés 'Cleanup=Auto'
for rg in $(az group list --query "[?tags.Cleanup=='Auto'].name" -o tsv); do
  az group delete --name $rg --yes --no-wait
done
```

### 11.4 Vérifier qu’il ne reste rien

```bash
# Lister tous les groupes restants
az group list --output table

# Vérifier les ressources dans un groupe spécifique
az resource list --resource-group rg-vm-demo --output table
```

---

## 12. Intégration CI/CD (Azure Pipelines)

Exemple de pipeline YAML pour Azure DevOps :

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  azureSubscription: 'AzureServiceConnection'
  resourceGroup: 'rg-bicep-pipeline'
  location: 'francecentral'

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: $(azureSubscription)
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # What-if avant déploiement
      az deployment group what-if \
        --resource-group $(resourceGroup) \
        --template-file main.bicep \
        --parameters environment=prod
      
      # Déploiement effectif
      az deployment group create \
        --resource-group $(resourceGroup) \
        --template-file main.bicep \
        --parameters environment=prod
```

---

## 13. Dépannage et erreurs courantes

| Erreur | Cause probable | Solution |
| :--- | :--- | :--- |
| `Bicep (BCPXXX)` | Erreur de syntaxe dans le fichier Bicep | Vérifiez l’extension VS Code et corrigez les erreurs signalées |
| `Deployment failed` | Paramètre manquant ou invalide | Vérifiez les paramètres requis et leurs valeurs |
| `Quota exceeded` | Limite de ressources atteinte dans la région | Changez de région ou demandez une augmentation de quota |
| `Authorization failed` | Permissions RBAC insuffisantes | Vérifiez les rôles attribués |
| `Resource not found` | Dépendance non respectée | Utilisez `dependsOn` ou vérifiez les références |

---

## Conclusion

Azure Bicep est l’outil d’infrastructure as code de référence pour Azure. Il combine la puissance des templates ARM avec une syntaxe simple et moderne.

**Points clés à retenir :**
- Bicep est **déclaratif** et **idempotent** – déployez le même fichier plusieurs fois sans crainte.
- Utilisez **VS Code** avec l’extension Bicep pour une expérience de développement optimale.
- Structurez votre code avec **paramètres, variables, ressources et outputs**.
- Découpez en **modules** pour la réutilisabilité.
- Toujours utiliser **what-if** avant chaque déploiement en production.
- **Supprimez systématiquement** les ressources de test pour éviter les coûts.

**Commandes essentielles :**

```bash
# Déploiement
az deployment group create -g <rg> -f <fichier>.bicep

# Simulation
az deployment group what-if -g <rg> -f <fichier>.bicep

# Validation
az deployment group validate -g <rg> -f <fichier>.bicep

# Linting
az bicep lint --file <fichier>.bicep

# Nettoyage
az group delete -g <rg> --yes --no-wait
```