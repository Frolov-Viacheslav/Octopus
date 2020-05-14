[CmdletBinding()]
param (
    [String] $webAppName = "viacheslav-frolov",
    [String] $ResourceGroupName = "SKILLUP-RG",
    [String] $KeyVaultName = "kv-viacheslav-frolov",
    [String] $KeyVaultSecretInstrumentationKey = "InstrumentationKey",
    [String] $KeyVaultSecretConnectionString = "ConnectionStringToApplicationInsight"
)

$WebAppName = $webAppName + "-webapp"
$KeyVaultSecretInstrumentationKeyId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretInstrumentationKey).Id
$KeyVaultSecretConnectionStringId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretConnectionString).Id

$INSTRUMENTATIONKEY = "@Microsoft.KeyVault(SecretUri=" + $KeyVaultSecretInstrumentationKeyId + ")"
$CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=" + $KeyVaultSecretConnectionStringId + ")"

$app = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
$newAppSettings = @{}
$app.SiteConfig.AppSettings | %{$newAppSettings[$_.Name] = $_.Value} # preserve non Application Insights application settings.
$newAppSettings["APPINSIGHTS_INSTRUMENTATIONKEY"] = $INSTRUMENTATIONKEY;
$newAppSettings["APPLICATIONINSIGHTS_CONNECTION_STRING"] = $CONNECTION_STRING;
$newAppSettings["ApplicationInsightsAgent_EXTENSION_VERSION"] = "~2";
Set-AzWebApp -AppSettings $newAppSettings -ResourceGroupName $ResourceGroupName -Name $WebAppName