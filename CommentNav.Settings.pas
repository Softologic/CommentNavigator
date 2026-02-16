{*******************************************************}
{                                                       }
{       Comment Navigator - Settings                    }
{                                                       }
{       Settings manager and configuration dialog       }
{                                                       }
{       Purpose:                                        }
{       - Store settings in INI file                    }
{       - Separator character and minimum length        }
{       - Group header font parameters                  }
{       - Insert comment hotkey configuration           }
{       - Scan mode and sort mode persistence           }
{       - Visual settings editor form                   }
{                                                       }
{       Author: Oleg Granishevsky & Claude 4.6 Opus	    }
{       Version: 1.0                                    }
{       License: MIT                                    }
{                                                       }
{*******************************************************}

unit CommentNav.Settings;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, StdCtrls, ExtCtrls, Spin,
  Graphics, IniFiles, Dialogs, Menus, ComCtrls;

type
  TCommentNavSettingsManager = class
  private
    FSeparatorChar: Char;
    FMinSeparatorLen: Integer;
    FRequireOpenSeparator: Boolean;
    FRequireCloseSeparator: Boolean;
    FAutoScanOnActivate: Boolean;
    FGroupFontName: string;
    FGroupFontSize: Integer;
    FGroupFontBold: Boolean;
    FGroupFontItalic: Boolean;
    FGroupFontColor: TColor;
    FScanModeIndex: Integer;
    FSortModeIndex: Integer;
    FSortDirectionIndex: Integer;
    FSeparatorWidth: Integer;
    FInsertHotkey: TShortCut;
    FIniPath: string;
    FInsertClassName: Boolean;
    function GetIniPath: string;
  public
    constructor Create;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ResetDefaults;
    property SeparatorChar: Char read FSeparatorChar write FSeparatorChar;
    property MinSeparatorLen: Integer read FMinSeparatorLen write FMinSeparatorLen;
    property RequireOpenSeparator: Boolean read FRequireOpenSeparator write FRequireOpenSeparator;
    property RequireCloseSeparator: Boolean read FRequireCloseSeparator write FRequireCloseSeparator;
    property AutoScanOnActivate: Boolean read FAutoScanOnActivate write FAutoScanOnActivate;
    property GroupFontName: string read FGroupFontName write FGroupFontName;
    property GroupFontSize: Integer read FGroupFontSize write FGroupFontSize;
    property GroupFontBold: Boolean read FGroupFontBold write FGroupFontBold;
    property GroupFontItalic: Boolean read FGroupFontItalic write FGroupFontItalic;
    property GroupFontColor: TColor read FGroupFontColor write FGroupFontColor;
    property ScanModeIndex: Integer read FScanModeIndex write FScanModeIndex;
    property SortModeIndex: Integer read FSortModeIndex write FSortModeIndex;
    property SortDirectionIndex: Integer read FSortDirectionIndex write FSortDirectionIndex;
    property SeparatorWidth: Integer read FSeparatorWidth write FSeparatorWidth;
    property InsertHotkey: TShortCut read FInsertHotkey write FInsertHotkey;
    property InsertClassName: Boolean read FInsertClassName write FInsertClassName;
  end;

  TfrmCommentNavSettings = class(TForm)
    pnlMain: TPanel;
    grpPattern: TGroupBox;
    lblSepChar: TLabel;
    edtSepChar: TEdit;
    lblMinLen: TLabel;
    seMinLen: TSpinEdit;
    chkRequireOpen: TCheckBox;
    chkRequireClose: TCheckBox;
    lblPreview: TLabel;
    mmoPreview: TMemo;
    lblSepWidth: TLabel;
    seSepWidth: TSpinEdit;
    grpBehavior: TGroupBox;
    chkAutoLoad: TCheckBox;
    grpHotkey: TGroupBox;
    lblHotkey: TLabel;
    hkInsert: THotKey;
    grpGroups: TGroupBox;
    lblGroupFont: TLabel;
    lblGroupSize: TLabel;
    lblGroupColor: TLabel;
    cbGroupFontName: TComboBox;
    seGroupFontSize: TSpinEdit;
    chkGroupBold: TCheckBox;
    chkGroupItalic: TCheckBox;
    cbGroupColor: TColorBox;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnDefaults: TButton;
    chkInsertClassName: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnDefaultsClick(Sender: TObject);
    procedure edtSepCharChange(Sender: TObject);
    procedure seMinLenChange(Sender: TObject);
    procedure chkRequireOpenClick(Sender: TObject);
    procedure chkRequireCloseClick(Sender: TObject);
  private
    FSettings: TCommentNavSettingsManager;
    procedure SetSettings(Value: TCommentNavSettingsManager);
    procedure SettingsToControls;
    procedure UpdatePreview;
    procedure PopulateFontList;
  public
    property Settings: TCommentNavSettingsManager read FSettings write SetSettings;
  end;

function CommentNavSettings: TCommentNavSettingsManager;

implementation

{$R *.dfm}

var
  FInstance: TCommentNavSettingsManager = nil;

function CommentNavSettings: TCommentNavSettingsManager;
begin
  if FInstance = nil then
  begin
    FInstance := TCommentNavSettingsManager.Create;
    FInstance.LoadSettings;
  end;
  Result := FInstance;
end;

{ --------------------------------------------------------------------------- }
{  TCommentNavSettingsManager                                                  }
{ --------------------------------------------------------------------------- }

constructor TCommentNavSettingsManager.Create;
begin
  inherited;
  ResetDefaults;
end;

procedure TCommentNavSettingsManager.ResetDefaults;
begin
  FSeparatorChar := '=';
  FMinSeparatorLen := 10;
  FRequireOpenSeparator := True;
  FRequireCloseSeparator := True;
  FAutoScanOnActivate := True;
  FGroupFontName := 'Segoe UI';
  FGroupFontSize := 11;
  FGroupFontBold := True;
  FGroupFontItalic := False;
  FGroupFontColor := clNavy;
  FScanModeIndex := 0;
  FSortModeIndex := 0;
  FSortDirectionIndex := 0;
  FSeparatorWidth := 78;
  FInsertHotkey := Menus.ShortCut(VK_RETURN, [ssCtrl, ssAlt]);
  FInsertClassName := False;
end;


function TCommentNavSettingsManager.GetIniPath: string;
begin
  if FIniPath = '' then
    FIniPath := ChangeFileExt(GetModuleName(HInstance), '.ini');
  Result := FIniPath;
end;

procedure TCommentNavSettingsManager.LoadSettings;
var
  Ini: TIniFile;
begin
  if not FileExists(GetIniPath) then Exit;
  Ini := TIniFile.Create(GetIniPath);
  try
    FSeparatorChar := Ini.ReadString('Pattern', 'SeparatorChar', '=')[1];
    FMinSeparatorLen := Ini.ReadInteger('Pattern', 'MinSeparatorLen', 10);
    FRequireOpenSeparator := Ini.ReadBool('Pattern', 'RequireOpenSeparator', True);
    FRequireCloseSeparator := Ini.ReadBool('Pattern', 'RequireCloseSeparator', True);
    FSeparatorWidth := Ini.ReadInteger('Pattern', 'SeparatorWidth', 78);
    FAutoScanOnActivate := Ini.ReadBool('Behavior', 'AutoScanOnActivate', True);
    FInsertHotkey := TShortCut(Ini.ReadInteger('Hotkey', 'InsertComment',
      Integer(Menus.ShortCut(VK_RETURN, [ssCtrl, ssAlt]))));
    FGroupFontName := Ini.ReadString('Groups', 'FontName', 'Segoe UI');
    FGroupFontSize := Ini.ReadInteger('Groups', 'FontSize', 11);
    FGroupFontBold := Ini.ReadBool('Groups', 'FontBold', True);
    FGroupFontItalic := Ini.ReadBool('Groups', 'FontItalic', False);
    FGroupFontColor := TColor(Ini.ReadInteger('Groups', 'FontColor', Integer(clNavy)));
    FScanModeIndex := Ini.ReadInteger('UI', 'ScanMode', 0);
    FSortModeIndex := Ini.ReadInteger('UI', 'SortMode', 0);
    FSortDirectionIndex := Ini.ReadInteger('UI', 'SortDirection', 0);
    FInsertClassName := Ini.ReadBool('Hotkey', 'InsertClassName', False);
  finally
    Ini.Free;
  end;
end;


procedure TCommentNavSettingsManager.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    Ini.WriteString('Pattern', 'SeparatorChar', FSeparatorChar);
    Ini.WriteInteger('Pattern', 'MinSeparatorLen', FMinSeparatorLen);
    Ini.WriteBool('Pattern', 'RequireOpenSeparator', FRequireOpenSeparator);
    Ini.WriteBool('Pattern', 'RequireCloseSeparator', FRequireCloseSeparator);
    Ini.WriteInteger('Pattern', 'SeparatorWidth', FSeparatorWidth);
    Ini.WriteBool('Behavior', 'AutoScanOnActivate', FAutoScanOnActivate);
    Ini.WriteInteger('Hotkey', 'InsertComment', Integer(FInsertHotkey));
    Ini.WriteString('Groups', 'FontName', FGroupFontName);
    Ini.WriteInteger('Groups', 'FontSize', FGroupFontSize);
    Ini.WriteBool('Groups', 'FontBold', FGroupFontBold);
    Ini.WriteBool('Groups', 'FontItalic', FGroupFontItalic);
    Ini.WriteInteger('Groups', 'FontColor', Integer(FGroupFontColor));
    Ini.WriteInteger('UI', 'ScanMode', FScanModeIndex);
    Ini.WriteInteger('UI', 'SortMode', FSortModeIndex);
    Ini.WriteInteger('UI', 'SortDirection', FSortDirectionIndex);
    Ini.WriteBool('Hotkey', 'InsertClassName', FInsertClassName);
  finally
    Ini.Free;
  end;
end;

{ --------------------------------------------------------------------------- }
{  TfrmCommentNavSettings                                                      }
{ --------------------------------------------------------------------------- }

procedure TfrmCommentNavSettings.FormCreate(Sender: TObject);
begin
  PopulateFontList;
end;

procedure TfrmCommentNavSettings.PopulateFontList;
var
  Idx: Integer;
begin
  cbGroupFontName.Items.Clear;
  cbGroupFontName.Items.Assign(Screen.Fonts);
  if FSettings <> nil then
  begin
    Idx := cbGroupFontName.Items.IndexOf(FSettings.GroupFontName);
    if Idx >= 0 then
      cbGroupFontName.ItemIndex := Idx
    else
    begin
      Idx := cbGroupFontName.Items.IndexOf('Segoe UI');
      if Idx >= 0 then
        cbGroupFontName.ItemIndex := Idx
      else if cbGroupFontName.Items.Count > 0 then
        cbGroupFontName.ItemIndex := 0;
    end;
  end;
end;

procedure TfrmCommentNavSettings.SetSettings(Value: TCommentNavSettingsManager);
begin
  FSettings := Value;
  SettingsToControls;
end;


procedure TfrmCommentNavSettings.SettingsToControls;
var
  Idx: Integer;
begin
  if FSettings = nil then Exit;

  edtSepChar.Text := FSettings.SeparatorChar;
  seMinLen.Value := FSettings.MinSeparatorLen;
  seSepWidth.Value := FSettings.SeparatorWidth;
  chkRequireOpen.Checked := FSettings.RequireOpenSeparator;
  chkRequireClose.Checked := FSettings.RequireCloseSeparator;

  chkAutoLoad.Checked := FSettings.AutoScanOnActivate;
  hkInsert.HotKey := FSettings.InsertHotkey;

  Idx := cbGroupFontName.Items.IndexOf(FSettings.GroupFontName);
  if Idx >= 0 then
    cbGroupFontName.ItemIndex := Idx;
  seGroupFontSize.Value := FSettings.GroupFontSize;
  cbGroupColor.Selected := FSettings.GroupFontColor;
  chkGroupBold.Checked := FSettings.GroupFontBold;
  chkGroupItalic.Checked := FSettings.GroupFontItalic;
  chkInsertClassName.Checked := FSettings.InsertClassName;

  UpdatePreview;
end;


procedure TfrmCommentNavSettings.UpdatePreview;
var
  SepChar: Char;
  MinLen: Integer;
  SepLine, CommentLine: string;
begin
  if edtSepChar.Text <> '' then
    SepChar := edtSepChar.Text[1]
  else
    SepChar := '=';
  MinLen := seMinLen.Value;

  SepLine := '// ' + StringOfChar(SepChar, MinLen);
  CommentLine := '//  TODO: refactor this';

  mmoPreview.Lines.Clear;
  if chkRequireOpen.Checked then
    mmoPreview.Lines.Add(SepLine);
  mmoPreview.Lines.Add(CommentLine);
  if chkRequireClose.Checked then
    mmoPreview.Lines.Add(SepLine);

  SendMessage(mmoPreview.Handle, EM_LINESCROLL, 0, -mmoPreview.Lines.Count);
end;

procedure TfrmCommentNavSettings.edtSepCharChange(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TfrmCommentNavSettings.seMinLenChange(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TfrmCommentNavSettings.chkRequireOpenClick(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TfrmCommentNavSettings.chkRequireCloseClick(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TfrmCommentNavSettings.btnOKClick(Sender: TObject);
begin
  if FSettings = nil then Exit;

  if edtSepChar.Text <> '' then
    FSettings.SeparatorChar := edtSepChar.Text[1];
  FSettings.MinSeparatorLen := seMinLen.Value;
  FSettings.SeparatorWidth := seSepWidth.Value;
  FSettings.RequireOpenSeparator := chkRequireOpen.Checked;
  FSettings.RequireCloseSeparator := chkRequireClose.Checked;

  FSettings.AutoScanOnActivate := chkAutoLoad.Checked;
  FSettings.InsertHotkey := hkInsert.HotKey;

  if cbGroupFontName.ItemIndex >= 0 then
    FSettings.GroupFontName := cbGroupFontName.Items[cbGroupFontName.ItemIndex];
  FSettings.GroupFontSize := seGroupFontSize.Value;
  FSettings.GroupFontColor := cbGroupColor.Selected;
  FSettings.GroupFontBold := chkGroupBold.Checked;
  FSettings.GroupFontItalic := chkGroupItalic.Checked;
  FSettings.InsertClassName := chkInsertClassName.Checked;
  FSettings.SaveSettings;
  ModalResult := mrOk;
end;


procedure TfrmCommentNavSettings.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmCommentNavSettings.btnDefaultsClick(Sender: TObject);
begin
  if FSettings <> nil then
  begin
    FSettings.ResetDefaults;
    SettingsToControls;
  end;
end;

initialization

finalization
  FreeAndNil(FInstance);

end.

