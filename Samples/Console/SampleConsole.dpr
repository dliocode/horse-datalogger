program SampleConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse,
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

  THorse.Listen(9000);
end.
