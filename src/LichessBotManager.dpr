program LichessBotManager;

uses
  uSxGUIApplication,
  uMain in 'uMain.pas' {fMain},
  uLichessBotManager in 'uLichessBotManager.pas',
  uLichessBot in 'uLichessBot.pas';

{$R *.res}

var
  GUIApplication: TSxGUIApplication;
  GLichessBotManager: TLichessBotManager;
begin
  GUIApplication := TSxGUIApplication.Create;
  try
    if GUIApplication.Initialized then
    begin
      GLichessBotManager := TLichessBotManager.Create;
      try
        GUIApplication.CreateForm(TfMain, fMain);
        try
          fMain.LichessBotManager := GLichessBotManager;
          GUIApplication.Run;
        finally
          fMain.LichessBotManager := nil;
        end;
      finally
        GLichessBotManager.Free;
      end;
    end;
  finally
    GUIApplication.Free;
  end;
end.
