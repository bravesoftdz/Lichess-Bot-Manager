unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uDWinControl, uDImage, uDView, Vcl.StdCtrls, Vcl.Menus,

  uTypes,
  uDForm,

  uLichessBot,
  uLichessBotManager;

type
  TfMain = class(TDForm)
    DView1: TDView;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Options1: TMenuItem;
    Help1: TMenuItem;
    EngineRootFolder1: TMenuItem;
    SelectedBots1: TMenuItem;
    OpenLogFile1: TMenuItem;
    EditConfiguration1: TMenuItem;
    N1: TMenuItem;
    Start1: TMenuItem;
    Stop1: TMenuItem;
    Restart1: TMenuItem;
    ReloadBotFolder1: TMenuItem;
    StartBotsAfterApplicationStart1: TMenuItem;
    StartAll1: TMenuItem;
    RestartBotIfFails1: TMenuItem;
    StopAll1: TMenuItem;
    PopupMenu1: TPopupMenu;
    Bots1: TMenuItem;
    OpenLichessBotWebPage1: TMenuItem;
    ClearErrors1: TMenuItem;
    ClearGames1: TMenuItem;
    N2: TMenuItem;
    procedure DView1GetDataEx(Sender: TObject; var Data: Variant; ColIndex, RowIndex: Integer; Rect: TRect);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EngineRootFolder1Click(Sender: TObject);
    procedure DView1DblClick(Sender: TObject);
    procedure OpenLogFile1Click(Sender: TObject);
    procedure BotConfiguration1Click(Sender: TObject);
    procedure Start1Click(Sender: TObject);
    procedure ReloadBotFolder1Click(Sender: TObject);
    procedure Restart1Click(Sender: TObject);
    procedure Stop1Click(Sender: TObject);
    procedure StartBotsAfterApplicationStart1Click(Sender: TObject);
    procedure StartAll1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure RestartBotIfFails1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StopAll1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure OpenLichessBotWebPage1Click(Sender: TObject);
    procedure ClearGames1Click(Sender: TObject);
    procedure ClearErrors1Click(Sender: TObject);
  private
    FLichessBotManager: TLichessBotManager;
    procedure ReadFolder;
    procedure RWOptions(const Save: BG);
    procedure SetLichessBotManager(const Value: TLichessBotManager);
    procedure CreateColumns;
    procedure OnBotChange(Sender: TObject);
    function GetStateAsText(const Bot: TLichessBot): string;
  public
    property LichessBotManager: TLichessBotManager read FLichessBotManager write SetLichessBotManager;
  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}

uses
  UITypes,

  uSystem,
  uAPI,
  uDIniFile,
  uStrings,
  uLongOperation,
  uCommonApplication,
  uOutputFormat,
  uMsg,
  uOutputInfo,
  uNamedColors,
  uColor,
  uMenus;

procedure TfMain.DView1DblClick(Sender: TObject);
begin
  if (DView1.IY >= 0) and (DView1.IX >= 0) then
  begin
    if DView1.IX < 8 then
      BotConfiguration1Click(Sender)
    else if DView1.IX < 11 then
      OpenLogFile1Click(Sender)
    else
      OpenLichessBotWebPage1Click(Sender);
  end;
end;

procedure TfMain.DView1GetDataEx(Sender: TObject; var Data: Variant; ColIndex, RowIndex: Integer; Rect: TRect);
var
  Bot: TLichessBot;
begin
  Bot := FLichessBotManager.LichessBots[RowIndex];
  case ColIndex of
  0: Data := RowIndex + 1;
  1: Data := ExtractFilePath(Bot.FileName);
  2: Data := ExtractFileName(Bot.FileName);
  3: Data := Bot.Name;
  4: Data := Bot.FileDateTime;
  5: Data := Bot.FileSize;
  6:
  begin
    if Bot.ExternalApplication.Handle <> INVALID_HANDLE_VALUE then
      Data := Bot.AllocatedMemoryPeak
    else
      Data := NAStr;
  end;
  7:
  begin
    if Bot.ExternalApplication.Handle <> INVALID_HANDLE_VALUE then
      Data := Bot.InitializationTime.MillisecondsAsF
    else
      Data := NAStr;
  end;
  8:
  begin
    Data := GetStateAsText(Bot);
  end;
  9:
  begin
    if Bot.ExternalApplication.Handle <> INVALID_HANDLE_VALUE then
    begin
      if Bot.ExternalApplication.ExitCode = STILL_ACTIVE then
        Data := '?'
      else
        Data := NToS(Bot.ExternalApplication.ExitCode, ofDisplay, 16) + ' h';
    end
    else
      Data := NAStr; // Not run yet or failed to run
  end;
  10:
  begin
    Data := Bot.ValueErrorCount;
    if Bot.ValueErrorCount > 0 then
      DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncRed));
  end;
  11:
  begin
    Data := Bot.ErrorCount;
    if Bot.ErrorCount > 0 then
      DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncRed));
  end;
  12:
  begin
    Data := Bot.FailCount;
    if Bot.FailCount > 0 then
      DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncRed));
  end;
  13:
  begin
    Data := Bot.QueuedGames;
    if Bot.QueuedGames > 0 then
      DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncBlue));
  end;
  14:
  begin
    Data := Bot.UsedGames;
    if Bot.UsedGames > 0 then
      DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncBlue));
  end;
  15:
  begin
    Data := Bot.PlayedGames;
    if Bot.QueuedGames > 0 then
      DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncBlue));
  end;
  16:
  begin
    if Bot.LastGameDate > 0 then
      Data := Bot.LastGameDate
    else
      Data := NAStr;
  end
  else
    Data := Null;
  end;
end;

procedure TfMain.BotConfiguration1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      APIOpen(FLichessBotManager.LichessBots[i].FileName);
end;

procedure TfMain.EngineRootFolder1Click(Sender: TObject);
var
  Path: string;
begin
  Path := FLichessBotManager.RootDirectory;
  if SelectFolder(Path, 'Lichess Bots (*.yml files) Root Folder') then
  begin
    FLichessBotManager.RootDirectory := Path;
    ReadFolder;
  end;
end;

procedure TfMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Action = csHide by default

  // Minimizes application instead of close it
  if IsRelease and (not Application.Terminated) and (not IsIconic(Application.Handle)) then
  begin
    Action := caNone;
    Application.Minimize;
  end;
end;

procedure TfMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Count: UG;
begin
  Count := FLichessBotManager.RunningBotCount;
  if Count > 0 then
  begin
    CanClose := Confirmation('Number of Lichess Bots running is ' + NToS(Count) + '. Do you want to close application and stop them?', [mbYes, mbNo]) = mbYes;
  end;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  CreateColumns;

  RWOptions(False);

  MenuCreate(SelectedBots1, PopupMenu1);
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  RWOptions(True);

  FLichessBotManager.OnChange := nil;
end;

procedure TfMain.FormShow(Sender: TObject);
begin
  RestartBotIfFails1.Checked := FLichessBotManager.RestarnBotIfFails;

  if CommonApplication.Statistics.RunFirstTime then
    EngineRootFolder1Click(Sender);

  ReadFolder;
  if StartBotsAfterApplicationStart1.Checked then
    FLichessBotManager.StartAll;
end;

procedure TfMain.OnBotChange(Sender: TObject);
begin
  DView1.DataChanged;
end;

procedure TfMain.OpenLichessBotWebPage1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      APIOpen(FLichessBotManager.LichessBots[i].WebAddress);
end;

procedure TfMain.OpenLogFile1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      APIOpen(FLichessBotManager.LichessBots[i].Logger.FileName);
end;

procedure TfMain.PopupMenu1Popup(Sender: TObject);
begin
  MenuUpdate(SelectedBots1, PopupMenu1.Items);
end;

procedure TfMain.ReadFolder;
var
  LongOperation: TLongOperation;
begin
  LongOperation := TLongOperation.Create;
  try
    LongOperation.Start;

    LongOperation.Title := 'Reading Lichess Bot Directory';
    FLichessBotManager.AddLichesBotsFromRootFolder;
    DView1.RowCount := FLichessBotManager.LichessBots.Count;
    DView1.DataChanged;

    LongOperation.Stop;
  finally
    LongOperation.Free;
  end;
end;

procedure TfMain.ReloadBotFolder1Click(Sender: TObject);
begin
  ReadFolder;
end;

procedure TfMain.Restart1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      FLichessBotManager.LichessBots[i].Restart;
end;

procedure TfMain.RestartBotIfFails1Click(Sender: TObject);
begin
  RestartBotIfFails1.Checked := not RestartBotIfFails1.Checked;
  FLichessBotManager.RestarnBotIfFails := RestartBotIfFails1.Checked;
end;

procedure TfMain.RWOptions(const Save: BG);
const
  Section = 'Engines';
begin
  MainIni.RWFormPos(Self, Save);
  DView1.Serialize(MainIni, Save);
  MainIni.RWMenuItem(Section, StartBotsAfterApplicationStart1, Save);
end;

procedure TfMain.SetLichessBotManager(const Value: TLichessBotManager);
begin
  FLichessBotManager := Value;
  FLichessBotManager.OnChange := OnBotChange;
end;

procedure TfMain.ClearErrors1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      FLichessBotManager.LichessBots[i].ClearErrors;
end;

procedure TfMain.ClearGames1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      FLichessBotManager.LichessBots[i].ClearGames;
end;

procedure TfMain.CreateColumns;
var
  s: string;
begin
  s := DateTimeToStr(32045.458);

  DView1.AddColumn('#', DView1.Canvas.TextWidth('888') + 2 * FormBorder, taRightJustify);
  DView1.AddColumn('Configuration Path', 50 * DView1.Canvas.TextWidth('W') + 2 * FormBorder, taLeftJustify);
  DView1.AddColumn('File Name', DView1.Canvas.TextWidth('Super Lichess Bot') + 2 * FormBorder, taLeftJustify);
  DView1.AddColumn('Engine File Name', DView1.Canvas.TextWidth('Super-Engine-2.11.exe') + 2 * FormBorder, taLeftJustify);
  DView1.AddColumn('Modified Date', DView1.Canvas.TextWidth(s) + 2 * FormBorder, taLeftJustify);
  DView1.AddColumn('Size', 0, taRightJustify);
  DView1.AddColumn('Memory', 0, taRightJustify);
  DView1.AddColumn('Initialization Time [ms]', 0, taRightJustify);
  DView1.AddColumn('Status', 0, taLeftJustify);
  DView1.AddColumn('Exit Code', 0, taRightJustify);
  DView1.AddColumn('Value Errors', 0, taRightJustify);
  DView1.AddColumn('Errors', 0, taRightJustify);
  DView1.AddColumn('Fails', 0, taRightJustify);
  DView1.AddColumn('Queued Games', 0, taRightJustify);
  DView1.AddColumn('Used Games', 0, taRightJustify);
  DView1.AddColumn('Played Games', 0, taRightJustify);
  DView1.AddColumn('Last Game Date', DView1.Canvas.TextWidth(s) + 2 * FormBorder, taLeftJustify);
end;

function TfMain.GetStateAsText(const Bot: TLichessBot): string;
begin
  case Bot.State of
    bsNone:
      Result := '�';
    bsTryingStart:
      begin
        DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncOrange));
        Result := 'Trying to log on';
      end;
    bsStartFailed:
      begin
        DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncRed));
        Result := 'Failed to start';
      end;
    bsStopped:
      begin
        Result := 'Stopped';
      end;
    bsStarted:
      begin
        DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncGreen));
        Result := 'Running';
      end;
  end;
  if Bot.RequiredStart then
  begin
    DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncYellowGreen));
    AppendStrSeparator(Result, 'Scheduled to start', ' | ');
  end;
  if Bot.RequiredStop then
  begin
    DView1.Bitmap.Canvas.Brush.Color := MixColors(DView1.Bitmap.Canvas.Brush.Color, TNamedColors.GetColor(TNamedColorEnum.ncYellow));
    AppendStrSeparator(Result, 'Scheduled to stop', ' | ');
  end;
end;

procedure TfMain.Start1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      FLichessBotManager.LichessBots[i].RequiredStart := True;
end;

procedure TfMain.StartAll1Click(Sender: TObject);
begin
  FLichessBotManager.StartAll;
end;

procedure TfMain.StartBotsAfterApplicationStart1Click(Sender: TObject);
begin
  StartBotsAfterApplicationStart1.Checked := not StartBotsAfterApplicationStart1.Checked;
end;

procedure TfMain.Stop1Click(Sender: TObject);
var
  i: SG;
begin
  for i := 0 to DView1.RowCount - 1 do
    if DView1.SelectedRows[i] then
      FLichessBotManager.LichessBots[i].Stop;
end;

procedure TfMain.StopAll1Click(Sender: TObject);
begin
  FLichessBotManager.StopAll;
end;

end.
