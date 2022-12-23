program SampleConsoleElasticSearch;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse, Horse.Constants,
  Horse.DataLogger,
  DataLogger.Provider.Console,
  DataLogger.Provider.ElasticSearch,
  System.SysUtils
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
  // Middleware
  THorse.Use(
    THorseDataLogger.Logger(

      // TypeFormat
      THorseDataLoggerFormat.Combined,

    [
      // Provider 1
      TProviderConsole.Create,

      // Provider 2
      TProviderElasticSearch.Create
        .URL('http://localhost:9200')
        .Index('log_request')

      // ....Add others Providers
    ]));


  // Routes
  THorse.Get('/success', Success);
  THorse.Get('/info', Info);
  THorse.Get('/warn', Warn);
  THorse.Get('/error', Error);


  // Listen
  THorse.Listen(9000,
    procedure(AHorse: THorse)
    begin
      Writeln(' ' + Format(START_RUNNING, [THorse.Host, THorse.Port]));
    end);
end.
