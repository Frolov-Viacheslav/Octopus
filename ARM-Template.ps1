$ApplicationInsightName = "AppInsight-" + $OctopusParameters["webAppName"]
$ApplicationInsight = Get-AzApplicationInsights -ResourceGroupName "SKILLUP-RG" -Name $ApplicationInsightName
$InstrumentationKey = ConvertTo-SecureString -String $ApplicationInsight.InstrumentationKey -AsPlainText -Force
$ConnectionString = ConvertTo-SecureString -String ("InstrumentationKey=" + $ApplicationInsight.InstrumentationKey) -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName 'kv-viacheslav-frolov' -Name 'InstrumentationKey' -SecretValue $InstrumentationKey
Set-AzKeyVaultSecret -VaultName 'kv-viacheslav-frolov' -Name 'ConnectionStringToApplicationInsight' -SecretValue $ConnectionString

$WebAppName = $OctopusParameters["webAppName"] + "-webapp"
New-OctopusAzureWebAppTarget -name "Azure Web Application" `
                             -azureWebApp $WebAppName `
                             -azureResourceGroupName "SKILLUP-RG"  `
                             -octopusAccountIdOrName "Azure" `
                             -octopusRoles "web" `
                             -updateIfExisting