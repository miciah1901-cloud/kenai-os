#Requires -RunAsAdministrator
# Removes Kenai Switch from Windows. Doesn't touch Kenai OS or any boot entries.
$ErrorActionPreference = 'Continue'
Unregister-ScheduledTask -TaskName 'Kenai Switch' -Confirm:$false
Remove-Item (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Kenai Switch.lnk') -Force
Remove-Item (Join-Path $env:ProgramFiles 'KenaiSwitch') -Recurse -Force
Write-Host 'Kenai Switch removed. Remove it from your Steam library by hand if you added it.'
