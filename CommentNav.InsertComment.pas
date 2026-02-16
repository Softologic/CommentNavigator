{*******************************************************}
{                                                       }
{       Comment Navigator - Insert Comment              }
{                                                       }
{       Insert formatted comment block into source      }
{                                                       }
{       Purpose:                                        }
{       - Intercept hotkey via IOTAKeyboardBinding      }
{       - Parse method name from current line           }
{       - Build separator comment block                 }
{       - Insert via IOTAEditWriter (undoable)          }
{       - Respect settings: char, width, class name     }
{                                                       }
{       Author: Oleg Granishevsky & Claude 4.6 Opus	    }
{       Version: 1.0                                    }
{       License: MIT                                    }
{                                                       }
{*******************************************************}
 
unit CommentNav.InsertComment;

interface

uses
  SysUtils, Classes, ToolsAPI, Menus;

type
  TCommentInserter = class
  public
    class procedure InsertAtCursor;
    class function ExtractMethodName(const ALine: string): string;
    class function GetSeparatorChar: Char;
  end;

  TCommentKeyBinding = class(TNotifierObject, IOTAKeyboardBinding)
  private
    FBindingIndex: Integer;
  public
    { IOTAKeyboardBinding }
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
    procedure InsertCommentHandler(const Context: IOTAKeyContext;
      KeyCode: TShortCut; var BindingResult: TKeyBindingResult);
    property BindingIndex: Integer read FBindingIndex write FBindingIndex;
  end;

procedure RegisterKeyBinding;
procedure UnregisterKeyBinding;

implementation

uses
  Windows, CommentNav.Settings;

var
  FKeyBindingIndex: Integer = -1;

{ --------------------------------------------------------------------------- }
{  TCommentInserter                                                            }
{ --------------------------------------------------------------------------- }

class function TCommentInserter.GetSeparatorChar: Char;
begin
  // Берём из настроек SeparatorChar
  Result := CommentNavSettings.SeparatorChar;
end;

class function TCommentInserter.ExtractMethodName(const ALine: string): string;
var
  S: string;
  DotPos, EndPos: Integer;
  IncludeClass: Boolean;
begin
  Result := '';
  S := Trim(ALine);
  IncludeClass := CommentNavSettings.InsertClassName;

  // Убираем class prefix если есть
  if Copy(AnsiLowerCase(S), 1, 6) = 'class ' then
    Delete(S, 1, 6);

  // Определяем тип и убираем ключевое слово
  if Copy(AnsiLowerCase(S), 1, 10) = 'procedure ' then
    Delete(S, 1, 10)
  else if Copy(AnsiLowerCase(S), 1, 9) = 'function ' then
    Delete(S, 1, 9)
  else if Copy(AnsiLowerCase(S), 1, 12) = 'constructor ' then
    Delete(S, 1, 12)
  else if Copy(AnsiLowerCase(S), 1, 11) = 'destructor ' then
    Delete(S, 1, 11)
  else
    Exit;

  S := Trim(S);

  DotPos := Pos('.', S);
  if DotPos > 0 then
  begin
    if IncludeClass then
    begin
      // TClass.MethodName
      EndPos := DotPos + 1;
      while (EndPos <= Length(S)) and
            not CharInSet(S[EndPos], ['(', ':', ';', ' ']) do
        Inc(EndPos);
      Result := Trim(Copy(S, 1, EndPos - 1));
    end
    else
    begin
      // Только MethodName
      S := Copy(S, DotPos + 1, MaxInt);
      EndPos := 1;
      while (EndPos <= Length(S)) and
            not CharInSet(S[EndPos], ['(', ':', ';', ' ']) do
        Inc(EndPos);
      Result := Trim(Copy(S, 1, EndPos - 1));
    end;
  end
  else
  begin
    // Простая функция без класса
    EndPos := 1;
    while (EndPos <= Length(S)) and
          not CharInSet(S[EndPos], ['(', ':', ';', ' ']) do
      Inc(EndPos);
    Result := Trim(Copy(S, 1, EndPos - 1));
  end;
end;


class procedure TCommentInserter.InsertAtCursor;
var
  EditView: IOTAEditView;
  EditPos: TOTAEditPos;
  CharPos: TOTACharPos;
  Writer: IOTAEditWriter;
  LineText, MethodName, SepLine, Block, Indent: string;
  SepChar: Char;
  SepWidth: Integer;
  LineNum, InsertOffset, i: Integer;
  Buffer: IOTAEditBuffer;
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  SourceEditor: IOTASourceEditor;
begin
  // Получаем текущий редактор
  if not Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then Exit;
  Module := ModuleServices.CurrentModule;
  if Module = nil then Exit;

  SourceEditor := nil;
  for i := 0 to Module.GetModuleFileCount - 1 do
    if Supports(Module.GetModuleFileEditor(i), IOTASourceEditor, SourceEditor) then
      Break;
  if SourceEditor = nil then Exit;

  EditView := SourceEditor.EditViews[0];
  if EditView = nil then Exit;

  Buffer := EditView.Buffer;
  if Buffer = nil then Exit;

  // Получаем текущую позицию курсора
  EditPos := EditView.CursorPos;
  LineNum := EditPos.Line;

  // Читаем текст строки
  EditView.Position.Move(LineNum, 1);
  EditView.Position.MoveBOL;
  CharPos.Line := LineNum;
  CharPos.CharIndex := 0;

  // Получаем текст строки через Reader
  LineText := '';
  begin
    var Reader: IOTAEditReader;
    var LineBuf: AnsiString;
    var BytesRead: Integer;
    var LineOffset: Integer;

    Reader := SourceEditor.CreateReader;
    if Reader = nil then Exit;

    EditView.ConvertPos(True, EditPos, CharPos);

    // Находим начало строки — ищем от CharPos назад
    // Проще: читаем блок и парсим
    LineOffset := EditView.CharPosToPos(CharPos);

    // Читаем от начала строки
    CharPos.CharIndex := 0;
    LineOffset := EditView.CharPosToPos(CharPos);

    SetLength(LineBuf, 1024);
    BytesRead := Reader.GetText(LineOffset, PAnsiChar(LineBuf), 1024);
    if BytesRead > 0 then
    begin
      SetLength(LineBuf, BytesRead);
      // Берём до конца строки
      i := Pos(#13, string(LineBuf));
      if i = 0 then
        i := Pos(#10, string(LineBuf));
      if i > 0 then
        LineText := Copy(string(LineBuf), 1, i - 1)
      else
        LineText := string(LineBuf);
    end;
  end;

  // Извлекаем имя метода
  MethodName := ExtractMethodName(LineText);
  if MethodName = '' then Exit;

  // Определяем отступ
  Indent := '';
  for i := 1 to Length(LineText) do
  begin
    if LineText[i] = ' ' then
      Indent := Indent + ' '
    else if LineText[i] = #9 then
      Indent := Indent + #9
    else
      Break;
  end;

  // Формируем блок комментария
  SepChar := GetSeparatorChar;
  SepWidth := CommentNavSettings.SeparatorWidth;
  SepLine := '//' + StringOfChar(SepChar, SepWidth);

  Block := Indent + SepLine + #13#10 +
           Indent + '// ' + MethodName + #13#10 +
           Indent + SepLine + #13#10;

  // Вставляем перед текущей строкой
  CharPos.Line := LineNum;
  CharPos.CharIndex := 0;
  InsertOffset := EditView.CharPosToPos(CharPos);

  Writer := SourceEditor.CreateUndoableWriter;
  if Writer = nil then Exit;
  try
    Writer.CopyTo(InsertOffset);
    Writer.Insert(PAnsiChar(AnsiString(Block)));
  finally
    Writer := nil;
  end;

  // Восстанавливаем позицию курсора (сдвинулась на 3 строки вниз)
  EditPos.Line := LineNum + 3;
  EditView.CursorPos := EditPos;
  EditView.Paint;
end;

{ --------------------------------------------------------------------------- }
{  TCommentKeyBinding                                                          }
{ --------------------------------------------------------------------------- }

function TCommentKeyBinding.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TCommentKeyBinding.GetDisplayName: string;
begin
  Result := 'Comment Navigator Insert';
end;

function TCommentKeyBinding.GetName: string;
begin
  Result := 'CommentNav.InsertComment';
end;

procedure TCommentKeyBinding.BindKeyboard(
  const BindingServices: IOTAKeyBindingServices);
var
  HK: TShortCut;
begin
  HK := CommentNavSettings.InsertHotkey;
  if HK <> 0 then
    BindingServices.AddKeyBinding([HK], InsertCommentHandler, nil);
end;

procedure TCommentKeyBinding.InsertCommentHandler(
  const Context: IOTAKeyContext; KeyCode: TShortCut;
  var BindingResult: TKeyBindingResult);
begin
  TCommentInserter.InsertAtCursor;
  BindingResult := krHandled;
end;

{ --------------------------------------------------------------------------- }
{  Registration                                                                }
{ --------------------------------------------------------------------------- }

procedure RegisterKeyBinding;
var
  Services: IOTAKeyboardServices;
begin
  if not Supports(BorlandIDEServices, IOTAKeyboardServices, Services) then Exit;
  FKeyBindingIndex := Services.AddKeyboardBinding(TCommentKeyBinding.Create);
end;

procedure UnregisterKeyBinding;
var
  Services: IOTAKeyboardServices;
begin
  if FKeyBindingIndex < 0 then Exit;
  if not Supports(BorlandIDEServices, IOTAKeyboardServices, Services) then Exit;
  Services.RemoveKeyboardBinding(FKeyBindingIndex);
  FKeyBindingIndex := -1;
end;

initialization

finalization

end.
