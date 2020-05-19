<#
    .SYNOPSIS
        Deploy Web Infrastructure
    .DESCRIPTION
        The Deploy-WebInfrastructure script deploys ARM template. 
        Creates Octopus deployment target for new Web App.
        Also manages Role Assignment and Access Policy for access to Key Vault.
    .PARAMETER webAppName
        Specifies the name of Web App.  
    .PARAMETER sku
        Specifies the sku of Web App.  
    .PARAMETER location
        Specifies the location of Azure resources.
    .PARAMETER ResourceGroupName
        Specifies the resource group name of Azure resources.
    .PARAMETER KeyVaultName
        Specifies the name of Key Vault.
    .PARAMETER TemplateFile
        Specifies the path to ARM Template.
    .PARAMETER KeyVaultSecretInstrumentationKey
        Specifies the Key Vault Secret which contains Instrumentation Key.
    .PARAMETER KeyVaultSecretConnectionString
        Specifies the Key Vault Secret which contains Connection String.
    .PARAMETER octopusAccountIdOrName
        Specifies the Account of Octopus.
    .PARAMETER octopusRoles
        Specifies the Role of Octopus.
    .PARAMETER appSettings
        Specifies the Application settings of Web App. 
    .PARAMETER connectionStrings
        Specifies the Connection String of Web App.
    .EXAMPLE
        PS> Deploy-WebInfrastructure -webAppName "#{webAppName}" `
                                     -sku "#{sku}" `
                                     -location "#{location}" `
                                     -ResourceGroupName "#{ResourceGroupName}" `
                                     -KeyVaultName "#{KeyVaultName}" `
                                     -TemplateFile "#{TemplateFile}" `
                                     -KeyVaultSecretInstrumentationKey "#{KeyVaultSecretInstrumentationKey}" `
                                     -KeyVaultSecretConnectionString "#{KeyVaultSecretConnectionString}" `
                                     -octopusAccountIdOrName "#{octopusAccountIdOrName}" `
                                     -octopusRoles "#{octopusRoles}" `
                                     -appSettings "#{appSettings}" `
                                     -connectionStrings "#{connectionStrings}"
    .LINK
        http://104.42.19.68/
    .NOTES
        Author: Viacheslav Frolov
        Telegram: @Viacheslav_Frolov
        GitHub: https://github.com/Frolov-Viacheslav/Octopus
#>

[CmdletBinding()]
param (
    [String] $webAppName = "viacheslav-frolov",
    [String] $sku = "S1",
    [String] $location = "West US",
    [String] $ResourceGroupName = "SKILLUP-RG",
    [String] $KeyVaultName = "kv-viacheslav-frolov",
    [String] $TemplateFile = ".\ARM-Template.json",
    [String] $KeyVaultSecretInstrumentationKey = "InstrumentationKey",
    [String] $KeyVaultSecretConnectionString = "ConnectionStringToApplicationInsight",
    [String] $octopusAccountIdOrName = "Azure",
    [String] $octopusRoles = "web",
    [String] $appSettings = '[]',
    [String] $connectionStrings = '[]'

)

$Parameters = @{}
$Parameters["webAppName"] = $webAppName
$Parameters["sku"] = $sku
$Parameters["location"] = $location
$Parameters["appSettings"] = $appSettings
$Parameters["connectionStrings"] = $connectionStrings

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $Parameters

#Save AppInsight Instrumentation Key and Connection String to Key Vault
$ApplicationInsightName = "AppInsight-" + $webAppName
$ApplicationInsight = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightName
$InstrumentationKey = ConvertTo-SecureString -String $ApplicationInsight.InstrumentationKey -AsPlainText -Force
$ConnectionString = ConvertTo-SecureString -String ("InstrumentationKey=" + $ApplicationInsight.InstrumentationKey) -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretInstrumentationKey -SecretValue $InstrumentationKey
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretConnectionString -SecretValue $ConnectionString

#Create Octopus deployment target
$WebAppName = $webAppName + "-webapp"
New-OctopusAzureWebAppTarget -name "Azure Web Application" `
                             -azureWebApp $WebAppName `
                             -azureResourceGroupName $ResourceGroupName  `
                             -octopusAccountIdOrName  $octopusAccountIdOrName `
                             -octopusRoles $octopusRoles `
                             -updateIfExisting

#Remove Role Assignment
$KeyVaultID = (Get-AzKeyVault -Name $KeyVaultName).ResourceId
$RoleAssignment = Get-AzRoleAssignment -Scope $KeyVaultID
$Unknown = $RoleAssignment | Where-Object{$_.ObjectType -eq "Unknown"}
if($Unknown){
    $Unknown | ForEach-Object {Remove-AzRoleAssignment -ObjectId $_.ObjectId -RoleDefinitionName $_.RoleDefinitionName -Scope $KeyVaultID}
}

#Remove Access Policy
$AccessPolicies = (Get-AzKeyVault -Name $KeyVaultName).AccessPolicies
$ObjectId = ($AccessPolicies | Where-Object{$_.DisplayName -eq ""}).ObjectId
if($ObjectId){
    $ObjectId | ForEach-Object {Remove-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $_}
}

#New Role Assignment
$WebAppId = (Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName).Identity.PrincipalId
$WebAppRole = $RoleAssignment | Where-Object{$_.ObjectId -eq $WebAppId}
if(!$WebAppRole){
    New-AzRoleAssignment -ObjectId $WebAppId -RoleDefinitionName "Reader" -Scope $KeyVaultID
}

#New Access Policy
$WebAppAccessPolicy = $AccessPolicies | Where-Object{$_.ObjectId -eq $WebAppId}
if(!$WebAppAccessPolicy){
    Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $WebAppId -PermissionsToSecrets Get
}

#Restart Web App
Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName