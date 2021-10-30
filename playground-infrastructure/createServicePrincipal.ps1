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

# select tenant 
Write-Host "Selecting tenant: $TenantId";
Connect-AzureRmAccount -TenantId $TenantId

# select subscription 
Write-Host "Selecting subscription: $SubscriptionId";
Select-AzureRmSubscription -SubscriptionID $SubscriptionId;

# create a contributor role assignment with scope of subscription 
$SP_PASSWORD=$(az ad sp create-for-rbac --name AccessAllResourcesPrincipal --role contributor --scopes /subscriptions/$SubscriptionId --query password --output tsv)
Write-Host "Service Principal Password: $SP_PASSWORD";

# Get the service principle client id.
$CLIENT_ID=$(az ad sp show --id http://AccessAllResourcesPrincipal --query appId --output tsv)
Write-Host "Service Principal ID: $CLIENT_ID";