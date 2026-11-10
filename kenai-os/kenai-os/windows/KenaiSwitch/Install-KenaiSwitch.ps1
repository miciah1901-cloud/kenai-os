#Requires -RunAsAdministrator
# Kenai Switch installer (Windows). Run through Install.cmd.
#  1. Finds Kenai OS in the firmware boot list
#  2. Installs Kenai Switch to C:\Program Files\KenaiSwitch
#  3. Creates the "Kenai Switch" task that does the restart (so no admin prompt later)
#  4. Adds a Start menu shortcut you can add to Steam Big Picture

$ErrorActionPreference = 'Stop'
$src      = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest     = Join-Path $env:ProgramFiles 'KenaiSwitch'
$TaskName = 'Kenai Switch'

Write-Host ''
Write-Host '  KENAI SWITCH  -  installer' -ForegroundColor Red
Write-Host ''

# --- 1. Find the Kenai OS boot entry -------------------------------------------
$raw = (& bcdedit.exe /enum firmware) | Out-String
if ($LASTEXITCODE -ne 0) { throw "bcdedit couldn't read the firmware boot list." }

$entries = foreach ($block in ($raw -split '\r?\n\s*\r?\n')) {
    $id   = [regex]::Match($block, '(?m)^identifier\s+(\{[0-9a-fA-F-]{36}\})').Groups[1].Value
    $desc = [regex]::Match($block, '(?m)^description\s+(.+?)\s*$').Groups[1].Value
    if ($id -and $desc) { [pscustomobject]@{ Id = $id; Description = $desc } }
}

$kenai = $entries | Where-Object { $_.Description -match 'Kenai|Bazzite|Fedora' } | Select-Object -First 1

if (-not $kenai) {
    Write-Host "Couldn't find Kenai OS automatically. Boot entries on this PC:" -ForegroundColor Yellow
    $i = 0
    foreach ($e in $entries) { $i++; Write-Host ("  [{0}] {1}" -f $i, $e.Description) }
    $list = @($entries)
    if ($list.Count -eq 0) { throw 'No firmware boot entries found. Is Kenai OS installed?' }
    $pick = Read-Host 'Type the number of the Kenai OS entry (or press Enter to cancel)'
    if (-not $pick) { Write-Host 'Cancelled.'; return }
    $n = 0
    if (-not [int]::TryParse($pick, [ref]$n) -or $n -lt 1 -or $n -gt $list.Count) {
        throw "Pick a number from 1 to $($list.Count)."
    }
    $kenai = $list[$n - 1]
}
Write-Host ("Kenai OS boot entry: {0}  {1}" -f $kenai.Description, $kenai.Id) -ForegroundColor Green

# --- 2. Install files ------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $dest, (Join-Path $dest 'assets') | Out-Null
Copy-Item (Join-Path $src 'KenaiSwitch.ps1'), (Join-Path $src 'Reboot-ToKenai.ps1'), (Join-Path $src 'Uninstall-KenaiSwitch.ps1') $dest -Force
Copy-Item (Join-Path $src 'assets\*') (Join-Path $dest 'assets') -Force -Recurse
@{ EntryId = $kenai.Id; Description = $kenai.Description } | ConvertTo-Json | Set-Content (Join-Path $dest 'config.json') -Encoding UTF8

# --- 3. Restart task (runs as SYSTEM, startable by normal users) --------------------
$action    = New-ScheduledTaskAction -Execute 'powershell.exe' `
             -Argument ("-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"{0}`"" -f (Join-Path $dest 'Reboot-ToKenai.ps1'))
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
Register-ScheduledTask -TaskName $TaskName -Action $action -Principal $principal -Settings $settings `
    -Description 'Restarts into Kenai OS for the next boot only. Started by Kenai Switch.' -Force | Out-Null

$svc  = New-Object -ComObject Schedule.Service
$svc.Connect()
$task = $svc.GetFolder('\').GetTask($TaskName)
$sd   = $task.GetSecurityDescriptor(4)            # DACL only
if ($sd -notmatch '\(A;;GRGX;;;AU\)') {
    $task.SetSecurityDescriptor($sd + '(A;;GRGX;;;AU)', 0)   # signed-in users may start it
}

# --- 4. Start menu shortcut ----------------------------------------------------------
$lnk = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Kenai Switch.lnk'
$ws  = New-Object -ComObject WScript.Shell
$sc  = $ws.CreateShortcut($lnk)
$sc.TargetPath       = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$sc.Arguments        = ("-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"{0}`"" -f (Join-Path $dest 'KenaiSwitch.ps1'))
$sc.IconLocation     = Join-Path $dest 'assets\kenai-switch.ico'
$sc.WorkingDirectory = $dest
$sc.Description      = 'Restart into Kenai OS'
$sc.Save()

Write-Host ''
Write-Host 'Installed.' -ForegroundColor Green
Write-Host '  Start menu:  Kenai Switch'
Write-Host ''
Write-Host 'Add it to Steam Big Picture (one time):'
Write-Host '  Steam > Games > Add a Non-Steam Game to My Library > Browse >'
Write-Host "  $lnk"
Write-Host '  Then right-click it > Properties > Customize to use the artwork in:'
Write-Host "  $(Join-Path $dest 'assets')"
Write-Host ''
