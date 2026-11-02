param(
    [Parameter(Mandatory=$true)][string]$Runtime,
    [ValidateSet('preflight','enable','verify')][string]$Phase='preflight'
)
$ErrorActionPreference='Stop'
$name='Area52 Featured Catalog'
$existing=Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
$script=Join-Path $Runtime 'Run-Catalog.ps1'
$arguments='-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "'+$script+'" -Runtime "'+$Runtime+'"'
if ($Phase -eq 'preflight') {
    if ($existing) { throw 'Existing catalog task requires explicit reconciliation.' }
    Get-Command Register-ScheduledTask -ErrorAction Stop | Out-Null
    Write-Output ('A52_CATALOG_TASK_OK:'+ $Phase)
    return
}
if ($existing) {
    if (@($existing.Actions).Count -ne 1 -or $existing.Actions[0].Arguments -ne $arguments) {
        throw 'Catalog task differs from this package.'
    }
} elseif ($Phase -eq 'enable') {
    $action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
    $trigger=New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 1)
    $settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 35)
    $principal=New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Publish GM-saved Featured vanity catalogs through the qualified launcher feed.' | Out-Null
} else { throw 'Catalog task is missing.' }
$current=Get-ScheduledTask -TaskName $name
if (@($current.Actions).Count -ne 1 -or $current.Actions[0].Arguments -ne $arguments) { throw 'Catalog task readback failed.' }
Write-Output ('A52_CATALOG_TASK_OK:'+ $Phase)
