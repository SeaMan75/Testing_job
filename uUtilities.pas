unit uUtilities;

interface
uses
  SysUtils
    , XMLDoc
    , XMLIntf
    , ActiveX
    , System.IOUtils
    , System.JSON
    , System.SyncObjs
    , System.Classes;

  const

    TITLE = $01;
    FOOTER = $02;
    NOTHING = $00;
    OVERWRITE = true;
    RESULT_OK = true;
    RESULT_FAILED = false;

  function parseXML(const sXML: string; const aFileName: string): boolean;
  function parseJSON(const sJSON: String; const aFileName: string; aAnyThing: byte = NOTHING): boolean;

  procedure logString(aMessage: String);

implementation

  procedure appendToFile(const aFileName: Tfilename; const aData: string; aOverwrite: boolean = false);
  var
    section: TCriticalSection;

  begin
    section := TCriticalSection.Create;
    section.Enter;

    try
      if aOverwrite then
        TFile.WriteAllText(aFileName, aData + #$0D#$0A, TEncoding.ANSI)
      else
        TFile.AppendAllText(aFileName, aData + #$0D#$0A, TEncoding.ANSI);
    except on ex: EInOutError do
      begin
        logString('append to file error ' + ex.Message);
        raise Exception.Create('File writing failed');
      end;
    end;

   section.Leave;

  end;

  procedure logString(aMessage: string);
  var
    ExePath, LogFileName: TFileName;
    section: TCriticalSection;

  begin

    section := TCriticalSection.Create;
    section.Enter;
    try
      ExePath := TPath.GetDirectoryName(GetModuleName(HInstance));
      LogFileName := TPath.Combine(ExePath, 'Logger.log');
      TFile.AppendAllText(LogFileName, Format('%s [%s] > %s %s',
        [DateToStr(now), TimeToStr(now), aMessage, #$0D#$0A]), TEncoding.ANSI);
    except on ex: EInOutError do
       //log('Error writing log...');
    end;
    section.Leave;

  end;

  function parseXML(const sXML: string; const aFileName: string): Boolean;
  var
    Doc: IXMLDocument;
    Node: IXMLNode;
    BufXMLNodeList : IXMLNodeList;
    i: integer;
    NumCode, CharCode, Rate: String;

  begin
    try
      Doc := TXMLDocument.Create(nil);
      Doc.LoadFromXML(sXML);

      if Doc.ChildNodes[1].HasChildNodes then
      begin
        BufXMLNodeList := Doc.ChildNodes[1].ChildNodes;

        AppendToFile(aFileName, 'Курсы валют на ' + DateToStr(now), OVERWRITE);

        for i := 0 to Pred(BufXMLNodeList.Count) do
        begin
          NumCode := BufXMLNodeList[i].ChildNodes['NumCode'].NodeValue;
          if (NumCode = '840') or (NumCode = '643') or (NumCode = '978') then
          begin
            Rate := BufXMLNodeList[i].ChildNodes['Rate'].NodeValue;
            CharCode := BufXMLNodeList[i].ChildNodes['CharCode'].NodeValue;
            AppendToFile(aFileName, Format('Валюта: %s; Курс: %s', [CharCode, Rate]));
          end;
        end;
        AppendToFile(aFileName, 'Загрузка выполнена в: ' + DateTimeToStr(now));
        result := RESULT_OK;

      end;
    except on ex:Exception do
      begin
        logString('inner error ' + ex.Message);
        result := RESULT_FAILED;
      end;
    end;
  end;

  function parseJSON(const sJSON: String; const aFileName: string; aAnyThing: byte = NOTHING): boolean;
  var
    JSON: TJSONObject;
    CharCode, Rate: String;

  begin
    try

      if aAnyThing = TITLE then
        AppendToFile(aFileName, 'Курсы валют на ' + DateToStr(now), OVERWRITE);

      JSON := TJSONObject.ParseJSONValue(sJSON, False, True) as TJSONObject;
      try
        CharCode := JSON.Values['Cur_Abbreviation'].Value;
        Rate := JSON.Values['Cur_OfficialRate'].Value;
        AppendToFile(aFileName, Format('Валюта: %s; Курс: %s', [CharCode, Rate]));
      finally
        JSON.Free;
      end;

      if aAnyThing = FOOTER then
        AppendToFile(aFileName, 'Загрузка выполнена в: ' + DateTimeToStr(now));
        result := RESULT_OK;

    except on ex:Exception do
      begin
        logString('inner error' + ex.Message);
        result := RESULT_FAILED;
      end;
    end;

  end;

end.

