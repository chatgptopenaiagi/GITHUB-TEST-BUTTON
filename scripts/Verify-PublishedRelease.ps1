param([string]$Tag='v0.1.0-beta.1')
. "$PSScriptRoot/Common.ps1"
$gh=Resolve-Tool 'gh'
$repo='chatgptopenaiagi/GITHUB-TEST-BUTTON'
$releaseJson=& $gh release view $Tag --repo $repo --json url,isDraft,isPrerelease,tagName,publishedAt,assets
if($LASTEXITCODE -ne 0){throw 'Release metadata lookup failed'}
$release=$releaseJson|ConvertFrom-Json
if($release.isDraft -or !$release.isPrerelease -or $release.tagName -ne $Tag){throw 'Expected published prerelease unavailable'}
$manifest=Get-Content "$ProjectRoot/release-manifest.json" -Raw|ConvertFrom-Json
$expected=@($manifest.artifacts|ForEach-Object{Join-Path $ProjectRoot $_.path})+@("$ProjectRoot/dist/SHA256SUMS.txt","$ProjectRoot/release-manifest.json")
$download=Join-Path $ProjectRoot '.verify/release-download'
New-Item -ItemType Directory -Force $download|Out-Null
Invoke-Checked $gh @('release','download',$Tag,'--repo',$repo,'--dir',$download,'--skip-existing')
$results=@(foreach($local in $expected){
    $name=Split-Path $local -Leaf
    $remote=@($release.assets|Where-Object name -eq $name)
    if($remote.Count -ne 1){throw "Published asset missing or duplicated: $name"}
    $received=Join-Path $download $name
    $localHash=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.ToLowerInvariant()
    $downloadHash=(Get-FileHash -LiteralPath $received -Algorithm SHA256).Hash.ToLowerInvariant()
    if($downloadHash -ne $localHash){throw "Downloaded checksum mismatch: $name"}
    if((Get-Item $received).Length -ne $remote[0].size){throw "Published size mismatch: $name"}
    [pscustomobject]@{name=$name;bytes=$remote[0].size;sha256=$localHash;download_matches=$true;url=$remote[0].url}
})
# Public API read deliberately supplies no authentication header.
$public=Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/tags/$Tag" -Headers @{'User-Agent'='GTB-release-verification'} -TimeoutSec 30
if($public.draft -or !$public.prerelease -or $public.assets.Count -ne $expected.Count){throw 'Anonymous published release readback mismatch'}
$tagCommit=& (Resolve-Tool 'git') -C $ProjectRoot rev-list -n 1 $Tag
[ordered]@{verified_at=[DateTime]::UtcNow.ToString('o');repository=$repo;release_url=$release.url;tag=$Tag;release_commit=$tagCommit;is_draft=$false;is_prerelease=$true;anonymous_api_readback='PASS';downloaded_assets=$results;asset_count=$results.Count;all_hashes_match=$true}|ConvertTo-Json -Depth 8|Set-Content "$ProjectRoot/release-verification.json" -Encoding utf8
Write-Output "Verified $($results.Count) published asset downloads against local SHA-256 values."
