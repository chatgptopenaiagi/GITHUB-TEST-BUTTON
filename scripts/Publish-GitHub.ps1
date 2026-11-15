param([switch]$PublishPrerelease)
. "$PSScriptRoot/Common.ps1"
$gh=Resolve-Tool 'gh'
$git=Resolve-Tool 'git'
$head=& $git -C $ProjectRoot rev-parse HEAD
if($LASTEXITCODE -ne 0){throw 'Committed project required'}
$tagCommit=& $git -C $ProjectRoot rev-list -n 1 v0.1.0-beta.1
if($LASTEXITCODE -ne 0 -or $tagCommit -ne $head){throw 'Release tag must already exist and match the reviewed HEAD commit'}
if($PublishPrerelease){
    $decisionFile="$ProjectRoot/reports/release-decision.json"
    if(!(Test-Path $decisionFile)){throw 'A reviewed release-decision.json is required to publish; otherwise create a draft'}
    $decision=Get-Content $decisionFile -Raw|ConvertFrom-Json
    if(!$decision.approved_for_prerelease -or $decision.commit -ne $head){throw 'Prerelease approval does not match current source commit'}
    foreach($gate in @('windows_build','windows_launch','android_build','android_signing','python_install','python_execution','contract_tests')){
        if($decision.gates.$gate -ne 'PASS'){throw "Prerelease gate failed: $gate"}
    }
}
& "$PSScriptRoot/Verify-Artifacts.ps1"
if($LASTEXITCODE -ne 0){throw 'Artifact verification failed'}
$owner=& $gh api user --jq '.login'
if($LASTEXITCODE -ne 0 -or $owner -ne 'chatgptopenaiagi'){throw 'Expected publisher authentication unavailable'}
$repo=& $gh repo view chatgptopenaiagi/GITHUB-TEST-BUTTON --json nameWithOwner,isPrivate | ConvertFrom-Json
if($repo.nameWithOwner -ne 'chatgptopenaiagi/GITHUB-TEST-BUTTON' -or $repo.isPrivate){throw 'Unexpected target repository'}
$manifest=Get-Content "$ProjectRoot/release-manifest.json" -Raw|ConvertFrom-Json
$assets=@($manifest.artifacts|ForEach-Object{Join-Path $ProjectRoot $_.path})+@("$ProjectRoot/dist/SHA256SUMS.txt","$ProjectRoot/release-manifest.json")
$releaseArgs=@('release','create','v0.1.0-beta.1','--repo','chatgptopenaiagi/GITHUB-TEST-BUTTON','--verify-tag','--target',$head,'--prerelease','--title','GTB v0.1.0-beta.1','--notes-file',"$ProjectRoot/RELEASE-NOTES.md")
if(!$PublishPrerelease){$releaseArgs+='--draft'}
Invoke-Checked $gh ($releaseArgs+$assets)
