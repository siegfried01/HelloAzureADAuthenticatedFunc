/*
   Begin common prolog commands
   export name=AuthFuncSourceControl
   export rg=rg_${name}
   export loc=westus2
   End common prolog commands

   emacs F10
   Begin commands to deploy this file using Azure CLI with bash
   echo WaitForBuildComplete
   WaitForBuildComplete
   echo "Previous build is complete. Begin deployment build."
   echo az deployment group create --mode complete --template-file ./clear-resources.json --resource-group $rg
   az deployment group create --mode complete --template-file ./clear-resources.json --resource-group $rg
   echo az deployment group create --name $name --resource-group $rg   --mode  Incremental  --template-file  deploy-AuthFuncSourceControl.bicep --parameters  '@deploy.parameters.json' 
   az deployment group create --name $name --resource-group $rg   --mode  Incremental  --template-file  deploy-AuthFuncSourceControl.bicep  --parameters  '@deploy.parameters.json' 
   echo end deploy
   az resource list -g $rg --query "[?resourceGroup=='$rg'].{ name: name, flavor: kind, resourceType: type, region: location }" --output table
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
   az resource list -g $rg --query "[?resourceGroup=='$rg'].{ name: name, flavor: kind, resourceType: type, region: location }" --output table
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

   https://learn.microsoft.com/en-us/azure/azure-functions/functions-infrastructure-as-code?tabs=bicep

 */
param location string = resourceGroup().location
param name string = uniqueString(resourceGroup().id)
@description('The name of the web app that you wish to create.')
param siteName string = '${name}-web'

@description('The name of the App Service plan to use for hosting the web app.')
param hostingPlanName string = '${name}-plan'

@description('Rquire Azure AD authentication for Azure Func CrewTaskMgrAuthSvs')
param requireAuthentication bool = true

@description('Azure AD B2C App Registration client secret')
@secure()
param BackEndClientSecret string

param applicationId string
param funcCrewTaskMgrAuthSvcsName string = 'CrewTaskMgrAuthSvcs'

@description('The pricing tier for the hosting plan.')
@allowed([
    'F1'
    'D1'
    'B1'
    'B2'
    'B3'
    'S1'
])
param sku string = 'F1'

@description('The URL for the GitHub repository that contains the project to deploy.')
param repoURL string = 'https://github.com/siegfried01/HelloAzureADAuthenticatedFunc.git'
//                     'https://github.com/siegfried01/HelloAzureADAuthenticatedFunc'

@description('The branch of the GitHub repository to use.')
param branch string = 'master'

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

param storageAccountName string = '${name}stgctmfunc'
resource stgCrewTaskMgrAuthFunc 'Microsoft.Storage/storageAccounts@2022-05-01' = {
    name: storageAccountName
    location: location
    sku: {
        name: 'Standard_LRS'
    }
    kind: 'StorageV2'

    properties: {
        supportsHttpsTrafficOnly: true
        defaultToOAuthAuthentication: true
    }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' existing = {
    name: 'default'
    parent: stgCrewTaskMgrAuthFunc
}

param myLogAnalyticsId string =  '/subscriptions/acc26051-92a5-4ed1-a226-64a187bc27db/resourcegroups/defaultresourcegroup-wus2/providers/microsoft.operationalinsights/workspaces/defaultworkspace-acc26051-92a5-4ed1-a226-64a187bc27db-wus2'
//resource myLogAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
//    name: '${name}-LogAnalytics'
    
    //Id: '/subscriptions/acc26051-92a5-4ed1-a226-64a187bc27db/resourcegroups/defaultresourcegroup-wus2/providers/microsoft.operationalinsights/workspaces/defaultworkspace-acc26051-92a5-4ed1-a226-64a187bc27db-wus2'
//}
resource storageDataPlaneLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
    name: '${storageAccountName}-logs'
    scope: blobService
    properties: {
        workspaceId: myLogAnalyticsId //myLogAnalytics.id
        logs: [
            {
                category: 'StorageWrite'
                enabled: true
            }
        ]
        metrics: [
            {
                category: 'Transaction'
                enabled: true
            }
        ]
    }
}
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
    name: '${name}-appins'
    location: location
    kind: 'web'
    properties: {
        Application_Type: 'web'
        Request_Source: 'IbizaWebAppExtensionCreate'
    }
}

var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${stgCrewTaskMgrAuthFunc.listKeys().keys[0].value}'

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
    resource authsettigns 'config@2022-09-01' = {
        name: 'authsettingsV2'
        properties: {
            platform: {
                enabled: requireAuthentication
                runtimeVersion: '~1'
            }
            globalValidation: {
                requireAuthentication: requireAuthentication
                unauthenticatedClientAction: 'RedirectToLoginPage'
                redirectToProvider: 'azureactivedirectory'
            }
            identityProviders: {
                azureActiveDirectory: requireAuthentication ? {
                    enabled: requireAuthentication
                    registration: {
                        openIdIssuer: 'https://enterprisedemoorg.b2clogin.com/enterprisedemoorg.onmicrosoft.com/v2.0/.well-known/openid-configuration?p=B2C_1_Frontend_APIM_Totorial_SUSI' // 'https://sts.windows.net/${subscription().tenantId}/v2.0'
                        clientId: applicationId
                        clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
                    }
                    login: {
                        disableWWWAuthenticate: false
                    }
                    validation: {
                        jwtClaimChecks: {}
                        allowedAudiences: [
                            'api://${applicationId}'
                        ]
                        defaultAuthorizationPolicy: {
                            allowedPrincipals: {}
                        }
                    }
                } : null
            }
            login: {
                routes: {}
                tokenStore: {
                    enabled: true
                    tokenRefreshExtensionHours: json('72.0')
                    fileSystem: {}
                    azureBlobStorage: {}
                }
                preserveUrlFragmentsForLogins: false
                cookieExpiration: {
                    convention: 'FixedTime'
                    timeToExpiration: '08:00:00'
                }
                nonce: {
                    validateNonce: true
                    nonceExpirationInterval: '00:05:00'
                }
            }
            httpSettings: {
                requireHttps: true
                routes: {
                    apiPrefix: '/.auth'
                }
                forwardProxy: {
                    convention: 'NoProxy'
                }
            }
        }
    }
    resource appSettings 'config@2021-02-01' = {
        name: 'appsettings'
        properties: {
            // 'APPINSIGHTS_INSTRUMENTATIONKEY': instrumentationKey
            // 'ApplicationInsights:InstrumentationKey': instrumentationKey
            //'APPLICATIONINSIGHTS_CONNECTION_STRING': ApplicationInsights_ConnectionString
            'APPINSIGHTS_INSTRUMENTATIONKEY': applicationInsights.properties.InstrumentationKey
            'FUNCTIONS_WORKER_RUNTIME': 'dotnet'
            'Logging:ApplicationInsights:Enabled': 'true'
            'Logging:ApplicationInsights:LogLevel': 'Trace'
            'Logging:LogLevel:Default': 'Trace'
            'Logging.LogLevel:Microsoft': 'Trace'
            'ASPNETCORE_ENVIRONMENT': 'Development'
            'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET': '${BackEndClientSecret}'
            'AzureWebJobsStorage': blobStorageConnectionString
        }
    }
    resource sites_CrewTaskMgrAuthenticatedSvcs_name_Hello 'functions@2022-09-01' = {
        name: 'Hello'
        properties: {
            script_root_path_href: 'https://${funcCrewTaskMgrAuthSvcsName}.azurewebsites.net/admin/vfs/site/wwwroot/Hello/'
            script_href: 'https://${funcCrewTaskMgrAuthSvcsName}.azurewebsites.net/admin/vfs/site/wwwroot/bin/CrewTaskMgrAuthenticatedServices.dll'
            config_href: 'https://${funcCrewTaskMgrAuthSvcsName}.azurewebsites.net/admin/vfs/site/wwwroot/Hello/function.json'
            test_data_href: 'https://${funcCrewTaskMgrAuthSvcsName}.azurewebsites.net/admin/vfs/data/Functions/sampledata/Hello.dat'
            href: 'https://${funcCrewTaskMgrAuthSvcsName}.azurewebsites.net/admin/functions/Hello'
            config: {}
            invoke_url_template: 'https://${funcCrewTaskMgrAuthSvcsName}.azurewebsites.net/api/hello'
            language: 'DotNetAssembly'
            isDisabled: false
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
}
