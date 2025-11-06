# Node Naming

This convention is motivated by the preferred way of accessing UI nodes from scripts, which is by **scene-unique names** using the `%` shorthand, for example: `%InstallBtn`, `%BuildsList`, `%UpdateSwitch`.

UI node names consist of the main part describing their function and a suffix loosely indicating what kind of element they are (but usually not the exact class).

## Suffix Reference

### Interactive Controls
- `Button` or `Btn` - Button, IconButton, etc.
- `Switch` - CheckBox, CheckBox in ButtonGroup (radio), CheckButton
- `List` - OptionButton, ItemList
- `Field` - LineEdit, SpinBox, TextEdit

### Display Elements
- `Label` - Label, short RichTextLabel (1-2 lines)
- `Text` or `Info` - Multi-line RichTextLabel (info blocks, logs)
- `Icon` - TextureRect, TextureButton used as icons

### Containers
- `Layout`, `Area`, `Group`, `Box` - Containers that group and arrange UI nodes (Panel, TabContainer, HBox/VBox, etc.). Use whichever reads best in context but prefer this order when going from higher to lower hierarchy levels: `Layout` → `Area` → `Group` → `Box`.
- `Panel` - Alternative for Panel/PanelContainer when semantically appropriate.

### Dialogs
- `Dialog` or `Dlg` - FileDialog, ConfirmationDialog, AcceptDialog, custom dialogs

## Guidelines

1. **Purpose over type** - Describe what it does, not what it is
   - ✓ `%RefreshBuildsBtn`, `%GamesList`
   - ✗ `%Button1`, `%OptionButton`

2. **Be specific in large scenes** - Names must be completely unique across the entire scene
   - ✓ `%DeleteModsBtn`, `%DeleteInstallBtn`, `%DeleteSoundBtn`, `%DeleteBackupBtn`
   - ✗ `%DeleteBtn` (ambiguous when all in same scene)

3. **Consistent suffixes** - Always use the same suffix for the same type
   - Buttons: `%PlayBtn`, `%RefreshBtn`, `%InstallBtn`
   - Switches: `%UpdateSwitch`, `%ShowStockSwitch`
   - Lists: `%BuildsList`, `%GamesList`

4. **Readable purpose** - Avoid abbreviations except well-known ones
   - ✓ `%ExperimentalSwitch`, `%NumReleasesField`
   - ✗ `%ExperSwitch`, `%NumRelsFld`

## Exceptions

- Nodes that serve a purely cosmetic purpose and aren't likely to ever be accessed from scripts (separators, spacers) do not have to follow this convention.