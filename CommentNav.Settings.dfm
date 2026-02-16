object frmCommentNavSettings: TfrmCommentNavSettings
  Left = 0
  Top = 0
  Margins.Left = 4
  Margins.Top = 4
  Margins.Right = 4
  Margins.Bottom = 4
  BorderStyle = bsDialog
  Caption = 'Comment Navigator - Settings'
  ClientHeight = 573
  ClientWidth = 567
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 21
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 567
    Height = 518
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object grpPattern: TGroupBox
      AlignWithMargins = True
      Left = 8
      Top = 4
      Width = 551
      Height = 213
      Margins.Left = 8
      Margins.Top = 4
      Margins.Right = 8
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Separator rules '
      TabOrder = 0
      object lblSepChar: TLabel
        Left = 94
        Top = 35
        Width = 105
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Separator char:'
      end
      object lblMinLen: TLabel
        Left = 51
        Top = 80
        Width = 148
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Min separator length:'
      end
      object lblSepWidth: TLabel
        Left = 85
        Top = 125
        Width = 114
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Separator width:'
      end
      object lblPreview: TLabel
        Left = 315
        Top = 31
        Width = 70
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Preview:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object edtSepChar: TEdit
        Left = 213
        Top = 31
        Width = 87
        Height = 29
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        MaxLength = 1
        TabOrder = 0
        Text = '='
        OnChange = edtSepCharChange
      end
      object seMinLen: TSpinEdit
        Left = 213
        Top = 76
        Width = 87
        Height = 32
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        MaxValue = 100
        MinValue = 3
        TabOrder = 1
        Value = 10
        OnChange = seMinLenChange
      end
      object seSepWidth: TSpinEdit
        Left = 213
        Top = 120
        Width = 87
        Height = 32
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        MaxValue = 120
        MinValue = 20
        TabOrder = 2
        Value = 78
      end
      object chkRequireOpen: TCheckBox
        Left = 25
        Top = 170
        Width = 250
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Require opening separator'
        TabOrder = 3
        OnClick = chkRequireOpenClick
      end
      object chkRequireClose: TCheckBox
        Left = 300
        Top = 170
        Width = 250
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Require closing separator'
        TabOrder = 4
        OnClick = chkRequireCloseClick
      end
      object mmoPreview: TMemo
        Left = 315
        Top = 60
        Width = 219
        Height = 92
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        TabStop = False
        Color = clCream
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -14
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 5
      end
    end
    object grpBehavior: TGroupBox
      AlignWithMargins = True
      Left = 8
      Top = 225
      Width = 551
      Height = 62
      Margins.Left = 8
      Margins.Top = 4
      Margins.Right = 8
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Behavior '
      TabOrder = 1
      object chkAutoLoad: TCheckBox
        Left = 25
        Top = 28
        Width = 375
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Auto-scan on module activate'
        TabOrder = 0
      end
    end
    object grpHotkey: TGroupBox
      AlignWithMargins = True
      Left = 8
      Top = 430
      Width = 551
      Height = 69
      Margins.Left = 8
      Margins.Top = 4
      Margins.Right = 8
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Insert comment hotkey '
      TabOrder = 2
      object lblHotkey: TLabel
        Left = 15
        Top = 30
        Width = 52
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Hotkey:'
      end
      object hkInsert: THotKey
        Left = 75
        Top = 26
        Width = 166
        Height = 29
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        HotKey = 49165
        Modifiers = [hkCtrl, hkAlt]
        TabOrder = 0
      end
      object chkInsertClassName: TCheckBox
        Left = 263
        Top = 28
        Width = 281
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Include class name  (TClass.Method)'
        TabOrder = 1
      end
    end
    object grpGroups: TGroupBox
      AlignWithMargins = True
      Left = 8
      Top = 295
      Width = 551
      Height = 127
      Margins.Left = 8
      Margins.Top = 4
      Margins.Right = 8
      Margins.Bottom = 4
      Align = alTop
      Caption = ' Group header style '
      TabOrder = 3
      object lblGroupFont: TLabel
        Left = 33
        Top = 35
        Width = 34
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Font:'
      end
      object lblGroupSize: TLabel
        Left = 325
        Top = 35
        Width = 31
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Size:'
      end
      object lblGroupColor: TLabel
        Left = 26
        Top = 86
        Width = 41
        Height = 21
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Caption = 'Color:'
      end
      object cbGroupFontName: TComboBox
        Left = 75
        Top = 31
        Width = 225
        Height = 29
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Style = csDropDownList
        TabOrder = 0
      end
      object seGroupFontSize: TSpinEdit
        Left = 369
        Top = 31
        Width = 75
        Height = 32
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        MaxValue = 36
        MinValue = 6
        TabOrder = 1
        Value = 11
      end
      object chkGroupBold: TCheckBox
        Left = 325
        Top = 84
        Width = 88
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Bold'
        TabOrder = 2
      end
      object chkGroupItalic: TCheckBox
        Left = 425
        Top = 84
        Width = 88
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Italic'
        TabOrder = 3
      end
      object cbGroupColor: TColorBox
        Left = 75
        Top = 83
        Width = 225
        Height = 26
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Style = [cbStandardColors, cbExtendedColors, cbCustomColor]
        ItemHeight = 20
        TabOrder = 4
      end
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 518
    Width = 567
    Height = 55
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TButton
      Left = 254
      Top = 8
      Width = 93
      Height = 35
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 360
      Top = 8
      Width = 93
      Height = 35
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
    object btnDefaults: TButton
      Left = 466
      Top = 8
      Width = 93
      Height = 35
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Defaults'
      TabOrder = 2
      OnClick = btnDefaultsClick
    end
  end
end
