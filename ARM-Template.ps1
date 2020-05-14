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
$Parameters["appSettings"] = $appSettings | ConvertFrom-Json
$Parameters["connectionStrings"] = $connectionStrings | ConvertFrom-Json

New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterObject $Parameters

$ApplicationInsightName = "AppInsight-" + $webAppName
$ApplicationInsight = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightName
$InstrumentationKey = ConvertTo-SecureString -String $ApplicationInsight.InstrumentationKey -AsPlainText -Force
$ConnectionString = ConvertTo-SecureString -String ("InstrumentationKey=" + $ApplicationInsight.InstrumentationKey) -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretInstrumentationKey -SecretValue $InstrumentationKey
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretConnectionString -SecretValue $ConnectionString

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
    Remove-AzRoleAssignment -ObjectId $Unknown.ObjectId -RoleDefinitionName $Unknown.RoleDefinitionName -Scope $KeyVaultID
}

#Remove Access Policy
$AccessPolicies = (Get-AzKeyVault -Name $KeyVaultName).AccessPolicies
$ObjectId = ($AccessPolicies | Where-Object{$_.DisplayName -eq ""}).ObjectId
if($ObjectId){
    Remove-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $ObjectId
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