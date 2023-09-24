/*
   Begin common prolog commands
   export name=AuthFuncSourceControl
   export name=CrewTaskMgr
   export uniqueName=jac3sukjdrxzi
   export rg=rg_${name}
   export loc=westus
   End common prolog commands

   emacs F10
   Begin commands to deploy this file using Azure CLI with bash
   echo WaitForBuildComplete
   WaitForBuildComplete
   echo "Previous build is complete. Begin deployment build."
   echo az deployment group create --name $name --resource-group $rg   --mode  Incremental  --template-file  deploy-AuthFuncSourceControl.bicep --parameters  '@deploy.parameters.json' 
   az deployment group create --name $name --resource-group $rg   --mode  Incremental  --template-file  deploy-AuthFuncSourceControl.bicep  --parameters  '@deploy.parameters.json' | tr '\r' -d
   echo end deploy
   az resource list -g $rg --query "[?resourceGroup=='$rg'].{ name: name, flavor: kind, resourceType: type, region: location }" --output table | tr '\r' -d
   End commands to deploy this file using Azure CLI with bash

   emacs ESC 2 F10
   Begin commands to shut down this deployment using Azure CLI with bash
   echo CreateBuildEvent.exe
   CreateBuildEvent.exe&
   echo "begin shutdown"
   az deployment group create --mode complete --template-file ./clear-resources.json --resource-group $rg
   #echo az group delete -g $rg  --yes 
   #az group delete -g $rg  --yes 
   BuildIsComplete.exe
   az resource list -g $rg --query "[?resourceGroup=='$rg'].{ name: name, flavor: kind, resourceType: type, region: location }" --output table | tr '\r' -d
   echo "showdown is complete"
   End commands to shut down this deployment using Azure CLI with bash

   emacs ESC 3 F10
   Begin commands for one time initializations using Azure CLI with bash
   az group create -l $loc -n $rg
   export id=`az group show --name $rg --query 'id' --output tsv`
   echo "id=$id"
   #export sp="spad_$name"
   #az ad sp create-for-rbac --name $sp --sdk-auth --role contributor --scopes $id
   #echo "go to github settings->secrets and create a secret called AZURE_CREDENTIALS with the above output"
   if [[ -e clear-resources.json ]]
   then
   echo clear-resources.json already exists
   else
   cat >clear-resources.json <<EOF
   {
    "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
     "contentVersion": "1.0.0.0",
     "resources": [] 
   }
   EOF
   fi
   End commands for one time initializations using Azure CLI with bash

   emacs ESC 4 F10 assign RBAC role
   Begin commands for one time initializations using Azure CLI with bash
   functionApp="${uniqueName}-func-CrewTaskMgrAuthSvcs"
   subscriptionId=`az account show --query 'id' --output tsv`
   #az functionApp identity assign --name $functionAppName --resource-group $rg
   #az ad sp show --id http://spad_$name --query objectId --output tsv
   #az ad sp list | tr '\r' -d
   clientId=73570410-46b1-48a8-b7c2-8f86ebba712d
   echo az role assignment create --assignee $clientId --role Contributor --scope "/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Web/sites/$functionApp"
   az role assignment create --assignee $clientId --role Contributor --scope "/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Web/sites/$functionApp"
   az role assignment list --assignee $clientId
   End commands for one time initializations using Azure CLI with bash

   Shutdown (delete) Function App only
   emacs ESC 5 F10
   Begin commands to shut down this deployment using Azure CLI with bash
   echo CreateBuildEvent.exe
   CreateBuildEvent.exe&
   echo "begin shutdown"
   echo az functionapp delete -g $rg -n  "${uniqueName}-func-CrewTaskMgrAuthSvcs"
   az functionapp delete -g $rg -n  "${uniqueName}-func-CrewTaskMgrAuthSvcs"
   BuildIsComplete.exe
   az resource list -g $rg --query "[?resourceGroup=='$rg'].{ name: name, flavor: kind, resourceType: type, region: location }" --output table
   echo "showdown is complete"
   End commands to shut down this deployment using Azure CLI with bash

   Shutdown (delete) Function app support
   emacs ESC 6 F10
   Begin commands to shut down this deployment using Azure CLI with bash
   echo CreateBuildEvent.exe
   CreateBuildEvent.exe&
   echo "begin shutdown"
   echo az functionapp plan delete --name ${unique-Name}-func-plan-CrewTaskMgrAuthSvcs --resource-group $rg --yes
   az functionapp plan delete --name ${unique-Name}-func-plan-CrewTaskMgrAuthSvcs --resource-group $rg --yes
   echo az storage account delete -n ${uniqueName}stgctmfunc -g $rg --yes
   az storage account delete -n ${uniqueName}stgctmfunc -g $rg --yes
   echo az apim delete -n ${unique-Name}-apim -g $rg --yes
   az apim delete -n ${uniqueName}-apim -g $rg --yes
   subscriptionId=$(az account show --query id --output tsv)
   subscriptionId=$(perl -e '$_=shift; $cr=chr(13); s/$cr//; print' $subscriptionId)
   echo az rest --method delete --header "Accept=application/json" -u "https://management.azure.com/subscriptions/${subscriptionId}/providers/Microsoft.ApiManagement/locations/$loc/deletedservices/${uniqueName}-apim?api-version=2020-06-01-preview"
   az rest --method delete --header "Accept=application/json" -u "https://management.azure.com/subscriptions/${subscriptionId}/providers/Microsoft.ApiManagement/locations/$loc/deletedservices/${uniqueName}-apim?api-version=2020-06-01-preview"
   BuildIsComplete.exe
   az resource list -g $rg --query "[?resourceGroup=='$rg'].{ name: name, flavor: kind, resourceType: type, region: location }" --output table
   echo "showdown is complete"
   End commands to shut down this deployment using Azure CLI with bash

   https://learn.microsoft.com/en-us/azure/azure-functions/functions-infrastructure-as-code?tabs=bicep

 */
param location string = resourceGroup().location
param name string = uniqueString(resourceGroup().id)

@description('The URL for the GitHub repository that contains the project to deploy.')
param repoURL string = 'https://github.com/siegfried01/HelloAzureADAuthenticatedFunc.git'

param funcCrewTaskMgrAuthSvcsName string = 'CrewTaskMgrAuthSvcs'

@description('The branch of the GitHub repository to use.')
param branch string = 'NoAzureADNoCosmos'

resource funcCrewTaskMgrAuthSvsPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
    name: '${name}-func-plan-CrewTaskMgrAuthSvcs'
    location: location
    sku: {
        name: 'Y1'
        tier: 'Dynamic'
        size: 'Y1'
        family: 'Y'
        capacity: 0
    }
    kind: 'functionapp'
    properties: {
        perSiteScaling: false
        elasticScaleEnabled: false
        maximumElasticWorkerCount: 1
        isSpot: false
        reserved: false
        isXenon: false
        hyperV: false
        targetWorkerCount: 0
        targetWorkerSizeId: 0
        zoneRedundant: false
    }
}

// https://learn.microsoft.com/en-us/azure/azure-functions/functions-infrastructure-as-code?tabs=bicep

resource funcCrewTaskMgrAuthSvcs 'Microsoft.Web/sites@2022-09-01' = {
    name: '${name}-func-CrewTaskMgrAuthSvcs'
    location: location
    kind: 'functionapp'
    identity: {
        type: 'SystemAssigned'
    }    
    properties: {        
        clientAffinityEnabled: false
        httpsOnly: true
        enabled: true
        hostNameSslStates: [

            {
                name: 'crewtaskmgrauthenticatedservices.azurewebsites.net'
                sslState: 'Disabled'
                hostType: 'Standard'
            }
            {
                name: 'crewtaskmgrauthenticatedservices.scm.azurewebsites.net'
                sslState: 'Disabled'
                hostType: 'Repository'
            }
        ]
        serverFarmId: funcCrewTaskMgrAuthSvsPlan.id
        reserved: false
        isXenon: false
        hyperV: false
        vnetRouteAllEnabled: false
        vnetImagePullEnabled: false
        vnetContentShareEnabled: false
        siteConfig: {
            windowsFxVersion: 'DOTNETCORE|6'
            numberOfWorkers: 1
            acrUseManagedIdentityCreds: false
            alwaysOn: false
            http20Enabled: false
            functionAppScaleLimit: 200
            minimumElasticInstanceCount: 0
        }
        scmSiteAlsoStopped: false
        clientCertEnabled: false
        clientCertMode: 'Required'
        hostNamesDisabled: false
        containerSize: 1536
        dailyMemoryTimeQuota: 0
        redundancyMode: 'None'
        storageAccountRequired: false
        keyVaultReferenceIdentity: 'SystemAssigned'
    }
}

resource siteName_web 'sourcecontrols@2020-12-01' = {
    name: 'web'
    properties: {
        repoUrl: repoURL
        branch: branch
        isManualIntegration: true
    }
}