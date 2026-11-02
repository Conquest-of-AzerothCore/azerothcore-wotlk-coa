param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$Transaction,
    [Parameter(Mandatory=$true)][string]$Python,
    [ValidateSet('preflight','publish')][string]$Phase='preflight'
)
$ErrorActionPreference='Stop'
$rootPath=(Resolve-Path -LiteralPath $Root).Path
$previousCertificate=$env:SSL_CERT_FILE
$trustDirectory=$null
try {
    & $Python (Join-Path $PSScriptRoot 'catalog_publication.py') $rootPath
    if ($LASTEXITCODE -ne 0) { throw 'Catalog input verification failed.' }
    . (Join-Path $rootPath 'publication_tls.ps1')
    $trustDirectory=Join-Path ([IO.Path]::GetTempPath()) ('area52-catalog-tls-'+[Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $trustDirectory | Out-Null
    $env:SSL_CERT_FILE=New-Area52PublicationTrust -Directory $trustDirectory
    & $Python (Join-Path $rootPath 'publish_client_release.py') $Phase $rootPath $Transaction
    if ($LASTEXITCODE -ne 0) { throw 'Catalog publication incomplete; preserve receipts for reconciliation.' }
} finally {
    $env:SSL_CERT_FILE=$previousCertificate
    if ($trustDirectory) {
        Remove-Item -LiteralPath (Join-Path $trustDirectory 'publication-ca.pem') -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $trustDirectory -ErrorAction SilentlyContinue
    }
}
