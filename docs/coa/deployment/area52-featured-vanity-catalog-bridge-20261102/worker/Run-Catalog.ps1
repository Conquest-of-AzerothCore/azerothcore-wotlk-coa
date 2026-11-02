param([Parameter(Mandatory=$true)][string]$Runtime)
$ErrorActionPreference='Stop'
$linuxRoot=& wsl.exe -d dml-arch -u root -- wslpath -a $Runtime.Replace('\','/')
if ($LASTEXITCODE -ne 0) { throw 'Unable to resolve catalog runtime.' }
& wsl.exe -d dml-arch -u root --exec python3 ($linuxRoot.Trim()+'/catalog_worker.py') --config ($linuxRoot.Trim()+'/config.json')
if ($LASTEXITCODE -ne 0) { throw 'Catalog worker paused; retained job and receipts require inspection.' }
