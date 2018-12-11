unit Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Quick.Config,
  Quick.Config.Provider.Registry,
  System.Generics.Collections,
  Quick.Config.Provider.Json;

type

  TMyPriority = (msLow, msMed, msHigh);

  TWinPos = record
  public
    PosX : Integer;
    PosY : Integer;
  end;

  TProcessType = record
    Id : Integer;
    Priority : TMyPriority;
    Redundant : Boolean;
  end;

  TWorker = class
  private
    fName : string;
    fActive : Boolean;
  published
    property Name : string read fName write fName;
    property Active : Boolean read fActive write fActive;
  end;

  TMyConfig = class(TAppConfig)
  private
    fTitle : string;
    fHidden : Boolean;
    fSessionName: string;
    fSizes : TArray<Integer>;
    fLastFilename : string;
    fWindowPos : TWinPos;
    fHistory : TArray<TProcessType>;
    fComplex : TProcessType;
    fModifyDate : TDateTime;
    fWorkList : TObjectList<TWorker>;
  published
    property Sizes : TArray<Integer> read fSizes write fSizes;
    property LastFilename : string read fLastFilename write fLastFilename;
    property WindowPos : TWinPos read fWindowPos write fWindowPos;
    property History : TArray<TProcessType> read fHistory write fHistory;
    property Complex : TProcessType read fComplex write fComplex;
    property ModifyDate : TDateTime read fModifyDate write fModifyDate;
    property Title : string read fTitle write fTitle;
    property SessionName : string read fSessionName write fSessionName;
    property WorkList : TObjectList<TWorker> read fWorkList write fWorkList;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure DefaultValues; override;
  end;

  TMainForm = class(TForm)
    meInfo: TMemo;
    btnLoadJson: TButton;
    btnSaveJson: TButton;
    btnLoadRegistry: TButton;
    SaveRegistry: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadJsonClick(Sender: TObject);
    procedure btnSaveJsonClick(Sender: TObject);
    procedure SaveRegistryClick(Sender: TObject);
    procedure btnLoadRegistryClick(Sender: TObject);
    procedure SetConfig(cConfig: TMyConfig);
    function TestConfig(cConfig1, cConfig2: TMyConfig) : Boolean;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  end;

var
  MainForm: TMainForm;
  ConfigJson : TMyConfig;
  ConfigReg : TMyConfig;
  ConfigTest : TMyConfig;
  AppConfigJson : TAppConfigJsonProvider<TMyConfig>;
  AppConfigReg : TAppConfigRegistryProvider<TMyConfig>;

implementation

{$R *.dfm}

procedure TMainForm.btnLoadJsonClick(Sender: TObject);
begin
  meInfo.Lines.Add('Load ConfigJson');
  AppConfigJson.Load(ConfigJson);
  meInfo.Lines.Add(ConfigJson.ToJSON);
  if TestConfig(ConfigTest,ConfigJson) then meInfo.Lines.Add('Test passed successfully!');
end;

procedure TMainForm.btnLoadRegistryClick(Sender: TObject);
begin
  meInfo.Lines.Add('Load ConfigReg');
  AppConfigReg.Load(ConfigReg);
  meInfo.Lines.Add(ConfigReg.ToJSON);
  if TestConfig(ConfigTest,ConfigReg) then meInfo.Lines.Add('Test passed successfully!');
end;

procedure TMainForm.btnSaveJsonClick(Sender: TObject);
begin
  SetConfig(ConfigJson);
  AppConfigJson.Save(ConfigJson);
  meInfo.Lines.Add('Saved Config in Json at ' + DateTimeToStr(ConfigJson.LastSaved));
end;

procedure TMainForm.SaveRegistryClick(Sender: TObject);
begin
  SetConfig(ConfigReg);
  AppConfigReg.Save(ConfigReg);
  meInfo.Lines.Add('Saved Config in Registry at ' + DateTimeToStr(ConfigReg.LastSaved));
end;

procedure TMainForm.SetConfig(cConfig : TMyConfig);
var
  winpos : TWinpos;
  protype : TProcessType;
  i : Integer;
  worker : TWorker;
begin
  cConfig.LastFilename := 'library.txt';
  cConfig.Sizes := [23,11,554,12,34,29,77,30,48,59,773,221,98,3,22,983,122,231,433,12,31,987];
  winpos.PosX := 640;
  winpos.PosX := 480;
  cConfig.WindowPos := winpos;
  protype.Priority := msHigh;
  protype.Redundant := False;
  cConfig.Complex := protype;
  cConfig.Title := 'a fresh title';
  cConfig.SessionName := 'First Session';
  for I := 0 to 22 do
  begin
    worker := TWorker.Create;
    worker.Name := 'Process ' + i.ToString;
    worker.Active := Boolean(Random(1));
    cConfig.WorkList.Add(worker);
  end;
  for i := 0 to 15 do
  begin
    protype.Id := i;
    protype.Priority := msLow;
    protype.Redundant := True;
    cConfig.History := cConfig.History + [protype];
  end;
  cConfig.ModifyDate := Now();
end;

function  TMainForm.TestConfig(cConfig1, cConfig2 : TMyConfig) : Boolean;
var
  i : Integer;
begin
  Result := False;
  try
    Assert(cConfig1.LastFilename = cConfig2.LastFilename);
    for i := Low(cConfig1.Sizes) to High(cConfig1.Sizes) do
      Assert(cConfig1.Sizes[i] = cConfig2.Sizes[i]);
    Assert(cConfig1.WindowPos.PosX = cConfig2.WindowPos.PosX);
    Assert(cConfig1.WindowPos.PosX = cConfig2.WindowPos.PosX);
    Assert(cConfig1.Complex.Priority = cConfig2.Complex.Priority);
    Assert(cConfig1.Complex.Redundant  = cConfig2.Complex.Redundant);
    Assert(cConfig1.Title = cConfig2.Title);
    for i := 0 to cConfig1.WorkList.Count - 1 do
    begin
      Assert(cConfig1.WorkList[i].Name = cConfig2.WorkList[i].Name);
      Assert(cConfig1.WorkList[i].Active = cConfig2.WorkList[i].Active);
    end;
    for i := 0 to High(cConfig1.History) do
    begin
      Assert(cConfig1.History[i].Priority = cConfig2.History[i].Priority);
      Assert(cConfig1.History[i].Redundant = cConfig2.History[i].Redundant);
    end;
    Result := True;
  except
    ShowMessage('Configuration not has been saved previously or has a corruption problem');
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(AppConfigJson) then AppConfigJson.Free;
  if Assigned(AppConfigReg) then AppConfigReg.Free;
  if Assigned(ConfigTest) then ConfigTest.Free;
  if Assigned(ConfigReg) then ConfigReg.Free;
  if Assigned(ConfigJson) then ConfigJson.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ConfigTest := TMyConfig.Create;
  SetConfig(ConfigTest);
  AppConfigJson := TAppConfigJsonProvider<TMyConfig>.Create(ConfigJson);
  AppConfigJson.CreateIfNotExists := True;
  AppConfigJson.Filename := 'Config.json';
  AppConfigReg := TAppConfigRegistryProvider<TMyConfig>.Create(ConfigReg);
  AppConfigReg.HRoot := HKEY_CURRENT_USER;
  AppConfigReg.MainKey := '_AppConfig';
end;

{ TMyConfig }

constructor TMyConfig.Create;
begin
  inherited;
  WorkList := TObjectList<TWorker>.Create(True);
  DefaultValues;
end;

procedure TMyConfig.DefaultValues;
begin
  fTitle := 'Default value';
end;

destructor TMyConfig.Destroy;
begin
  if Assigned(WorkList) then WorkList.Free;
  inherited;
end;

end.
