unit uHTTPQuery;

interface

uses
  SysUtils, HTTPApp, IdHTTP, XMLDoc, XMLIntf, ActiveX, System.IOUtils, System.Classes;

const
  SERVER_ADDRESS_XML = 'https://www.nbrb.by/Services/XmlExRates.aspx?ondate=';
  SERVER_ADDRESS_JSON = 'https://www.nbrb.by/api/exrates/rates/%d?parammode=1';
  USD = 840;
  RUB = 643;
  EUR = 978;


function getDataXML(): string;
function getDataJSONByCurrency(const aCurrenyCode: word): string;

implementation

uses
  uUtilities;

function getDataXML: string;
var
  CoResult: Integer;
  HTTP: TIdHTTP;
  Request: String;

begin

  logString('...function getData...');

  try
    CoResult := CoInitializeEx(nil, COINIT_MULTITHREADED);

    if not((CoResult = S_OK) or (CoResult = S_FALSE)) then
    begin
      logString(Format('XML - getData result - fail (#%d)', [CoResult]));
      Exit;
    end;

    HTTP := TIdHTTP.Create;
    Request := SERVER_ADDRESS_XML;
    Result := HTTP.Get(Request);
    HTTP.Destroy;

  except
    on E: Exception do
    begin
      logString(Format('XML - getData - (%s) message: %s', [E.ClassName, E.Message]));
      result := '';
    end;
  end;
end;

function getDataJSONByCurrency(const aCurrenyCode: word): string;
var
  CoResult: Integer;
  HTTP: TIdHTTP;
  Request: String;
  stream : TStringStream;

begin

  logString('...function getData...');

  HTTP := TIdHTTP.Create;

  try
    try
      CoResult := CoInitializeEx(nil, COINIT_MULTITHREADED);

      if not((CoResult = S_OK) or (CoResult = S_FALSE)) then
      begin
        logString(Format('JSON - getData result - fail (#%d)', [CoResult]));
        Exit;
      end;

      request := Format(SERVER_ADDRESS_JSON, [aCurrenyCode]);
      stream := TStringStream.Create(Result);
      HTTP.Get(Request, stream);
      stream.Position := 0;
      Result := stream.ReadString(stream.Size);

      // Display document content
      logString(Result);

    finally
      FreeAndNil(HTTP);
      FreeAndNil(stream);
      // //HTTP.Destroy;
    end;

  except
    on E: Exception do
    begin
      logString(Format('JSON - getData - (%s) message: %s', [E.ClassName, E.Message]));
      result := '';
    end;
  end;
end;

end.
