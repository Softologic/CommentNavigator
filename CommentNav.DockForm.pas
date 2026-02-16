{*******************************************************}
{                                                       }
{       Comment Navigator - Dockable Form               }
{                                                       }
{       Dockable panel and IDE notifiers                }
{                                                       }
{       Purpose:                                        }
{       - INTACustomDockableForm implementation         }
{       - IOTAIDENotifier for file events               }
{       - Active file polling timer                     }
{       - Auto-scan on module switch                    }
{       - Editor modification detection                 }
{                                                       }
{       Author: Oleg Granishevskii & Claude 4.6 Opus	    }
{       Version: 1.0                                    }
{       License: MIT                                    }
{                                                       }
{*******************************************************}
 
unit CommentNav.DockForm;

interface

uses
  SysUtils, Classes, Controls, Forms, Menus, ActnList, ImgList,
  ComCtrls, IniFiles, ToolsAPI, DesignIntf, ExtCtrls,
  CommentNav.Frame;

type
  TCommentNavDockable = class(TInterfacedObject, INTACustomDockableForm)
  public
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    function GetIdentifier: string;
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    function GetToolBarActionList: TCustomActionList;
    function GetToolBarImageList: TCustomImageList;
    procedure CustomizePopupMenu(PopupMenu: TPopupMenu);
    procedure CustomizeToolBar(ToolBar: TToolBar);
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string; IsProject: Boolean);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
  end;

  TFileNotifier = class(TNotifierObject, IOTANotifier, IOTAIDENotifier)
  public
    procedure FileNotification(NotifyCode: TOTAFileNotification;
      const FileName: string; var Cancel: Boolean);
    procedure BeforeCompile(const Project: IOTAProject;
      var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
  end;

  TActiveFileChecker = class(TObject)
  private
    FTimer: TTimer;
    FLastFile: string;
    FWasModified: Boolean;
    procedure OnTimer(Sender: TObject);
    function GetCurrentActiveFile: string;
    function IsCurrentModuleModified: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  CommentNavFrame: TCommentNavFrame = nil;

procedure ShowCommentNavigator;
procedure RegisterCommentNavigatorForm;

implementation

uses
  CommentNav.Settings;

var
  FDockableForm: INTACustomDockableForm;
  FNotifierIndex: Integer = -1;
  FRegistered: Boolean = False;
  FActiveFileChecker: TActiveFileChecker = nil;

{ --------------------------------------------------------------------------- }
{  TActiveFileChecker                                                          }
{ --------------------------------------------------------------------------- }

constructor TActiveFileChecker.Create;
begin
  inherited Create;
  FLastFile := '';
  FWasModified := False;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 1000;
  FTimer.OnTimer := OnTimer;
  FTimer.Enabled := True;
end;

destructor TActiveFileChecker.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  inherited;
end;

function TActiveFileChecker.GetCurrentActiveFile: string;
var
  Module: IOTAModule;
  Editor: IOTASourceEditor;
  i: Integer;
begin
  Result := '';
  try
    Module := (BorlandIDEServices as IOTAModuleServices).CurrentModule;
    if Module = nil then Exit;

    for i := 0 to Module.ModuleFileCount - 1 do
    begin
      if Supports(Module.ModuleFileEditors[i], IOTASourceEditor, Editor) then
      begin
        Result := Editor.FileName;
        Break;
      end;
    end;
  except
    Result := '';
  end;
end;

function TActiveFileChecker.IsCurrentModuleModified: Boolean;
var
  Module: IOTAModule;
  Editor: IOTASourceEditor;
  i: Integer;
begin
  Result := False;
  try
    Module := (BorlandIDEServices as IOTAModuleServices).CurrentModule;
    if Module = nil then Exit;

    for i := 0 to Module.ModuleFileCount - 1 do
    begin
      if Supports(Module.ModuleFileEditors[i], IOTASourceEditor, Editor) then
      begin
        Result := Editor.Modified;
        Break;
      end;
    end;
  except
    Result := False;
  end;
end;

procedure TActiveFileChecker.OnTimer(Sender: TObject);
var
  CurrentFile: string;
  IsModified: Boolean;
begin
  if CommentNavFrame = nil then Exit;
  if not CommentNavSettings.AutoScanOnActivate then Exit;

  CurrentFile := GetCurrentActiveFile;
  if CurrentFile = '' then Exit;

  if not SameText(CurrentFile, FLastFile) then
  begin
    FLastFile := CurrentFile;
    FWasModified := False;
    CommentNavFrame.OnFileActivated(CurrentFile);
    Exit;
  end;

  IsModified := IsCurrentModuleModified;
  if IsModified and not FWasModified then
  begin
    FWasModified := True;
    CommentNavFrame.ScanCurrentEditorBuffer;
  end
  else if not IsModified and FWasModified then
  begin
    FWasModified := False;
    CommentNavFrame.ScanCurrentEditorBuffer;
  end;
end;

{ --------------------------------------------------------------------------- }
{  TCommentNavDockable                                                         }
{ --------------------------------------------------------------------------- }

function TCommentNavDockable.GetCaption: string;
begin
  Result := 'Comment Navigator';
end;

function TCommentNavDockable.GetFrameClass: TCustomFrameClass;
begin
  Result := TCommentNavFrame;
end;

procedure TCommentNavDockable.FrameCreated(AFrame: TCustomFrame);
begin
  CommentNavFrame := AFrame as TCommentNavFrame;

  if FActiveFileChecker = nil then
    FActiveFileChecker := TActiveFileChecker.Create;
end;

function TCommentNavDockable.GetIdentifier: string;
begin
  Result := 'CommentNavigator';
end;

function TCommentNavDockable.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TCommentNavDockable.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

function TCommentNavDockable.GetToolBarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TCommentNavDockable.GetToolBarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TCommentNavDockable.CustomizePopupMenu(PopupMenu: TPopupMenu);
begin
end;

procedure TCommentNavDockable.CustomizeToolBar(ToolBar: TToolBar);
begin
end;

procedure TCommentNavDockable.SaveWindowState(Desktop: TCustomIniFile;
  const Section: string; IsProject: Boolean);
begin
end;

procedure TCommentNavDockable.LoadWindowState(Desktop: TCustomIniFile;
  const Section: string);
begin
end;

function TCommentNavDockable.GetEditState: TEditState;
begin
  Result := [];
end;

function TCommentNavDockable.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

{ --------------------------------------------------------------------------- }
{  TFileNotifier                                                               }
{ --------------------------------------------------------------------------- }

procedure TFileNotifier.FileNotification(NotifyCode: TOTAFileNotification;
  const FileName: string; var Cancel: Boolean);
begin
  if NotifyCode = ofnFileOpened then
  begin
    if (CommentNavFrame <> nil) and CommentNavSettings.AutoScanOnActivate then
    begin
      TThread.Queue(nil,
        procedure
        begin
          if CommentNavFrame <> nil then
            CommentNavFrame.OnFileActivated(FileName);
        end);
    end;
  end;
end;

procedure TFileNotifier.BeforeCompile(const Project: IOTAProject;
  var Cancel: Boolean);
begin
end;

procedure TFileNotifier.AfterCompile(Succeeded: Boolean);
begin
end;

{ --------------------------------------------------------------------------- }
{  Global                                                                      }
{ --------------------------------------------------------------------------- }

procedure RegisterCommentNavigatorForm;
var
  Services: IOTAServices;
begin
  if FRegistered then Exit;
  FRegistered := True;

  FDockableForm := TCommentNavDockable.Create;
  (BorlandIDEServices as INTAServices).RegisterDockableForm(FDockableForm);

  if Supports(BorlandIDEServices, IOTAServices, Services) then
    FNotifierIndex := Services.AddNotifier(TFileNotifier.Create);
end;

procedure ShowCommentNavigator;
begin
  if not FRegistered then
    RegisterCommentNavigatorForm;

  (BorlandIDEServices as INTAServices).CreateDockableForm(FDockableForm);
end;

initialization

finalization
  FreeAndNil(FActiveFileChecker);

  if FNotifierIndex >= 0 then
  begin
    try
      (BorlandIDEServices as IOTAServices).RemoveNotifier(FNotifierIndex);
    except
    end;
    FNotifierIndex := -1;
  end;

  if FDockableForm <> nil then
  begin
    try
      (BorlandIDEServices as INTAServices).UnregisterDockableForm(FDockableForm);
    except
    end;
    FDockableForm := nil;
  end;

end.
