{*******************************************************}
{                                                       }
{       Comment Navigator - Main Frame                  }
{                                                       }
{       Core UI frame for comment navigation            }
{                                                       }
{       Purpose:                                        }
{       - Scan structured comments in source code       }
{       - Display results in grouped ListView           }
{       - Sort by line number, text, or group           }
{       - Real-time search filtering                    }
{       - Navigate to source line in IDE editor         }
{       - Scan modes: Rules, All //, All {}             }
{       - Collapsible group headers                     }
{                                                       }
{       Author: Oleg Granishevsky & Claude 4.6 Opus	    }
{       Version: 1.0                                    }
{       License: MIT                                    }
{                                                       }
{*******************************************************}
 
unit CommentNav.Frame;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls, CommCtrl, Menus, Dialogs,
  ToolsAPI, CommentNav.Settings, CommentNav.InsertComment;

type
  TSortMode = (smByLine, smByComment);
  TSortDirection = (sdAscending, sdDescending);
  TScanMode = (scmRulesSlash, scmRulesBrace, scmAllSlash, scmAllBrace, scmAll);

  TCommentInfo = record
    LineNumber: Integer;
    CommentText: string;
    GroupName: string;
    DisplayText: string;
    FileName: string;
  end;
  PCommentInfo = ^TCommentInfo;

  TListItemKind = (likComment, likGroupHeader);

  TListItemData = record
    Kind: TListItemKind;
    CommentInfo: PCommentInfo;
    GroupName: string;
  end;
  PListItemData = ^TListItemData;

  TGroupState = class
    GroupName: string;
    Collapsed: Boolean;
    constructor Create(const AName: string; ACollapsed: Boolean);
  end;

  TCommentNavFrame = class(TFrame)
    pnlTop: TPanel;
    pnlInfo: TPanel;
    btnScan: TButton;
    cbScanMode: TComboBox;
    btnSettings: TButton;
    btnSortByLine: TButton;
    btnSortByComment: TButton;
    lblInfo: TLabel;
    lvComments: TListView;
    pmMenu: TPopupMenu;
    miScan: TMenuItem;
    miSep1: TMenuItem;
    miGoTo: TMenuItem;
    miSep2: TMenuItem;
    miSortByLine: TMenuItem;
    miSortByComment: TMenuItem;
    miSep3: TMenuItem;
    miSettings: TMenuItem;
    miSep4: TMenuItem;
    miCollapseAll: TMenuItem;
    miExpandAll: TMenuItem;
    edtSearch: TEdit;

    procedure btnScanClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnSortByLineClick(Sender: TObject);
    procedure btnSortByCommentClick(Sender: TObject);
    procedure lvCommentsDblClick(Sender: TObject);
    procedure lvCommentsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lvCommentsClick(Sender: TObject);
    procedure miGoToClick(Sender: TObject);
    procedure miCollapseAllClick(Sender: TObject);
    procedure miExpandAllClick(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure lvCommentsResize(Sender: TObject);
    procedure cbScanModeChange(Sender: TObject);
    procedure WMInitScan(var Msg: TMessage); message WM_USER + 100;
  private
    FComments: TList;
    FListItemDatas: TList;
    FGroupStates: TList;
    FCurrentFile: string;
    FSortMode: TSortMode;
    FSortDirection: TSortDirection;
    FScanMode: TScanMode;
    FSearchText: string;
    FGroupsEnabled: Boolean;
    FOriginalWndProc: TWndMethod;
    procedure lvWndProc(var Message: TMessage);
    procedure ClearComments;
    procedure ClearListItemDatas;
    procedure ClearGroupStates;
    procedure ScanCurrentModule;
    procedure GoToSelectedComment;
    function IsSlashSeparatorLine(const ALine: string): Boolean;
    function IsBraceSeparatorLine(const ALine: string): Boolean;
    function ExtractSlashComment(const ALine: string): string;
    function ExtractBraceComment(const ALine: string): string;
    procedure ParseGroupAndText(const AText: string; out AGroup, ADisplay: string);
    procedure ShowSettings;
    procedure DoSort(AMode: TSortMode);
    procedure UpdateSortButtons;
    procedure UpdateInfoLabel;
    procedure ApplyFilter;
    function FindGroupState(const AName: string): TGroupState;
    function GetOrCreateGroupState(const AName: string): TGroupState;
    procedure ToggleGroup(const AName: string);
    procedure SetAllGroupsCollapsed(ACollapsed: Boolean);
    procedure lvCommentsCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvCommentsAdvancedCustomDrawSubItem(Sender: TCustomListView;
      Item: TListItem; SubItem: Integer; State: TCustomDrawState;
      Stage: TCustomDrawStage; var DefaultDraw: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure ScanLines(const AFileName: string; ALines: TStrings);
    procedure ScanCurrentEditorBuffer;
    procedure OnFileActivated(const AFileName: string);
  end;

implementation

{$R *.dfm}

var
  GSortMode: TSortMode;
  GSortDirection: TSortDirection;

{ --------------------------------------------------------------------------- }
{  TGroupState                                                                 }
{ --------------------------------------------------------------------------- }

constructor TGroupState.Create(const AName: string; ACollapsed: Boolean);
begin
  inherited Create;
  GroupName := AName;
  Collapsed := ACollapsed;
end;

{ --------------------------------------------------------------------------- }
{  Sort comparison                                                             }
{ --------------------------------------------------------------------------- }

function CompareComments(Item1, Item2: Pointer): Integer;
var
  A, B: PCommentInfo;
begin
  A := PCommentInfo(Item1);
  B := PCommentInfo(Item2);
  case GSortMode of
    smByLine:
      Result := A^.LineNumber - B^.LineNumber;
    smByComment:
      Result := CompareStringW(LOCALE_USER_DEFAULT, LINGUISTIC_IGNORECASE,
        PWideChar(A^.CommentText), Length(A^.CommentText),
        PWideChar(B^.CommentText), Length(B^.CommentText)) - CSTR_EQUAL;
  else
    Result := 0;
  end;
  if GSortDirection = sdDescending then
    Result := -Result;
end;

{ --------------------------------------------------------------------------- }
{  UTF-8 detection                                                             }
{ --------------------------------------------------------------------------- }

function IsValidUTF8(const ABytes: TBytes; ALen: Integer): Boolean;
var
  i, Extra, j: Integer;
  HasMultibyte: Boolean;
begin
  Result := False;
  HasMultibyte := False;
  i := 0;
  while i < ALen do
  begin
    if ABytes[i] < $80 then
    begin
      Inc(i);
      Continue;
    end;
    if (ABytes[i] and $E0) = $C0 then
      Extra := 1
    else if (ABytes[i] and $F0) = $E0 then
      Extra := 2
    else if (ABytes[i] and $F8) = $F0 then
      Extra := 3
    else
      Exit;
    if i + Extra >= ALen then
      Exit;
    for j := 1 to Extra do
    begin
      if (ABytes[i + j] and $C0) <> $80 then
        Exit;
    end;
    HasMultibyte := True;
    Inc(i, Extra + 1);
  end;
  Result := HasMultibyte;
end;

{ --------------------------------------------------------------------------- }
{  OTA utilities                                                               }
{ --------------------------------------------------------------------------- }

function GetCurrentSourceEditor: IOTASourceEditor;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  i: Integer;
begin
  Result := nil;
  if not Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then Exit;
  Module := ModuleServices.CurrentModule;
  if Module = nil then Exit;
  for i := 0 to Module.GetModuleFileCount - 1 do
    if Supports(Module.GetModuleFileEditor(i), IOTASourceEditor, Result) then Exit;
end;

function GetCurrentModuleText(out AFileName: string): TStrings;
var
  SourceEditor: IOTASourceEditor;
  Reader: IOTAEditReader;
  RawBytes: TBytes;
  Buffer: AnsiString;
  BytesRead, Position, TotalSize: Integer;
  DecodedText: string;
  HasBOM: Boolean;
const
  BLOCK_SIZE = 65536;
begin
  Result := nil;
  AFileName := '';
  SourceEditor := GetCurrentSourceEditor;
  if SourceEditor = nil then Exit;
  AFileName := SourceEditor.FileName;
  Reader := SourceEditor.CreateReader;
  if Reader = nil then Exit;

  TotalSize := 0;
  Position := 0;
  repeat
    SetLength(Buffer, BLOCK_SIZE);
    BytesRead := Reader.GetText(Position, PAnsiChar(Buffer), BLOCK_SIZE);
    if BytesRead > 0 then
    begin
      SetLength(RawBytes, TotalSize + BytesRead);
      Move(Buffer[1], RawBytes[TotalSize], BytesRead);
      Inc(TotalSize, BytesRead);
      Inc(Position, BytesRead);
    end;
  until BytesRead < BLOCK_SIZE;

  if TotalSize = 0 then Exit;

  HasBOM := (TotalSize >= 3) and (RawBytes[0] = $EF) and
            (RawBytes[1] = $BB) and (RawBytes[2] = $BF);

  if HasBOM then
    DecodedText := TEncoding.UTF8.GetString(RawBytes, 3, TotalSize - 3)
  else if IsValidUTF8(RawBytes, TotalSize) then
    DecodedText := TEncoding.UTF8.GetString(RawBytes, 0, TotalSize)
  else
    DecodedText := TEncoding.ANSI.GetString(RawBytes, 0, TotalSize);

  Result := TStringList.Create;
  Result.Text := DecodedText;
end;

procedure GotoEditorLine(ALine: Integer; const AFileName: string);
var
  SourceEditor: IOTASourceEditor;
  EditView: IOTAEditView;
  EditPos: TOTAEditPos;
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  i: Integer;
  Editor: IOTAEditor;
begin
  if not Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then Exit;

  Module := ModuleServices.CurrentModule;
  if (Module = nil) or (not SameText(Module.FileName, AFileName)) then
    Module := ModuleServices.OpenModule(AFileName);
  if Module = nil then Exit;

  SourceEditor := nil;
  for i := 0 to Module.GetModuleFileCount - 1 do
  begin
    Editor := Module.GetModuleFileEditor(i);
    if Supports(Editor, IOTASourceEditor, SourceEditor) then
    begin
      SourceEditor.Show;
      Break;
    end;
  end;

  if SourceEditor = nil then Exit;
  if SourceEditor.EditViewCount = 0 then Exit;

  EditView := SourceEditor.EditViews[0];
  EditPos.Line := ALine + 1;
  EditPos.Col := 1;
  EditView.SetCursorPos(EditPos);
  EditView.MoveViewToCursor;
  EditView.SetCursorPos(EditPos);
  EditView.Paint;

  if (EditView.GetEditWindow <> nil) and (EditView.GetEditWindow.Form <> nil) then
    EditView.GetEditWindow.Form.SetFocus;
end;

{ --------------------------------------------------------------------------- }
{  TCommentNavFrame — Custom Draw                                              }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.lvCommentsCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  ItemData: PListItemData;
  R, R1, R2: TRect;
  LV: TListView;
  GroupText, Arrow: string;
  GS: TGroupState;
  ItemCount: Integer;
  i: Integer;
  Info: PCommentInfo;
  IsSelected: Boolean;
begin
  if Item.Data = nil then Exit;
  ItemData := PListItemData(Item.Data);
  LV := TListView(Sender);
  DefaultDraw := False;

  R := Item.DisplayRect(drBounds);

  if ItemData^.Kind = likGroupHeader then
  begin
    LV.Canvas.Brush.Color := clBtnFace;
    LV.Canvas.FillRect(R);

    LV.Canvas.Pen.Color := clBtnShadow;
    LV.Canvas.MoveTo(R.Left, R.Bottom - 1);
    LV.Canvas.LineTo(R.Right, R.Bottom - 1);

    GS := FindGroupState(ItemData^.GroupName);
    if (GS <> nil) and GS.Collapsed then
      Arrow := WideChar($25B6)
    else
      Arrow := WideChar($25BC);

    ItemCount := 0;
    for i := 0 to FComments.Count - 1 do
    begin
      Info := PCommentInfo(FComments[i]);
      if ItemData^.GroupName = '(Other)' then
      begin
        if Info^.GroupName = '' then
          if (FSearchText = '') or
             (Pos(FSearchText, AnsiLowerCase(Info^.CommentText)) > 0) then
            Inc(ItemCount);
      end
      else
      begin
        if Info^.GroupName = ItemData^.GroupName then
          if (FSearchText = '') or
             (Pos(FSearchText, AnsiLowerCase(Info^.CommentText)) > 0) then
            Inc(ItemCount);
      end;
    end;

    LV.Canvas.Font.Name := CommentNavSettings.GroupFontName;
    LV.Canvas.Font.Size := CommentNavSettings.GroupFontSize;
    LV.Canvas.Font.Color := CommentNavSettings.GroupFontColor;
    LV.Canvas.Font.Style := [];
    if CommentNavSettings.GroupFontBold then
      LV.Canvas.Font.Style := LV.Canvas.Font.Style + [fsBold];
    if CommentNavSettings.GroupFontItalic then
      LV.Canvas.Font.Style := LV.Canvas.Font.Style + [fsItalic];

    GroupText := Arrow + '  ' + ItemData^.GroupName + '  (' + IntToStr(ItemCount) + ')';
    LV.Canvas.Brush.Style := bsClear;
    LV.Canvas.TextOut(R.Left + 6,
      R.Top + (R.Bottom - R.Top - LV.Canvas.TextHeight(GroupText)) div 2,
      GroupText);
  end
  else
  begin
    IsSelected := cdsSelected in State;

    if IsSelected then
    begin
      if LV.Focused then
        LV.Canvas.Brush.Color := clHighlight
      else
        LV.Canvas.Brush.Color := clBtnFace;
    end
    else
      LV.Canvas.Brush.Color := LV.Color;

    LV.Canvas.FillRect(R);

    R1 := R;
    R1.Right := R1.Left + LV.Columns[0].Width;
    LV.Canvas.Font.Name := LV.Font.Name;
    LV.Canvas.Font.Size := LV.Font.Size;
    LV.Canvas.Font.Style := [];

    if IsSelected and LV.Focused then
      LV.Canvas.Font.Color := clHighlightText
    else
      LV.Canvas.Font.Color := clGray;

    LV.Canvas.Brush.Style := bsClear;
    DrawText(LV.Canvas.Handle, PChar(Item.Caption), Length(Item.Caption),
      R1, DT_SINGLELINE or DT_VCENTER or DT_RIGHT or DT_END_ELLIPSIS);

    R2 := R;
    R2.Left := R.Left + LV.Columns[0].Width + 6;

    if IsSelected and LV.Focused then
      LV.Canvas.Font.Color := clHighlightText
    else
      LV.Canvas.Font.Color := clWindowText;

    if Item.SubItems.Count > 0 then
      DrawText(LV.Canvas.Handle, PChar(Item.SubItems[0]), Length(Item.SubItems[0]),
        R2, DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);

    if IsSelected and LV.Focused then
    begin
      LV.Canvas.Brush.Style := bsClear;
      LV.Canvas.DrawFocusRect(R);
    end;
  end;
end;

procedure TCommentNavFrame.lvCommentsAdvancedCustomDrawSubItem(
  Sender: TCustomListView; Item: TListItem; SubItem: Integer;
  State: TCustomDrawState; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
  DefaultDraw := False;
end;

{ --------------------------------------------------------------------------- }
{  TCommentNavFrame — Group state management                                   }
{ --------------------------------------------------------------------------- }

function TCommentNavFrame.FindGroupState(const AName: string): TGroupState;
var
  i: Integer;
begin
  for i := 0 to FGroupStates.Count - 1 do
  begin
    Result := TGroupState(FGroupStates[i]);
    if SameText(Result.GroupName, AName) then
      Exit;
  end;
  Result := nil;
end;

function TCommentNavFrame.GetOrCreateGroupState(const AName: string): TGroupState;
begin
  Result := FindGroupState(AName);
  if Result = nil then
  begin
    Result := TGroupState.Create(AName, False);
    FGroupStates.Add(Result);
  end;
end;

procedure TCommentNavFrame.ToggleGroup(const AName: string);
var
  GS: TGroupState;
begin
  GS := GetOrCreateGroupState(AName);
  GS.Collapsed := not GS.Collapsed;
  ApplyFilter;
end;

procedure TCommentNavFrame.SetAllGroupsCollapsed(ACollapsed: Boolean);
var
  i: Integer;
begin
  for i := 0 to FGroupStates.Count - 1 do
    TGroupState(FGroupStates[i]).Collapsed := ACollapsed;
  ApplyFilter;
end;

procedure TCommentNavFrame.ClearGroupStates;
var
  i: Integer;
begin
  for i := 0 to FGroupStates.Count - 1 do
    TGroupState(FGroupStates[i]).Free;
  FGroupStates.Clear;
end;

{ --------------------------------------------------------------------------- }
{  TCommentNavFrame — Constructor / Destructor                                 }
{ --------------------------------------------------------------------------- }

constructor TCommentNavFrame.Create(AOwner: TComponent);
begin
  inherited;
  FComments := TList.Create;
  FListItemDatas := TList.Create;
  FGroupStates := TList.Create;
  FCurrentFile := '';
  FSearchText := '';
  FGroupsEnabled := False;

  // Загружаем сохранённые режимы
  FSortMode := TSortMode(CommentNavSettings.SortModeIndex);
  FSortDirection := TSortDirection(CommentNavSettings.SortDirectionIndex);
  FScanMode := TScanMode(CommentNavSettings.ScanModeIndex);

  UpdateSortButtons;

  cbScanMode.Items.Clear;
  cbScanMode.Items.Add('// Rules');
  cbScanMode.Items.Add('{ } Rules');
  cbScanMode.Items.Add('All //');
  cbScanMode.Items.Add('All { }');
  cbScanMode.Items.Add('All');
  cbScanMode.ItemIndex := CommentNavSettings.ScanModeIndex;

  FOriginalWndProc := lvComments.WindowProc;
  lvComments.WindowProc := lvWndProc;
  lvComments.DoubleBuffered := True;
  lvComments.OnCustomDrawItem := lvCommentsCustomDrawItem;
  lvComments.OnAdvancedCustomDrawSubItem := lvCommentsAdvancedCustomDrawSubItem;
  lvComments.OnClick := lvCommentsClick;
  lvComments.OwnerDraw := False;
  lvComments.Font.Color := clWindowText;
  lvComments.Font.Name := 'Segoe UI';
  lvComments.Font.Size := 10;
  lvComments.ViewStyle := vsReport;

  if lvComments.Columns.Count >= 2 then
  begin
    lvComments.Columns[0].Width := 50;
    lvComments.Columns[0].MinWidth := 50;
  end;

  RegisterKeyBinding;
  // Отложенное сканирование текущего файла IDE
  PostMessage(Self.Handle, WM_USER + 100, 0, 0);
end;



destructor TCommentNavFrame.Destroy;
begin
  if Assigned(FOriginalWndProc) then
    lvComments.WindowProc := FOriginalWndProc;

  ClearComments;
  ClearGroupStates;
  FGroupStates.Free;
  FListItemDatas.Free;
  FComments.Free;

  UnregisterKeyBinding;
  inherited;
end;

procedure TCommentNavFrame.lvWndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_ERASEBKGND:
      Message.Result := 1;
  else
    FOriginalWndProc(Message);
  end;
end;

procedure TCommentNavFrame.AfterConstruction;
begin
  inherited;
  lvComments.DoubleBuffered := True;
  lvComments.OnResize := lvCommentsResize;
end;

procedure TCommentNavFrame.ClearListItemDatas;
var
  i: Integer;
begin
  for i := 0 to FListItemDatas.Count - 1 do
    Dispose(PListItemData(FListItemDatas[i]));
  FListItemDatas.Clear;
end;

procedure TCommentNavFrame.ClearComments;
var
  i: Integer;
begin
  for i := 0 to FComments.Count - 1 do
    Dispose(PCommentInfo(FComments[i]));
  FComments.Clear;
  ClearListItemDatas;
  lvComments.Items.Clear;
  UpdateInfoLabel;
end;

procedure TCommentNavFrame.UpdateInfoLabel;
begin
  if FCurrentFile <> '' then
    lblInfo.Caption := Format('  %d items  |  %s',
      [FComments.Count, ExtractFileName(FCurrentFile)])
  else
    lblInfo.Caption := Format('  %d items', [FComments.Count]);
end;

procedure TCommentNavFrame.ParseGroupAndText(const AText: string;
  out AGroup, ADisplay: string);
var
  ColonPos, i: Integer;
  Prefix: string;
  IsValidPrefix: Boolean;
begin
  ColonPos := Pos(':', AText);
  if (ColonPos >= 2) and (ColonPos <= 20) then
  begin
    Prefix := Trim(Copy(AText, 1, ColonPos - 1));
    IsValidPrefix := Prefix <> '';
    if IsValidPrefix then
    begin
      for i := 1 to Length(Prefix) do
      begin
        if not CharInSet(Prefix[i], ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
        begin
          IsValidPrefix := False;
          Break;
        end;
      end;
    end;
    if IsValidPrefix then
    begin
      AGroup := UpperCase(Prefix);
      ADisplay := Trim(Copy(AText, ColonPos + 1, MaxInt));
      if ADisplay = '' then
        ADisplay := AText;
      Exit;
    end;
  end;
  AGroup := '';
  ADisplay := AText;
end;

procedure TCommentNavFrame.edtSearchChange(Sender: TObject);
begin
  FSearchText := AnsiLowerCase(Trim(edtSearch.Text));
  ApplyFilter;
end;

{ --------------------------------------------------------------------------- }
{  ApplyFilter                                                                 }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.ApplyFilter;
var
  i, j: Integer;
  Info: PCommentInfo;
  ListItem: TListItem;
  VisibleCount: Integer;
  Groups: TStringList;
  CurrentGroup: string;
  ItemData: PListItemData;
  HasOther: Boolean;

  procedure AddGroupHeader(const AGroupName: string);
  begin
    GetOrCreateGroupState(AGroupName);
    New(ItemData);
    ItemData^.Kind := likGroupHeader;
    ItemData^.CommentInfo := nil;
    ItemData^.GroupName := AGroupName;
    FListItemDatas.Add(ItemData);
    ListItem := lvComments.Items.Add;
    ListItem.Caption := '';
    ListItem.SubItems.Add('');
    ListItem.Data := ItemData;
  end;

  procedure AddCommentItem(AInfo: PCommentInfo);
  begin
    New(ItemData);
    ItemData^.Kind := likComment;
    ItemData^.CommentInfo := AInfo;
    ItemData^.GroupName := '';
    FListItemDatas.Add(ItemData);
    ListItem := lvComments.Items.Add;
    ListItem.Caption := IntToStr(AInfo^.LineNumber + 1);
    ListItem.SubItems.Add(AInfo^.DisplayText);
    ListItem.Data := ItemData;
    Inc(VisibleCount);
  end;

  function IsGroupCollapsed(const AName: string): Boolean;
  var
    G: TGroupState;
  begin
    G := FindGroupState(AName);
    Result := (G <> nil) and G.Collapsed;
  end;

begin
  SendMessage(lvComments.Handle, WM_SETREDRAW, WPARAM(False), 0);
  try
    lvComments.Items.BeginUpdate;
    try
      lvComments.Items.Clear;
      ClearListItemDatas;
      VisibleCount := 0;

      if FGroupsEnabled then
      begin
        Groups := TStringList.Create;
        try
          Groups.Sorted := True;
          Groups.Duplicates := dupIgnore;

          for i := 0 to FComments.Count - 1 do
          begin
            Info := PCommentInfo(FComments[i]);
            if (FSearchText = '') or
               (Pos(FSearchText, AnsiLowerCase(Info^.CommentText)) > 0) then
            begin
              if Info^.GroupName <> '' then
                Groups.Add(Info^.GroupName);
            end;
          end;

          if Groups.Count > 0 then
          begin
            for i := 0 to Groups.Count - 1 do
            begin
              CurrentGroup := Groups[i];
              AddGroupHeader(CurrentGroup);
              if not IsGroupCollapsed(CurrentGroup) then
              begin
                for j := 0 to FComments.Count - 1 do
                begin
                  Info := PCommentInfo(FComments[j]);
                  if Info^.GroupName <> CurrentGroup then Continue;
                  if (FSearchText <> '') and
                     (Pos(FSearchText, AnsiLowerCase(Info^.CommentText)) = 0) then Continue;
                  AddCommentItem(Info);
                end;
              end;
            end;

            HasOther := False;
            for i := 0 to FComments.Count - 1 do
            begin
              Info := PCommentInfo(FComments[i]);
              if Info^.GroupName <> '' then Continue;
              if (FSearchText <> '') and
                 (Pos(FSearchText, AnsiLowerCase(Info^.CommentText)) = 0) then Continue;
              if not HasOther then
              begin
                AddGroupHeader('(Other)');
                HasOther := True;
              end;
              if not IsGroupCollapsed('(Other)') then
                AddCommentItem(Info);
            end;
          end
          else
          begin
            for i := 0 to FComments.Count - 1 do
            begin
              Info := PCommentInfo(FComments[i]);
              if (FSearchText = '') or
                 (Pos(FSearchText, AnsiLowerCase(Info^.CommentText)) > 0) then
                AddCommentItem(Info);
            end;
          end;
        finally
          Groups.Free;
        end;
      end
      else
      begin
        for i := 0 to FComments.Count - 1 do
        begin
          Info := PCommentInfo(FComments[i]);
          if (FSearchText = '') or
             (Pos(FSearchText, AnsiLowerCase(Info^.CommentText)) > 0) then
            AddCommentItem(Info);
        end;
      end;
    finally
      lvComments.Items.EndUpdate;
    end;
  finally
    SendMessage(lvComments.Handle, WM_SETREDRAW, WPARAM(True), 0);
    RedrawWindow(lvComments.Handle, nil, 0,
      RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
  end;

  if FSearchText <> '' then
  begin
    if FCurrentFile <> '' then
      lblInfo.Caption := Format('  %d / %d items  |  %s',
        [VisibleCount, FComments.Count, ExtractFileName(FCurrentFile)])
    else
      lblInfo.Caption := Format('  %d / %d items',
        [VisibleCount, FComments.Count]);
  end
  else
    UpdateInfoLabel;

  lvCommentsResize(lvComments);
end;

{ --------------------------------------------------------------------------- }
{  Sort buttons                                                                }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.UpdateSortButtons;
const
  ARROW_UP = ' '#$25B2;
  ARROW_DOWN = ' '#$25BC;
begin
  if FSortMode = smByLine then
  begin
    if FSortDirection = sdAscending then
      btnSortByLine.Caption := 'Line' + ARROW_UP
    else
      btnSortByLine.Caption := 'Line' + ARROW_DOWN;
    btnSortByComment.Caption := 'A-Z';
    btnSortByLine.Font.Style := [fsBold];
    btnSortByComment.Font.Style := [];
  end
  else
  begin
    btnSortByLine.Caption := 'Line';
    if FSortDirection = sdAscending then
      btnSortByComment.Caption := 'A-Z' + ARROW_UP
    else
      btnSortByComment.Caption := 'A-Z' + ARROW_DOWN;
    btnSortByLine.Font.Style := [];
    btnSortByComment.Font.Style := [fsBold];
  end;
end;

{ --------------------------------------------------------------------------- }
{  Comment extraction helpers                                                  }
{ --------------------------------------------------------------------------- }
function TCommentNavFrame.IsSlashSeparatorLine(const ALine: string): Boolean;
var
  Trimmed: string;
  i, SepCount: Integer;
const
  PREFIX = '//';
begin
  Result := False;
  Trimmed := Trim(ALine);
  if Length(Trimmed) < Length(PREFIX) then Exit;
  if Copy(Trimmed, 1, Length(PREFIX)) <> PREFIX then Exit;
  SepCount := 0;
  for i := Length(PREFIX) + 1 to Length(Trimmed) do
  begin
    if Trimmed[i] = CommentNavSettings.SeparatorChar then
      Inc(SepCount)
    else if Trimmed[i] <> ' ' then
      Exit;
  end;
  Result := SepCount >= CommentNavSettings.MinSeparatorLen;
end;



function TCommentNavFrame.IsBraceSeparatorLine(const ALine: string): Boolean;
var
  Trimmed, Inner: string;
  L, i, SepCount: Integer;
begin
  Result := False;
  Trimmed := Trim(ALine);
  L := Length(Trimmed);
  if (L < 2) or (Trimmed[1] <> '{') or (Trimmed[L] <> '}') then Exit;
  if (L >= 3) and (Trimmed[2] = '$') then Exit;
  Inner := Copy(Trimmed, 2, L - 2);
  SepCount := 0;
  for i := 1 to Length(Inner) do
  begin
    if Inner[i] = CommentNavSettings.SeparatorChar then
      Inc(SepCount)
    else if Inner[i] <> ' ' then
      Exit;
  end;
  Result := SepCount >= CommentNavSettings.MinSeparatorLen;
end;


function TCommentNavFrame.ExtractSlashComment(const ALine: string): string;
var
  Trimmed: string;
const
  PREFIX = '//';
begin
  Result := '';
  Trimmed := Trim(ALine);
  if Pos(PREFIX, Trimmed) = 1 then
    Result := Trim(Copy(Trimmed, Length(PREFIX) + 1, MaxInt));
end;


function TCommentNavFrame.ExtractBraceComment(const ALine: string): string;
var
  Trimmed: string;
  L: Integer;
begin
  Result := '';
  Trimmed := Trim(ALine);
  L := Length(Trimmed);
  if (L >= 2) and (Trimmed[1] = '{') and (Trimmed[L] = '}') then
  begin
    if (L >= 3) and (Trimmed[2] = '$') then
      Exit;
    Result := Trim(Copy(Trimmed, 2, L - 2));
  end;
end;

{ --------------------------------------------------------------------------- }
{  Scanning                                                                    }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.ScanCurrentModule;
var
  Lines: TStrings;
  FileName: string;
begin
  Lines := GetCurrentModuleText(FileName);
  if Lines = nil then Exit;
  try
    ScanLines(FileName, Lines);
  finally
    Lines.Free;
  end;
end;

procedure TCommentNavFrame.ScanLines(const AFileName: string; ALines: TStrings);
var
  i: Integer;
  CommentText: string;
  Info: PCommentInfo;
  BlockLines: TList;
  BlockInfo: PCommentInfo;
  NeedOpen, NeedClose: Boolean;
  UseSlash, UseBrace: Boolean;

  procedure FreeBlockLines;
  begin
    while BlockLines.Count > 0 do
    begin
      Dispose(PCommentInfo(BlockLines[0]));
      BlockLines.Delete(0);
    end;
  end;

  procedure AcceptBlockLines;
  begin
    while BlockLines.Count > 0 do
    begin
      FComments.Add(BlockLines[0]);
      BlockLines.Delete(0);
    end;
  end;

  function IsCurrentSeparator(const ALine: string): Boolean;
  begin
    Result := False;
    if UseSlash then
      Result := IsSlashSeparatorLine(ALine);
    if (not Result) and UseBrace then
      Result := IsBraceSeparatorLine(ALine);
  end;

  function ExtractCurrentComment(const ALine: string): string;
  begin
    Result := '';
    if UseSlash then
      Result := ExtractSlashComment(ALine);
    if (Result = '') and UseBrace then
      Result := ExtractBraceComment(ALine);
  end;

  procedure CollectCommentLine(ALineIndex: Integer);
  begin
    CommentText := ExtractCurrentComment(ALines[ALineIndex]);
    if CommentText <> '' then
    begin
      New(BlockInfo);
      BlockInfo^.LineNumber := ALineIndex;
      BlockInfo^.CommentText := CommentText;
      BlockInfo^.FileName := AFileName;
      ParseGroupAndText(CommentText, BlockInfo^.GroupName, BlockInfo^.DisplayText);
      BlockLines.Add(BlockInfo);
    end;
  end;

  procedure AddSingleComment(ALineIndex: Integer; const AText: string);
  begin
    New(Info);
    Info^.LineNumber := ALineIndex;
    Info^.CommentText := AText;
    Info^.FileName := AFileName;
    ParseGroupAndText(AText, Info^.GroupName, Info^.DisplayText);
    FComments.Add(Info);
  end;

begin
  ClearComments;

  FCurrentFile := AFileName;
  FGroupsEnabled := FScanMode in [scmRulesSlash, scmRulesBrace];

  case FScanMode of
    scmRulesSlash:
    begin
      UseSlash := True;
      UseBrace := False;
      NeedOpen := CommentNavSettings.RequireOpenSeparator;
      NeedClose := CommentNavSettings.RequireCloseSeparator;
    end;
    scmRulesBrace:
    begin
      UseSlash := False;
      UseBrace := True;
      NeedOpen := CommentNavSettings.RequireOpenSeparator;
      NeedClose := CommentNavSettings.RequireCloseSeparator;
    end;
    scmAllSlash:
    begin
      UseSlash := True;
      UseBrace := False;
      NeedOpen := False;
      NeedClose := False;
      FGroupsEnabled := False;
    end;
    scmAllBrace:
    begin
      UseSlash := False;
      UseBrace := True;
      NeedOpen := False;
      NeedClose := False;
      FGroupsEnabled := False;
    end;
    scmAll:
    begin
      UseSlash := True;
      UseBrace := True;
      NeedOpen := False;
      NeedClose := False;
      FGroupsEnabled := False;
    end;
  else
    UseSlash := True;
    UseBrace := False;
    NeedOpen := True;
    NeedClose := True;
  end;

  BlockLines := TList.Create;
  try
    if NeedOpen and NeedClose then
    begin
      i := 0;
      while i < ALines.Count do
      begin
        if IsCurrentSeparator(ALines[i]) then
        begin
          Inc(i);
          BlockLines.Clear;
          while (i < ALines.Count) and (not IsCurrentSeparator(ALines[i])) do
          begin
            CollectCommentLine(i);
            Inc(i);
          end;
          if (i < ALines.Count) and IsCurrentSeparator(ALines[i]) then
          begin
            AcceptBlockLines;
            Inc(i);
          end
          else
            FreeBlockLines;
        end
        else
          Inc(i);
      end;
    end
    else if NeedOpen and (not NeedClose) then
    begin
      i := 0;
      while i < ALines.Count do
      begin
        if IsCurrentSeparator(ALines[i]) then
        begin
          Inc(i);
          while (i < ALines.Count) and (not IsCurrentSeparator(ALines[i])) do
          begin
            CommentText := ExtractCurrentComment(ALines[i]);
            if CommentText <> '' then
              AddSingleComment(i, CommentText)
            else
              Break;
            Inc(i);
          end;
        end
        else
          Inc(i);
      end;
    end
    else if (not NeedOpen) and NeedClose then
    begin
      i := 0;
      while i < ALines.Count do
      begin
        CommentText := ExtractCurrentComment(ALines[i]);
        if (CommentText <> '') and (not IsCurrentSeparator(ALines[i])) then
        begin
          BlockLines.Clear;
          while (i < ALines.Count) do
          begin
            if IsCurrentSeparator(ALines[i]) then
            begin
              AcceptBlockLines;
              Inc(i);
              Break;
            end;
            CollectCommentLine(i);
            Inc(i);
          end;
          if BlockLines.Count > 0 then
            FreeBlockLines;
        end
        else
          Inc(i);
      end;
    end
    else
    begin
      for i := 0 to ALines.Count - 1 do
      begin
        if IsCurrentSeparator(ALines[i]) then
          Continue;
        CommentText := ExtractCurrentComment(ALines[i]);
        if CommentText <> '' then
          AddSingleComment(i, CommentText);
      end;
    end;
  finally
    FreeBlockLines;
    BlockLines.Free;
  end;

  GSortMode := FSortMode;
  GSortDirection := FSortDirection;
  if FComments.Count > 0 then
    FComments.Sort(@CompareComments);

  ApplyFilter;
end;

procedure TCommentNavFrame.ScanCurrentEditorBuffer;
var
  Lines: TStrings;
  FileName: string;
begin
  Lines := GetCurrentModuleText(FileName);
  if Lines = nil then Exit;
  try
    if FileName = '' then
      FileName := FCurrentFile;
    ScanLines(FileName, Lines);
  finally
    Lines.Free;
  end;
end;

{ --------------------------------------------------------------------------- }
{  Sort                                                                        }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.DoSort(AMode: TSortMode);
begin
  if FSortMode = AMode then
  begin
    if FSortDirection = sdAscending then
      FSortDirection := sdDescending
    else
      FSortDirection := sdAscending;
  end
  else
  begin
    FSortMode := AMode;
    FSortDirection := sdAscending;
  end;

  GSortMode := FSortMode;
  GSortDirection := FSortDirection;
  if FComments.Count > 0 then
    FComments.Sort(@CompareComments);

  // Сохраняем в настройки
  CommentNavSettings.SortModeIndex := Ord(FSortMode);
  CommentNavSettings.SortDirectionIndex := Ord(FSortDirection);
  CommentNavSettings.SaveSettings;

  UpdateSortButtons;
  ApplyFilter;
end;


{ --------------------------------------------------------------------------- }
{  Navigation                                                                  }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.GoToSelectedComment;
var
  Item: TListItem;
  ItemData: PListItemData;
begin
  Item := lvComments.Selected;
  if Item = nil then Exit;
  if Item.Data = nil then Exit;
  ItemData := PListItemData(Item.Data);

  if ItemData^.Kind = likGroupHeader then
  begin
    ToggleGroup(ItemData^.GroupName);
    Exit;
  end;

  if ItemData^.CommentInfo <> nil then
    GotoEditorLine(ItemData^.CommentInfo^.LineNumber, ItemData^.CommentInfo^.FileName);
end;

{ --------------------------------------------------------------------------- }
{  File activation                                                             }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.OnFileActivated(const AFileName: string);
var
  Ext: string;
begin
  if AFileName = '' then Exit;
  Ext := AnsiLowerCase(ExtractFileExt(AFileName));
  if (Ext <> '.pas') and (Ext <> '.dpr') and (Ext <> '.dpk') and (Ext <> '.inc') then
    Exit;
  if SameText(AFileName, FCurrentFile) then Exit;
  FCurrentFile := AFileName;
  ScanCurrentModule;
end;

{ --------------------------------------------------------------------------- }
{  Settings                                                                    }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.ShowSettings;
var
  Frm: TfrmCommentNavSettings;
begin
  Frm := TfrmCommentNavSettings.Create(nil);
  try
    Frm.Settings := CommentNavSettings;
    if Frm.ShowModal = mrOk then
      ScanCurrentModule;
  finally
    Frm.Free;
  end;
end;



{ --------------------------------------------------------------------------- }
{  Event handlers                                                              }
{ --------------------------------------------------------------------------- }

procedure TCommentNavFrame.btnScanClick(Sender: TObject);
begin
  ScanCurrentModule;
end;

procedure TCommentNavFrame.btnSettingsClick(Sender: TObject);
begin
  ShowSettings;
end;

procedure TCommentNavFrame.btnSortByLineClick(Sender: TObject);
begin
  DoSort(smByLine);
end;

procedure TCommentNavFrame.btnSortByCommentClick(Sender: TObject);
begin
  DoSort(smByComment);
end;

procedure TCommentNavFrame.cbScanModeChange(Sender: TObject);
begin
  case cbScanMode.ItemIndex of
    0: FScanMode := scmRulesSlash;
    1: FScanMode := scmRulesBrace;
    2: FScanMode := scmAllSlash;
    3: FScanMode := scmAllBrace;
    4: FScanMode := scmAll;
  end;
  CommentNavSettings.ScanModeIndex := cbScanMode.ItemIndex;
  CommentNavSettings.SaveSettings;
  ScanCurrentModule;
end;

procedure TCommentNavFrame.WMInitScan(var Msg: TMessage);
var
  Lines: TStrings;
  FileName: string;
begin
  Lines := GetCurrentModuleText(FileName);
  if Lines <> nil then
  begin
    try
      ScanLines(FileName, Lines);
    finally
      Lines.Free;
    end;
  end;
end;



procedure TCommentNavFrame.lvCommentsDblClick(Sender: TObject);
begin
  GoToSelectedComment;
end;

procedure TCommentNavFrame.lvCommentsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    GoToSelectedComment;
end;

procedure TCommentNavFrame.lvCommentsClick(Sender: TObject);
var
  Item: TListItem;
  ItemData: PListItemData;
begin
  Item := lvComments.Selected;
  if Item = nil then Exit;
  if Item.Data = nil then Exit;
  ItemData := PListItemData(Item.Data);
  if ItemData^.Kind = likGroupHeader then
    ToggleGroup(ItemData^.GroupName);
end;

procedure TCommentNavFrame.miGoToClick(Sender: TObject);
begin
  GoToSelectedComment;
end;

procedure TCommentNavFrame.miCollapseAllClick(Sender: TObject);
begin
  SetAllGroupsCollapsed(True);
end;

procedure TCommentNavFrame.miExpandAllClick(Sender: TObject);
begin
  SetAllGroupsCollapsed(False);
end;

procedure TCommentNavFrame.lvCommentsResize(Sender: TObject);
var
  TotalWidth, Col0Width: Integer;
const
  LINE_COL_WIDTH = 50;
begin
  if lvComments.Columns.Count < 2 then Exit;
  TotalWidth := lvComments.ClientWidth;
  Col0Width := lvComments.Columns[0].Width;
  if Col0Width < LINE_COL_WIDTH then
  begin
    lvComments.Columns[0].Width := LINE_COL_WIDTH;
    Col0Width := LINE_COL_WIDTH;
  end;
  lvComments.Columns[1].Width := TotalWidth - Col0Width;
end;

end.

