# Introduction

Introduction of Azure Devops / Azure Portal / some basic resources and how everything works together.  

In this repository we will setup following infrastructure:
- Resource Group
- Key Vault
- Container Registry
- Application Insights
- Service Plan (Linux)
- Service App (Docker)

We will deploy a spring boot backend in Service App by using Azure DevOps pipelines (build and release).
We will not use the App Service integrations. Instead of the integrations we will use custom powershell scripts where we have a Service Principal for logging in into Azure. The Service Principal was created by a custom `createServicePrincipal.ps1` script which you can also find in this repository. This Service Principal was added as contributor to the subscription. 

<br/> 

## Tenant Id, Subscription Id and Service Principal Information and other variables

<br/> 

We are using several predefined and custom variables for setting everything up. 

List of variables:
- SubscriptionId
- TenantId
- EnvironmentTag
- LocationTag
- ProjectTag
- ServicePrincipalId
- ServicePrincipalPassword
- BuildNumber

<br/> 

## Scripts

<br /> 

<b>createServicePrincipal.ps1 </b>  
Setup of the Service Principal for setting infrastructure up. 

<b>createInfrastructure.ps1</b>  
Setup of whole infrastructure.

<b>azure-pipelines-build.yml</b>  
Build Pipeline for backend.

<b>azure-pipelines-infrastructure.yml</b>  
Build pipeline for infrastructure. 

<b>backend-release.json</b>  
Release pipeline for backend. 

<br/> 


# Articles

Some basic documentation about the setup.

<b>Integrate Azure Application Insights in Spring Boot:</b> 
https://github.com/lenisha/spring-demo-monitor

<b>Spring Boot Environment Variables in Azure Web App:</b> 
https://docs.microsoft.com/de-de/azure/developer/java/migration/migrate-spring-boot-to-app-service


<b>Azure Container Registry and Azure Web App: </b> 
https://docs.microsoft.com/en-us/cli/azure/webapp/config/container?view=azure-cli-latest#az_webapp_config_container_set

<br/> 

<b>Spring Boot App on Web App: </b>  
https://docs.microsoft.com/de-de/azure/developer/java/spring-framework/deploy-spring-boot-java-app-on-linux

<br />

<b>Application Insights Configuration for Spring Boot: </b>  
https://docs.microsoft.com/de-de/azure/azure-monitor/app/java-standalone-config
