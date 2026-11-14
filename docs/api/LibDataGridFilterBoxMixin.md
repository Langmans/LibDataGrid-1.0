Inherits: Frame, Region, ScriptRegion, Object, FrameScriptObject, ScriptRegionResizing, AnimatableObject, ScriptObject, [LibDataGridWidget](LibDataGridWidget.md)

## Fields

| Name | Type | Description |
|------|------|-------------|
| apply | `Button` |  |
| builder | `LibDataGridBuilderMixin?` | made when first opened |
| clear | `Button` | the x that empties the filter |
| edit | `EditBox` |  |
| filterText | `string` | the text as typed; the edit box may show it coloured |
| hint | `FontString` |  |
| open | `Button` | opens the Builder |
| skin | `LibDataGridSkinMixin` |  |
| view | `LibDataGridView` |  |

## Methods

### Apply

```lua
function LibDataGridFilterBoxMixin:Apply()
```

Applies the box's text to the view, or shows why it cannot.

### Clear

```lua
function LibDataGridFilterBoxMixin:Clear()
```

Empties the filter.

### GetText

```lua
function LibDataGridFilterBoxMixin:GetText()
  -> string
```

The filter text in the box as typed: never the coloured text the box shows.

**Returns:**

| Type | Description |
|------|-------------|
| `string` |  |

### OnViewChanged

```lua
function LibDataGridFilterBoxMixin:OnViewChanged(event)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |

### OpenBuilder

```lua
function LibDataGridFilterBoxMixin:OpenBuilder()
```

Opens the Builder on the view's filter; the box keeps one, made the first time.

### Reset

```lua
function LibDataGridFilterBoxMixin:Reset()
```

Shows the view's filter and drops the hint.

### SetText

```lua
function LibDataGridFilterBoxMixin:SetText(text)
```

Puts filter text in the box.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `string` |  |

### ShowText

```lua
function LibDataGridFilterBoxMixin:ShowText()
```

Shows the text: plain while the box is being typed in, so the cursor and a marked error sit  
where they should; coloured by kind otherwise. The clear button shows when there is text.

