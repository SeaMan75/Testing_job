unit WorkerThreadU;

interface

uses
  System.Classes, System.SysUtils;

type
  TWorkerThread = class(TThread)
  private
    FPaused: Boolean;
    fFolderXML, fFolderJSON: TFileName;
  protected
    procedure Execute; override;
  public
    procedure Pause;
    procedure Continue;
    procedure setFoldersPath(const aFolderXML, aFolderJSON: TfileName);
  end;

implementation

uses
  System.IOUtils,
  uHTTPQuery,
  uUtilities;

procedure TWorkerThread.Continue;
begin
  FPaused := False;
end;

procedure TWorkerThread.Execute;
var
  fileName: TFileName;
  xml, json: integer;

begin
  logString('Thread Running...');
  FPaused := False;
  (*************************************************************************************************
    Что делает поток:
    1. Смотрит каждую минуту есть ли на сегодня файлы с курсами валют.
    1.1. Если ХОТЯ БЫ одного из файлов нету, поток во внутреннем цикле пытается каждые 10 секунд
         стучаться на сервер, который ему отдаст нужные данные. Если все ок (фа йлы сформированы),
         то будет выход из цикла и поток продолжит работу.
    1.2 Если файлы на месте за текущую дату, то на сервер из потока запросы не полетят.
  *************************************************************************************************)

  while not Terminated do
  begin
    fileName := '\currencyData_' + FormatDateTime('yyyy_mm_dd', now) + '.txt';
    logString(fFolderXML + fileName);
    logString(fFolderJSON + fileName);

    if (not FileExists(fFolderXML + fileName)) or (not FileExists(fFolderJSON + fileName)) then
    try
        xml := 0;
        json := 0;

        while true do
        begin

          logString('#');
          if parseXML(getDataXML(), fFolderXML + fileName) then inc(xml);

          if parseJSON(getDataJSONByCurrency(USD), fFolderJSON + fileName, TITLE) then inc(json);
          if parseJSON(getDataJSONByCurrency(RUB), fFolderJSON + fileName) then inc(json) ;
          if parseJSON(getDataJSONByCurrency(EUR), fFolderJSON + fileName, FOOTER) then inc(json);
          sleep (10000);

          if (xml = 1) and (json = 3) then
          begin
            logString('На сегодня файлы с курсами валют сформированы');
            break;
          end
          else
          begin
            xml := 0;
            json := 0;
            logString('Сервер не отдал данныые...');
          end;
        end;

    except on E: Exception do
      begin
        logString(Format('Thread execute failed %s, %s', [E.ClassName, E.Message]));
      end;
    end;

    sleep(600000);
  end;
end;

procedure TWorkerThread.Pause;
begin
  FPaused := True;
end;

procedure TWorkerThread.setFoldersPath(const aFolderXML, aFolderJSON: TfileName);
begin
  fFolderXML := aFolderXML;
  fFolderJSON := aFolderJSON;
end;

end.
