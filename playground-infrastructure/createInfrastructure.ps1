#Requires -Version 3.0

Param(
    [Parameter(Mandatory=$True)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory=$True)]
    [string]
    $TenantId,

    [Parameter(Mandatory=$True)]
    [string]
    $ServicePrincipalId,

    [Parameter(Mandatory=$True)]
    [string]
    $ServicePrincipalPassword,

    [Parameter(Mandatory=$True)]
    [string]
    $LocationTag,

    [Parameter(Mandatory=$True)]
    [string]
    $EnvironmentTag,

    [Parameter(Mandatory=$True)]
    [string]
    $ProjectTag
)

#stop the script on first error
$ErrorActionPreference = 'Stop'

# login into azure using service principal
Write-Host "Selecting ServicePrincipalId: $ServicePrincipalId";
az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalPassword --tenant $TenantId

Write-Host "Selecting Subscription: $SubscriptionId";
Write-Host "Selecting LocationTag: $LocationTag";
Write-Host "Selecting EnvironmentTag: $EnvironmentTag";
Write-Host "Selecting ProjectTag: $ProjectTag";


# at the moment we only allow 'ne' and 'we' as locations
if ($LocationTag -eq "we") {
    $ResourceGroupLocation = "westeurope"
    $LocationTag = "we"
} 
elseif ($LocationTag -eq "ne"){
    $LocationTag = "ne"
    $ResourceGroupLocation = "northeurope"
} else {
    Write-Host "Only 'we' and 'ne' are supported for location tags, default value is 'we'!"
    $ResourceGroupLocation = "West Europe"
    $LocationTag = "we"

}


# naming of resources
$ResourceGroupName="$LocationTag-$EnvironmentTag-$ProjectTag-rg"
$KeyVaultName="$LocationTag-$EnvironmentTag-$ProjectTag-vt"
$AcrName=$LocationTag+$EnvironmentTag+$ProjectTag+"acr"
$AppInsightsName="$LocationTag-$EnvironmentTag-$ProjectTag-insights"
$WebAppPlanName=$LocationTag+$EnvironmentTag+$ProjectTag+"appplan"
$WebAppName=$LocationTag+$EnvironmentTag+$ProjectTag+"app"

Write-Host "Resource group name: $ResourceGroupName";
Write-Host "KeyVault  name: $KeyVaultName";
Write-Host "Container registry  name: $AcrName";
Write-Host "Application Insights  name: $AppInsightsName";
Write-Host "Web App plan name: $WebAppPlanName";
Write-Host "Web App name: $WebAppName";

# create resource group and service principal
Write-Host "Creating/Updating resource group...: $ResourceGroupName";
az group create --location $ResourceGroupLocation --name $ResourceGroupName --subscription $SubscriptionId --tags "project=$ProjectTag"

# create keyvault
Write-Host "Creating/Updating key vault...: $KeyVaultName";
az keyvault create --name $KeyVaultName --resource-group $ResourceGroupName --location $ResourceGroupLocation --subscription $SubscriptionId --tags "project=$ProjectTag"

# add service principal permission for keyvault secrets
az keyvault set-policy --name $KeyVaultName --spn http://AccessAllResourcesPrincipal --secret-permissions get list purge set

# add dummy secret to keyvault
Write-Host "Setting secret in key vault...: MySecretSecretName";
az keyvault secret set --name MySecretSecretName --vault-name $KeyVaultName --value MySecretSecretValue --subscription $SubscriptionId

# create container registry and enable admin mode
Write-Host "Creating/Updating container registry...: $AcrName";
az acr create --name $AcrName --resource-group $ResourceGroupName --sku Standard --location $ResourceGroupLocation --subscription $SubscriptionId --tags "project=$ProjectTag"
az acr update --name $AcrName --admin-enabled 'true'

# add container registry password to keyvault
Write-Host "Setting secret in key vault...: AcrLoginCredentials";
$AcrLoginCredentials=az acr credential show --name $AcrName --query passwords[0].value --resource-group $ResourceGroupName --subscription $SubscriptionId
az keyvault secret set --name AcrLoginCredentials --vault-name $KeyVaultName --value $AcrLoginCredentials --subscription $SubscriptionId

# create application insights
# maybe you have to check if application-insights extension is installed in Powershell or enable it in Azure CLI
# Install extension in Powershell: az extension add --name application-insights
# Enable it in Azur CLI: az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.use_dynamic_install=yes_without_prompt
Write-Host "Creating/Updating container registry...: $AppInsightsName";
az monitor app-insights component create --app $AppInsightsName --location $ResourceGroupLocation --kind web --resource-group $ResourceGroupName --application-type web --tags "project=$ProjectTag"

# get app insights instrumentation key by az cli and add it to keyvault
Write-Host "Setting secret in key vault...: AppInsightsKey";
$AppInsightsKey=az resource show --resource-group $ResourceGroupName --name $AppInsightsName --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey
az keyvault secret set --name AppInsightsKey --vault-name $KeyVaultName --value $AppInsightsKey --subscription $SubscriptionId

# create service plan and webapp with nginx as example/base image
Write-Host "Creating/Updating app service plan...: $WebAppPlanName";
az appservice plan create --resource-group $ResourceGroupName --name $WebAppPlanName --is-linux --number-of-workers 1 --sku S1
Write-Host "Creating/Updating web app...: $WebAppName";
az webapp create --resource-group $ResourceGroupName --plan $WebAppPlanName --name $WebAppName -i nginx --subscription $SubscriptionId --tags "project=$ProjectTag"

# set environment variables in webapp by getting all stuff from keyvault
Write-Host "Setting configs for Web App...";
$AppInsightsKeyFromVault=az keyvault secret show --name AppInsightsKey --vault-name $KeyVaultName --query "value"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_APPLICATIONINSIGHTS_INSTRUMENTATIONKEY=$AppInsightsKeyFromVault"

az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_KEYVAULT_CLIENTID=$ServicePrincipalId"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_KEYVAULT_CLIENTKEY=$ServicePrincipalPassword"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_KEYVAULT_TENANTID=f38a3a5a-f715-4a37-a8b4-b8ed47a3c08b"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_KEYVAULT_URI=https://$KeyVaultName.vault.azure.net/"

az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_APPLICATIONINSIGHTS_HEARTBEAT_HEARTBEATINTERVAL=60"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_APPLICATIONINSIGHTS_HEARTBEAT_ENABLED=true"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "AZURE_APPLICATIONINSIGHTS_QUICKPULSE_ENABLED=true"

# set registry username, password, url for accessing registry from azure web app
az webapp config container set --docker-registry-server-password $AcrLoginCredentials --docker-registry-server-url "https://$AcrName.azurecr.io" --docker-registry-server-user $AcrName --name $WebAppName --resource-group $ResourceGroupName

# set custom Tomcat Port for Spring Boot 
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "WEBSITES_PORT=8080"


$ServiceBusNamespaceName=$LocationTag+$EnvironmentTag+$ProjectTag+"ns"
$ServiceBusTopicName=$LocationTag+$EnvironmentTag+$ProjectTag+"tp"
$ServiceBusSubscriptionName=$LocationTag+$EnvironmentTag+$ProjectTag+"sn"

Write-Host "Service Bus Namespace name: $ServiceBusNamespaceName";
Write-Host "Service Bus Topic name: $ServiceBusTopicName";
Write-Host "Service Bus Subscription name: $ServiceBusSubscriptionName";

# create service bus namespace, topic and subscription for sending and receiving messages
Write-Host "Creating/Updating service bus ...: $ServiceBusNamespaceName";
az servicebus namespace create --resource-group $ResourceGroupName  --name $ServiceBusNamespaceName --location $ResourceGroupLocation --sku standard --subscription $SubscriptionId --tags "project=$ProjectTag"
az servicebus topic create --resource-group $ResourceGroupName --namespace-name $ServiceBusNamespaceName --name $ServiceBusTopicName
az servicebus topic subscription create --resource-group $ResourceGroupName --namespace-name $ServiceBusNamespaceName --topic-name $ServiceBusTopicName --name $ServiceBusSubscriptionName

# add service bus connection secret to key vault
Write-Host "Setting secret in key vault...: ServiceBusNamespaceConnectionString";
$ServiceBusNamespaceConnectionString=az servicebus namespace authorization-rule keys list --resource-group $ResourceGroupName --namespace-name $ServiceBusNamespaceName --name RootManageSharedAccessKey --query primaryConnectionString -o tsv
az keyvault secret set --name ServiceBusNamespaceConnectionString --vault-name $KeyVaultName --value $ServiceBusNamespaceConnectionString --subscription $SubscriptionId


# add service bus configuration to web app 
Write-Host "Setting configs for Web App...";
az webapp config connection-string set --resource-group $ResourceGroupName  --name $WebAppName --connection-string-type servicebus --settings "SPRING_JMS_SERVICEBUS_CONNECTIONSTRING=$ServiceBusNamespaceConnectionString"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "SPRING_JMS_SERVICEBUS_TOPICCLIENTID=$ServicePrincipalId"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "SERVICEBUSTOPICNAME=$ServiceBusTopicName"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "SERVICEBUSSUBSCRIPTIONNAME=$ServiceBusSubscriptionName"
az webapp config appsettings set --resource-group $ResourceGroupName --name $WebAppName --settings "SERVICEBUSDESTINATIONNAME=$ServiceBusTopicName"