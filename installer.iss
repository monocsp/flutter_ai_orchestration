[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName=AI Orchestration
AppVersion=1.0.0
AppPublisher=AI Orchestration Team
DefaultDirName={autopf}\AI Orchestration
DefaultGroupName=AI Orchestration
OutputDir=installer_output
OutputBaseFilename=AI_Orchestration_Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\ai_orchestration.exe
WizardStyle=modern

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "dist\ai_orchestration.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\desktop_drop_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dist\user_handoff_kit\*"; DestDir: "{app}\user_handoff_kit"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\AI Orchestration"; Filename: "{app}\ai_orchestration.exe"
Name: "{group}\{cm:UninstallProgram,AI Orchestration}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\AI Orchestration"; Filename: "{app}\ai_orchestration.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\ai_orchestration.exe"; Description: "{cm:LaunchProgram,AI Orchestration}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  UninstallPath: String;
  Choice: Integer;
begin
  Result := True;

  if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#SetupSetting("AppId")}_is1',
    'UninstallString', UninstallPath) or
     RegQueryStringValue(HKCU, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#SetupSetting("AppId")}_is1',
    'UninstallString', UninstallPath) then
  begin
    Choice := MsgBox('AI Orchestration이 이미 설치되어 있습니다.' + #13#10 + #13#10 +
      '재설치하시겠습니까?' + #13#10 + #13#10 +
      '[예] 기존 버전을 삭제하고 재설치합니다.' + #13#10 +
      '[아니오] 설치를 취소합니다.',
      mbConfirmation, MB_YESNO);

    if Choice = IDYES then
    begin
      Exec(RemoveQuotes(UninstallPath), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
      Result := True;
    end
    else
    begin
      Result := False;
    end;
  end;
end;
