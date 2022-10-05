{.$DEFINE CHECK_FOR_EXECUTE}
unit uMain;

interface

uses

  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.SvcMgr,
  Vcl.Dialogs,
  WorkerThreadU;

  const c_ServiceName = 'The_simplest_currency_service';

type

    TSampleService = class(TService)
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
  private
    FWorkerThread: TWorkerThread;
  public
    function GetServiceController: TServiceController; override;
  end;

  var
  SampleService: TSampleService;

implementation
{$R *.dfm}

uses System.IOUtils, IniFiles, uUtilities;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  SampleService.Controller(CtrlCode);
end;

function TSampleService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TSampleService.ServiceContinue(Sender: TService; var Continued: Boolean);

begin
  FWorkerThread.Continue;
  Continued := True;
end;

procedure TSampleService.ServicePause(Sender: TService; var Paused: Boolean);

begin
  FWorkerThread.Pause;
  Paused := True;
end;

procedure TSampleService.ServiceStart(Sender: TService; var Started: Boolean);
var
  IniFileName: TFileName;
  ini : TIniFile;
  folderXML, folderJSON: TFileName;
  ExePath: TFileName;
begin

  ExePath := TPath.GetDirectoryName(GetModuleName(HInstance));
  IniFileName := TPath.Combine(ExePath, 'Settings') + '.ini';
  ini := TIniFile.Create(IniFileName);

  try
    folderXML := ini.ReadString('XML', 'folderPath', '');
    folderJSON := ini.ReadString('JSON', 'folderPath', '');

    if folderXML = '' then
    begin
      ini.WriteString('XML', 'folderPath', ExePath + '\XML');
      folderXML := ini.ReadString('XML', 'folderPath', '');
    end;

    if folderJSON = '' then
    begin
      ini.WriteString('JSON', 'folderPath', ExePath + '\JSON');
      folderJSON := ini.ReadString('JSON', 'folderPath', '');
    end;

    if not TDirectory.Exists(folderXML) then
      TDirectory.CreateDirectory(folderXML);

    if not TDirectory.Exists(folderJSON) then
      TDirectory.CreateDirectory(folderJSON);

  finally
    ini.Free;
  end;


  logString('TSampleService.ServiceStart');
  logString(Format('folder for XML: %s; folder for JSON: %s', [folderXML, folderJSON]));

  FWorkerThread := TWorkerThread.Create(True);

  FWorkerThread.setFoldersPath(folderXML, folderJSON);
  FWorkerThread.Start;
  Started := True;
end;

procedure TSampleService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin

  logString('TSampleService.Stop');
  FWorkerThread.Terminate;
  FWorkerThread.WaitFor;
  FreeAndNil(FWorkerThread);
  Stopped := True;
end;

procedure TSampleService.ServiceExecute(Sender: TService);
begin
  while not Terminated do
  begin
    {$IFDEF CHECK_FOR_EXECUTE}logString('TSampleService.Execute');{$ENDIF}
    ServiceThread.ProcessRequests(false);
    TThread.Sleep(1000);
  end;
end;

end.
