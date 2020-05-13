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