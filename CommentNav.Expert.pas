{*******************************************************}
{                                                       }
{       Comment Navigator - Expert Registration         }
{                                                       }
{       IDE Expert entry point                          }
{                                                       }
{       Purpose:                                        }
{       - Register menu item under View                 }
{       - Create and show dockable panel                }
{       - Register keyboard binding                     }
{       - Register entry point for IDE                  }
{                                                       }
{       Author: Oleg Granishevsky & Claude 4.6 Opus	    }
{       Version: 1.0                                    }
{       License: MIT                                    }
{                                                       }
{*******************************************************}
 
unit CommentNav.Expert;

interface

uses
  ToolsAPI, Classes, SysUtils, Menus, Forms;

type
  TCommentNavigatorExpert = class(TNotifierObject, IOTAWizard, IOTAMenuWizard)
  private
    FMenuItem: TMenuItem;
    procedure MenuItemClick(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    function GetMenuText: string;
  end;

procedure Register;

implementation

uses
  CommentNav.DockForm,
  CommentNav.Settings;

constructor TCommentNavigatorExpert.Create;
var
  NTAServices: INTAServices;
  MainMenu: TMainMenu;
  ViewMenu: TMenuItem;
  i: Integer;
begin
  inherited Create;

  // Инициализируем настройки
  CommentNavSettings;

  // Регистрируем dockable форму и notifier
  RegisterCommentNavigatorForm;

  // Добавляем пункт меню View -> Comment Navigator
  if Supports(BorlandIDEServices, INTAServices, NTAServices) then
  begin
    MainMenu := NTAServices.MainMenu;
    ViewMenu := nil;
    for i := 0 to MainMenu.Items.Count - 1 do
    begin
      if SameText(MainMenu.Items[i].Name, 'ViewsMenu') then
      begin
        ViewMenu := MainMenu.Items[i];
        Break;
      end;
    end;

    if ViewMenu <> nil then
    begin
      FMenuItem := TMenuItem.Create(nil);
      FMenuItem.Caption := 'Comment Navigator';
      FMenuItem.OnClick := MenuItemClick;
      ViewMenu.Add(FMenuItem);
    end;
  end;
end;

destructor TCommentNavigatorExpert.Destroy;
begin
  FreeAndNil(FMenuItem);
  inherited;
end;

procedure TCommentNavigatorExpert.MenuItemClick(Sender: TObject);
begin
  ShowCommentNavigator;
end;

procedure TCommentNavigatorExpert.Execute;
begin
  ShowCommentNavigator;
end;

function TCommentNavigatorExpert.GetIDString: string;
begin
  Result := 'CommentNavigator.Expert';
end;

function TCommentNavigatorExpert.GetMenuText: string;
begin
  Result := 'Comment Navigator';
end;

function TCommentNavigatorExpert.GetName: string;
begin
  Result := 'Comment Navigator Expert';
end;

function TCommentNavigatorExpert.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure Register;
begin
  RegisterPackageWizard(TCommentNavigatorExpert.Create);
end;

end.
