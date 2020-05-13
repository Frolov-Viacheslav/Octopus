[CmdletBinding()]
param (
    [String] $webAppName = "viacheslav-frolov",
    [String] $sku = "S1",
    [String] $location = "West US",
    [String] $ResourceGroupName = "SKILLUP-RG"
)

$Parameters = @{}
$Parameters["webAppName"] = $webAppName
$Parameters["sku"] = $sku
$Parameters["location"] = $location


New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile ".\ARM-Template.json" -TemplateParameterObject $Parameters

$ApplicationInsightName = "AppInsight-" + $webAppName
$ApplicationInsight = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightName
$InstrumentationKey = ConvertTo-SecureString -String $ApplicationInsight.InstrumentationKey -AsPlainText -Force
$ConnectionString = ConvertTo-SecureString -String ("InstrumentationKey=" + $ApplicationInsight.InstrumentationKey) -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName 'kv-viacheslav-frolov' -Name 'InstrumentationKey' -SecretValue $InstrumentationKey
Set-AzKeyVaultSecret -VaultName 'kv-viacheslav-frolov' -Name 'ConnectionStringToApplicationInsight' -SecretValue $ConnectionString

$WebAppName = $webAppName + "-webapp"
New-OctopusAzureWebAppTarget -name "Azure Web Application" `
                             -azureWebApp $WebAppName `
                             -azureResourceGroupName $ResourceGroupName  `
                             -octopusAccountIdOrName "Azure" `
                             -octopusRoles "web" `
                             -updateIfExisting