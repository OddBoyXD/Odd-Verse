[Setup]
AppId=B9F6E402-0CAE-4045-BDE6-14BD6C39C4EA
AppVersion=1.0.0+1
AppName=Odd Verse
AppPublisher=OddBoyXdxd69
AppPublisherURL=https://github.com/OddBoyXdxd69/Odd-Verse
AppSupportURL=https://github.com/OddBoyXdxd69/Odd-Verse
AppUpdatesURL=https://github.com/OddBoyXdxd69/Odd-Verse
DefaultDirName={autopf}\OddVerse
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=OddVerse-1.0.0
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
Source: "..\..\build\windows\x64\runner\Release\oddverse.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\Odd Verse"; Filename: "{app}\oddverse.exe"
Name: "{autodesktop}\Odd Verse"; Filename: "{app}\oddverse.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\oddverse.exe"; Description: "{cm:LaunchProgram,{#StringChange('Odd Verse', '&', '&&')}}"; Flags: nowait postinstall skipifsilent
