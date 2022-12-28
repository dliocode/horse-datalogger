program SampleConsoleAndDataBase;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  Horse,
  System.JSON,
  Horse.DataLogger,
  DataLogger.Provider.Console,
  DataLogger.Provider.Events,
  DataSet.Serialize,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  FireDAC.UI.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.VCLUI.Wait,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.DApt;

var
  FDConnection1: TFDConnection;
begin
  TDataSetSerializeConfig.GetInstance.CaseNameDefinition := TCaseNameDefinition.cndNone;

  FDConnection1 := TFDConnection.Create(nil);
  FDConnection1.DriverName := 'SQLite';
  FDConnection1.Params.Values['database'] := '.\..\..\DB\DB.db';
  FDConnection1.Connected := True;

  THorse
    .Use(THorseDataLogger.Logger([
      TProviderConsole.Create,

      TProviderEvents.Create
      .OnAny(
        procedure(const AItem: TJSONObject)
        var
          LQuery: TFDQuery;
        begin
          LQuery := TFDQuery.Create(FDConnection1);
          try
            LQuery.Connection := FDConnection1;
            LQuery.SQL.Text := 'SELECT * FROM LogDB WHERE 1 = 2';

            LQuery.Close;
            LQuery.Open;

            LQuery.LoadFromJSON(AItem.ToString);
          finally
            LQuery.Free;
          end;
        end)
    ])) // Adicionando Middleware e o Provider

    .Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);

end.
