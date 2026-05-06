[Setup]
AppId=B9F6E402-0CAE-4045-BDE6-14BD6C39C4EA
AppVersion=1.12.2+27
AppName=beatzpro
AppPublisher=Michael Anthony Valdiviezo Maza
AppPublisherURL=https://github.com/VMichael1999/BeatzPro
AppSupportURL=https://github.com/VMichael1999/BeatzPro
AppUpdatesURL=https://github.com/VMichael1999/BeatzPro
DefaultDirName={autopf}\beatzpro
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=beatzpro-1.12.2
Compression=lzma
SolidCompression=yes
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=lowest
LicenseFile=..\..\LICENSE
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\beatzpro.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\beatzpro"; Filename: "{app}\beatzpro.exe"
Name: "{autodesktop}\beatzpro"; Filename: "{app}\beatzpro.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\beatzpro.exe"; Description: "{cm:LaunchProgram,{#StringChange('beatzpro', '&', '&&')}}"; Flags: nowait postinstall skipifsilent
