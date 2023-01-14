program SampleConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Horse, Horse.Constants,
  Horse.DataLogger,
  DataLogger.Provider.Console; // Provider para Console

begin
  THorse
   .Use(THorseDataLogger.Logger([TProviderConsole.Create])) // Adicionando Middleware e o Provider

  .Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.KeepConnectionAlive := True;
  THorse.Listen(8080,
    procedure(AHorse: THorse)
    begin
      Writeln(' ' + Format(START_RUNNING, [THorse.Host, THorse.Port]));
      Writeln;
    end);
end.
