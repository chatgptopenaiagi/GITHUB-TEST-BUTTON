param([string]$Keytool)
. "$PSScriptRoot/Common.ps1"
$key=Resolve-Tool 'keytool' @($Keytool,"$env:JAVA_HOME/bin/keytool.exe",'C:\Program Files\Android\openjdk\jdk-21.0.8\bin\keytool.exe')
$private="$ProjectRoot/.private"
$store="$private/gtb-release.p12"
$properties="$ProjectRoot/flutter/android/key.properties"
if((Test-Path $store) -or (Test-Path $properties)){throw 'Signing material already exists; preserving it. Never replace a published application signing key.'}
New-Item -ItemType Directory -Force $private|Out-Null
$password=[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
$env:GTB_SIGNING_PASSWORD=$password
try{
    Invoke-Checked $key @('-genkeypair','-keystore',$store,'-storetype','PKCS12','-alias','gtb-release','-keyalg','RSA','-keysize','4096','-validity','10000','-dname','CN=GITHUB TEST BUTTON, OU=GTB, O=GTB contributors','-storepass:env','GTB_SIGNING_PASSWORD','-keypass:env','GTB_SIGNING_PASSWORD')
    @("storeFile=$($store.Replace('\','/'))","storePassword=$password","keyPassword=$password",'keyAlias=gtb-release')|Set-Content $properties -Encoding ascii
    # Restrict secrets to the current Windows account and SYSTEM.
    foreach($path in @($store,$properties)){
        $acl=Get-Acl $path
        $acl.SetAccessRuleProtection($true,$false)
        $acl.SetAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.WindowsIdentity]::GetCurrent().User,'FullControl','Allow'))
        $acl.SetAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new('S-1-5-18'),'FullControl','Allow'))
        Set-Acl $path $acl
    }
    Write-Output 'Created project release signing key. Back up .private/gtb-release.p12 and android/key.properties securely; neither belongs in Git or release assets.'
} finally {Remove-Item Env:GTB_SIGNING_PASSWORD -ErrorAction SilentlyContinue}
