object CommentNavFrame: TCommentNavFrame
  Left = 0
  Top = 0
  Width = 625
  Height = 781
  Margins.Left = 4
  Margins.Top = 4
  Margins.Right = 4
  Margins.Bottom = 4
  TabOrder = 0
  PixelsPerInch = 120
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 625
    Height = 48
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnScan: TButton
      AlignWithMargins = True
      Left = 127
      Top = 8
      Width = 79
      Height = 32
      Margins.Left = 5
      Margins.Top = 8
      Margins.Right = 5
      Margins.Bottom = 8
      Align = alLeft
      Caption = 'Scan'
      TabOrder = 0
      OnClick = btnScanClick
    end
    object cbScanMode: TComboBox
      AlignWithMargins = True
      Left = 5
      Top = 8
      Width = 112
      Height = 31
      Margins.Left = 5
      Margins.Top = 8
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alLeft
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -17
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnChange = cbScanModeChange
    end
    object btnSortByLine: TButton
      AlignWithMargins = True
      Left = 229
      Top = 8
      Width = 86
      Height = 32
      Margins.Left = 18
      Margins.Top = 8
      Margins.Right = 5
      Margins.Bottom = 8
      Align = alLeft
      Caption = 'Line'
      TabOrder = 2
      OnClick = btnSortByLineClick
    end
    object btnSortByComment: TButton
      AlignWithMargins = True
      Left = 325
      Top = 8
      Width = 86
      Height = 32
      Margins.Left = 5
      Margins.Top = 8
      Margins.Right = 5
      Margins.Bottom = 8
      Align = alLeft
      Caption = 'A-Z'
      TabOrder = 3
      OnClick = btnSortByCommentClick
    end
    object btnSettings: TButton
      AlignWithMargins = True
      Left = 528
      Top = 8
      Width = 92
      Height = 32
      Margins.Left = 5
      Margins.Top = 8
      Margins.Right = 5
      Margins.Bottom = 8
      Align = alRight
      Caption = 'Settings'
      TabOrder = 4
      OnClick = btnSettingsClick
    end
  end
  object pnlInfo: TPanel
    Left = 0
    Top = 48
    Width = 625
    Height = 46
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblInfo: TLabel
      AlignWithMargins = True
      Left = 5
      Top = 5
      Width = 48
      Height = 41
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Align = alLeft
      Caption = '0 items'
      ExplicitHeight = 20
    end
    object edtSearch: TEdit
      AlignWithMargins = True
      Left = 410
      Top = 5
      Width = 210
      Height = 36
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alRight
      TabOrder = 0
      OnChange = edtSearchChange
      ExplicitHeight = 28
    end
  end
  object lvComments: TListView
    Left = 0
    Top = 94
    Width = 625
    Height = 687
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alClient
    Columns = <
      item
        Caption = 'Line'
        Width = 63
      end
      item
        Caption = 'Comment'
        Width = 375
      end>
    ReadOnly = True
    RowSelect = True
    PopupMenu = pmMenu
    TabOrder = 2
    ViewStyle = vsReport
    OnDblClick = lvCommentsDblClick
    OnKeyDown = lvCommentsKeyDown
  end
  object pmMenu: TPopupMenu
    Left = 390
    Top = 180
    object miScan: TMenuItem
      Caption = 'Scan Module'
      OnClick = btnScanClick
    end
    object miSep1: TMenuItem
      Caption = '-'
    end
    object miGoTo: TMenuItem
      Caption = 'Go to Comment'
      OnClick = miGoToClick
    end
    object miSep2: TMenuItem
      Caption = '-'
    end
    object miSortByLine: TMenuItem
      Caption = 'Sort by Line'
      OnClick = btnSortByLineClick
    end
    object miSortByComment: TMenuItem
      Caption = 'Sort by Comment'
      OnClick = btnSortByCommentClick
    end
    object miSep3: TMenuItem
      Caption = '-'
    end
    object miCollapseAll: TMenuItem
      Caption = 'Collapse All Groups'
      OnClick = miCollapseAllClick
    end
    object miExpandAll: TMenuItem
      Caption = 'Expand All Groups'
      OnClick = miExpandAllClick
    end
    object miSep4: TMenuItem
      Caption = '-'
    end
    object miSettings: TMenuItem
      Caption = 'Settings...'
      OnClick = btnSettingsClick
    end
  end
end
