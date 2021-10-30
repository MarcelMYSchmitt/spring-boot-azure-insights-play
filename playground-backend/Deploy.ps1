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
    $ProjectTag,

    [Parameter(Mandatory=$True)]
    [string]
    $BuildNumber
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


# naming of resources
$ResourceGroupName="$LocationTag-$EnvironmentTag-$ProjectTag-rg"
$AcrName=$LocationTag+$EnvironmentTag+$ProjectTag+"acr"
$WebAppPlanName=$LocationTag+$EnvironmentTag+$ProjectTag+"appplan"
$WebAppName=$LocationTag+$EnvironmentTag+$ProjectTag+"app"

Write-Host "Resource group name: $ResourceGroupName";
Write-Host "Container registry  name: $AcrName";
Write-Host "Web App plan name: $WebAppPlanName";
Write-Host "Web App name: $WebAppName";
Write-Host "Build Number: $BuildNumber";

$AcrFullName=$AcrName+".azurecr.io/applicationinsightsdemo"
Write-Host "Web App url: $AcrFullName";

# deploy new image version by creating/updating web app
Write-Host "Updating web app...: $WebAppName"; 
az webapp create --resource-group $ResourceGroupName --plan $WebAppPlanName --name $WebAppName --deployment-container-image-name $AcrFullName":"$BuildNumber

# restarting web app
Write-Host "Restarting web app...: $WebAppName";
az webapp restart --name $WebAppName --resource-group $ResourceGroupName