# Comment Navigator

**Delphi IDE Expert** for fast navigation through structured comment blocks in Pascal source code.

![Delphi](https://img.shields.io/badge/Delphi-2009%2B-red)
![License](https://img.shields.io/badge/License-MIT-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)

## Overview

Comment Navigator scans your Pascal source files for specially formatted comment blocks and displays them in a convenient dockable panel inside the Delphi IDE. It allows you to instantly jump to any section of your code, organize large units into logical groups, and insert standardized comment headers with a single hotkey.

### Comment Block Format

    //==============================================================================
    // InitializeDatabase
    //==============================================================================
    procedure TDataModule1.InitializeDatabase;
    begin
      // ...
    end;

    //==============================================================================
    // LoadConfiguration
    //==============================================================================
    procedure TDataModule1.LoadConfiguration;
    begin
      // ...
    end;

## Features

### Navigation
- **Dockable panel** integrated into Delphi IDE (View → Comment Navigator)
- **Click to navigate** — jump to any comment line in the editor
- **Real-time search** — filter comments as you type
- **Collapsible groups** — organize comments into logical sections

### Scanning Modes
- **Rules** — scan for structured comment blocks with configurable separators
- **All //** — scan all single-line comments
- **All {}** — scan all curly-brace comments

### Sorting
- By line number (original order)
- By comment text (alphabetical)
- By group name
- Ascending / descending direction

### Comment Insertion
- **One hotkey** (default: Ctrl+Alt+Enter) inserts a formatted comment block above the current method
- Automatically extracts method name from procedure, function, constructor, destructor
- Optional class name inclusion (TClassName.MethodName or just MethodName)
- Separator character and width are configurable
- Fully **undoable** (Ctrl+Z works)

### Auto-Scan
- Automatic rescan when switching between modules
- Detects editor modifications and refreshes the list
- Can be disabled in settings

### Customization
- Separator character (=, -, *, #, etc.)
- Minimum separator length for detection
- Separator width for inserted comments
- Require opening separator, closing separator, or both
- Group header font: name, size, bold, italic, color
- Hotkey is fully configurable

## Screenshots

*Coming soon*

## Requirements

- Delphi 2009 or later
- Windows
- ToolsAPI, DesignIntf (included with Delphi)

## Installation

1. Clone or download this repository
2. Open CommentNavigator.dpk in Delphi IDE
3. Right-click the project in Project Manager → **Compile** → **Install**
4. Access via menu: **View → Comment Navigator**

## Quick Start

1. Open any .pas, .dpr, .dpk, or .inc file
2. Open **View → Comment Navigator**
3. Add structured comments to your code:

        //==============================================================================
        // Section Name
        //==============================================================================

4. Comments appear in the navigator panel — click to jump
5. Place cursor on a procedure/function line and press Ctrl+Alt+Enter to auto-insert a comment header

## Project Structure

| File | Description |
|---|---|
| CommentNavigator.dpk | Design-time package |
| CommentNav.Expert.pas | Expert registration, menu item |
| CommentNav.DockForm.pas | Dockable form, IDE notifiers, file polling |
| CommentNav.Frame.pas | Main UI frame — ListView, scanning, navigation |
| CommentNav.Settings.pas | Settings manager, INI storage, settings dialog |
| CommentNav.InsertComment.pas | Hotkey binding, method name parser, comment inserter |

## Settings

Access settings via the **gear icon** on the Comment Navigator panel.

| Setting | Default | Description |
|---|---|---|
| Separator char | = | Character used in separator lines |
| Min separator length | 10 | Minimum length to recognize a separator |
| Separator width | 78 | Width of inserted separator lines |
| Require opening separator | Yes | Separator line required above comment |
| Require closing separator | Yes | Separator line required below comment |
| Auto-scan on activate | Yes | Rescan when switching modules |
| Insert hotkey | Ctrl+Alt+Enter | Hotkey for comment insertion |
| Include class name | Yes | Include TClass. prefix in inserted comments |
| Group font | Segoe UI, 11, Bold, Navy | Appearance of group headers |

## How It Works

### Scanning (Rules Mode)

The scanner looks for patterns like:

    // <separator line>    ← opening separator (configurable char, min length)
    // Comment text        ← one or more comment lines (captured)
    // <separator line>    ← closing separator

Lines are grouped by the text between separators. Groups are collapsible in the ListView.

### Comment Insertion

When you press Ctrl+Alt+Enter on a line like:

    procedure TMyForm.ButtonClick(Sender: TObject);

The expert inserts above it:

    //==============================================================================
    // TMyForm.ButtonClick
    //==============================================================================

The separator character, width, and class name inclusion are all taken from settings.

## Contributing

Contributions are welcome! Feel free to:

- Report bugs via [Issues](../../issues)
- Submit feature requests
- Open pull requests

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

**Oleg Granishevskii**

---

*If you find this project useful, please give it a ⭐ on GitHub!*
