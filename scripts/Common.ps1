$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:ProjectRoot = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force (Join-Path $script:ProjectRoot 'reports') | Out-Null
function Resolve-Tool([string]$Name, [string[]]$Candidates = @()) {
    foreach ($p in $Candidates) { if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { return $p } }
    $c = Get-Command $Name -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    throw "Required tool unavailable: $Name. Install its official distribution or provide the documented override."
}
function Invoke-Checked([string]$File, [string[]]$Arguments) {
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed ($LASTEXITCODE): $File" }
}
function Invoke-Flutter([string[]]$Arguments) {
    $f = Resolve-Tool 'flutter' @($env:GTB_FLUTTER, 'C:\flutter\bin\flutter.bat')
    # The cached SDK snapshot is the same installed Flutter tool; avoids the
    # Windows batch bootstrap when a current, complete cache is available.
    $sdk = Split-Path (Split-Path $f -Parent) -Parent
    $dart = Join-Path $sdk 'bin\cache\dart-sdk\bin\dart.exe'
    $snapshot = Join-Path $sdk 'bin\cache\flutter_tools.snapshot'
    if ((Test-Path $dart) -and (Test-Path $snapshot)) {
        Invoke-Checked $dart (@($snapshot) + $Arguments)
    } else { Invoke-Checked $f $Arguments }
}
function Assert-Artifact([string]$Path) {
    if (!(Test-Path -LiteralPath $Path -PathType Leaf) -or (Get-Item -LiteralPath $Path).Length -eq 0) { throw "Artifact missing or empty: $Path" }
    [pscustomobject]@{ name = Split-Path $Path -Leaf; path = [IO.Path]::GetRelativePath($script:ProjectRoot, $Path).Replace('\','/'); bytes = (Get-Item $Path).Length; sha256 = (Get-FileHash $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
}
