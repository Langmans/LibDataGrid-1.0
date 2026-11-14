Inherits: Frame, Region, ScriptRegion, Object, FrameScriptObject, ScriptRegionResizing, AnimatableObject, ScriptObject, [LibDataGridWidget](LibDataGridWidget.md)

## Fields

| Name | Type | Description |
|------|------|-------------|
| bar | `LibDataGridScrollBarMixin` |  |
| body | `Frame` |  |
| columns | `LibDataGridGridColumn[]` |  |
| count | `number` | how many pass |
| heads | `LibDataGridGridHead[]` |  |
| lines | `LibDataGridGridLine[]` |  |
| rows | `table \| number \| string[]` | every row, as the owner gave them |
| shown | `table \| number \| string[]` | the rows that pass, in order |
| skin | `LibDataGridSkinMixin` |  |
| view | `LibDataGridView` |  |

## Methods

### AddColumn

```lua
function LibDataGridGridMixin:AddColumn(entry)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `entry` | `LibDataGridGridColumn` |  |

### AddFillColumn

```lua
function LibDataGridGridMixin:AddFillColumn(key, weight)
```

A column sharing, by weight (1 when not given), what the fixed columns leave.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `key` | `string` |  |
| `weight` | `number?` |  |

### AddFixedWidthColumn

```lua
function LibDataGridGridMixin:AddFixedWidthColumn(key, width)
```

A column of this width.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `key` | `string` |  |
| `width` | `number` |  |

### Draw

```lua
function LibDataGridGridMixin:Draw()
```

Fills the lines from the scrolled offset, and the headers' sort markers.

### FindColumn

```lua
function LibDataGridGridMixin:FindColumn(key)
  -> LibDataGridColumnMixin
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `key` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridColumnMixin` |  |

### Layout

```lua
function LibDataGridGridMixin:Layout()
```

Places the headers and cells by the columns' widths, and makes as many lines as fit.

### NewCell

```lua
function LibDataGridGridMixin:NewCell(line, column)
  -> FontString
```

A text cell for a column without a renderer.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `line` | `LibDataGridGridLine` |  |
| `column` | `LibDataGridColumnMixin` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `FontString` |  |

### OnRowClick

```lua
function LibDataGridGridMixin:OnRowClick(row, button)
```

A clicked row; does nothing unless a caller's mixin says otherwise.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `row` | `LibDataGridRow` |  |
| `button` | `string` |  |

### OnViewChanged

```lua
function LibDataGridGridMixin:OnViewChanged(event)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |

### Refresh

```lua
function LibDataGridGridMixin:Refresh()
```

Runs the view over the rows again and draws them.

### SetRows

```lua
function LibDataGridGridMixin:SetRows(rows)
```

The rows the grid shows from: every row, as the owner keeps them. Call again, or Refresh,  
after they change.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `rows` | `LibDataGridRow[]` |  |

