$WebAppName = $OctopusParameters["webAppName"] + "-webapp"

$INSTRUMENTATIONKEY = "@Microsoft.KeyVault(SecretUri=" + (Get-AzKeyVaultSecret -VaultName 'kv-viacheslav-frolov' -Name 'InstrumentationKey').Id + ")"
$CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=" + (Get-AzKeyVaultSecret -VaultName 'kv-viacheslav-frolov' -Name 'ConnectionStringToApplicationInsight').Id + ")"
$app = Get-AzWebApp -ResourceGroupName "SKILLUP-RG" -Name $WebAppName -ErrorAction Stop
$newAppSettings = @{}
$app.SiteConfig.AppSettings | %{$newAppSettings[$_.Name] = $_.Value} # preserve non Application Insights application settings.
$newAppSettings["APPINSIGHTS_INSTRUMENTATIONKEY"] = $INSTRUMENTATIONKEY;
$newAppSettings["APPLICATIONINSIGHTS_CONNECTION_STRING"] = $CONNECTION_STRING;
$newAppSettings["ApplicationInsightsAgent_EXTENSION_VERSION"] = "~2";
$app = Set-AzWebApp -AppSettings $newAppSettings -ResourceGroupName $app.ResourceGroup -Name $app.Name -ErrorAction Stop