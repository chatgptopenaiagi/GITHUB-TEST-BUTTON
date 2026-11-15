#ifndef SourceDir
  #define SourceDir "..\flutter\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist\windows"
#endif
[Setup]
AppId={{51C4475D-40F9-40C5-AB23-787DDBF7D344}
AppName=GITHUB TEST BUTTON
AppVersion=0.1.0-beta.1
AppVerName=GITHUB TEST BUTTON 0.1.0-beta.1
AppPublisher=GTB contributors
AppPublisherURL=https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON
DefaultDirName={localappdata}\Programs\GITHUB TEST BUTTON
DefaultGroupName=GITHUB TEST BUTTON
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=GTB-Windows-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\flutter\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\github_test_button.exe
DisableProgramGroupPage=yes
[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\GITHUB TEST BUTTON"; Filename: "{app}\github_test_button.exe"
[Run]
Filename: "{app}\github_test_button.exe"; Description: "Launch GITHUB TEST BUTTON"; Flags: nowait postinstall skipifsilent
