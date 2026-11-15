param([switch]$Json)
. "$PSScriptRoot/Common.ps1"
$result = [ordered]@{timestamp=[DateTime]::UtcNow.ToString('o');tools=@();free_disk_bytes=(Get-PSDrive -Name ([IO.Path]::GetPathRoot($ProjectRoot).TrimEnd(':\'))).Free}
foreach ($name in @('git','gh','python','flutter','java','pwsh')) {
    $command=Get-Command $name -ErrorAction SilentlyContinue
    $result.tools += @{name=$name;detected=[bool]$command;path=$(if($command){$command.Source}else{$null});functional_verification='NOT_TESTED'}
}
New-Item -ItemType Directory -Force "$ProjectRoot/reports" | Out-Null
$result | ConvertTo-Json -Depth 5 | Set-Content "$ProjectRoot/reports/environment.json" -Encoding utf8
if($Json){$result|ConvertTo-Json -Depth 5}else{$result.tools|ForEach-Object{[pscustomobject]$_}|Format-Table}
if (@($result.tools|Where-Object{!$_.detected -and $_.name -in @('git','gh','python','flutter','pwsh')}).Count) { exit 1 }
