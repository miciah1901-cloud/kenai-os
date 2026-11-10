# Run by the "Kenai Switch" scheduled task (as SYSTEM).
# Sets Kenai OS as the firmware's next boot (one time only), then restarts.
$ErrorActionPreference = 'Stop'
$log = Join-Path $PSScriptRoot 'last-run.log'
try {
    $cfg = Get-Content (Join-Path $PSScriptRoot 'config.json') -Raw | ConvertFrom-Json
    if ($cfg.EntryId -notmatch '^\{[0-9a-fA-F-]{36}\}$') { throw "Bad boot entry id in config.json: $($cfg.EntryId)" }
    & bcdedit.exe /set '{fwbootmgr}' bootsequence $cfg.EntryId | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "bcdedit failed with code $LASTEXITCODE" }
    "$(Get-Date -Format s)  next boot -> $($cfg.Description) $($cfg.EntryId)" | Set-Content $log
    & shutdown.exe /r /t 0
} catch {
    "$(Get-Date -Format s)  ERROR: $_" | Set-Content $log
    exit 1
}
