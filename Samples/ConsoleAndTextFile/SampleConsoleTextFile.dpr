program SampleConsoleTextFile;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.IOUtils, System.SysUtils,
  Horse, Horse.Constants,
  Horse.DataLogger,
  DataLogger.Provider.Console,
  DataLogger.Provider.TextFile
    ;

procedure Success(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('pong').Status(200); // StatusCode 0 -- 299 = Success
end;

procedure Info(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('pong').Status(300); // StatusCode 300 -- 399 = Info
end;

procedure Warn(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('pong').Status(400); // StatusCode 400 -- 499 = Warn
end;

procedure Error(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('pong').Status(500); // StatusCode 500 -- 599 = Error
end;

begin
  THorse.Use(
    THorseDataLogger.Logger(

      // TypeFormat
      THorseDataLoggerFormat.Combined,

    [
      // Provider 1
      TProviderConsole.Create,

      // Provider 2
      TProviderTextFile.Create
        .LogDir(TPath.GetDirectoryName(ParamStr(0)) + '\log\request')
        .PrefixFileName('request_')
        .FormatDateTime('yyyy-mm-dd')
        .Extension('txt')
        .MaxBackupFileCount(3)
        .Compress(True)

      // ....Add others Providers
    ]));


  // Routes
  THorse.Get('/success', Success);
  THorse.Get('/info', Info);
  THorse.Get('/warn', Warn);
  THorse.Get('/error', Error);


  // Info
  Writeln;
  Writeln(Format(' See the file: %s', [TPath.GetDirectoryName(ParamStr(0)) + '\log\request']));
  Writeln;
  Writeln;


  // Listen
  THorse.KeepConnectionAlive := True;
  THorse.Listen(8080,
    procedure(AHorse: THorse)
    begin
      Writeln(' ' + Format(START_RUNNING, [THorse.Host, THorse.Port]));
      Writeln;
    end);

end.
