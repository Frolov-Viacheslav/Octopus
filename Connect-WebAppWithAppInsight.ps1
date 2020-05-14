<#
    .SYNOPSIS
        Connect WebApp with AppInsight
    .DESCRIPTION
        The Connect-WebAppWithAppInsight script set app settings for connection with AppInsight. 
        Get Key Vault secrets ids and create references on Key Vault.
    .PARAMETER webAppName
        Specifies the name of Web App.  
    .PARAMETER ResourceGroupName
        Specifies the resource group name of Azure resources.
    .PARAMETER KeyVaultName
        Specifies the name of Key Vault.
    .PARAMETER KeyVaultSecretInstrumentationKey
        Specifies the Key Vault Secret which contains Instrumentation Key.
    .PARAMETER KeyVaultSecretConnectionString
        Specifies the Key Vault Secret which contains Connection String.
    .EXAMPLE
        PS> Connect-WebAppWithAppInsight -webAppName "#{webAppName}" `
                                         -ResourceGroupName "#{ResourceGroupName}" `
                                         -KeyVaultName "#{KeyVaultName}" `
                                         -KeyVaultSecretInstrumentationKey "#{KeyVaultSecretInstrumentationKey}" `
                                         -KeyVaultSecretConnectionString "#{KeyVaultSecretConnectionString}"
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
    [String] $ResourceGroupName = "SKILLUP-RG",
    [String] $KeyVaultName = "kv-viacheslav-frolov",
    [String] $KeyVaultSecretInstrumentationKey = "InstrumentationKey",
    [String] $KeyVaultSecretConnectionString = "ConnectionStringToApplicationInsight"
)

#Get Key Vault secrets ids
$WebAppName = $webAppName + "-webapp"
$KeyVaultSecretInstrumentationKeyId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretInstrumentationKey).Id
$KeyVaultSecretConnectionStringId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretConnectionString).Id

#Create references on Key Vault
$INSTRUMENTATIONKEY = "@Microsoft.KeyVault(SecretUri=" + $KeyVaultSecretInstrumentationKeyId + ")"
$CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=" + $KeyVaultSecretConnectionStringId + ")"

#Set App settings for connection with AppInsight
$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
$newAppSettings = @{}
$app.SiteConfig.AppSettings | %{$newAppSettings[$_.Name] = $_.Value} # preserve non Application Insights application settings.
$newAppSettings["APPINSIGHTS_INSTRUMENTATIONKEY"] = $INSTRUMENTATIONKEY;
$newAppSettings["APPLICATIONINSIGHTS_CONNECTION_STRING"] = $CONNECTION_STRING;
$newAppSettings["ApplicationInsightsAgent_EXTENSION_VERSION"] = "~2";
Set-AzWebApp -AppSettings $newAppSettings -ResourceGroupName $ResourceGroupName -Name $WebAppName