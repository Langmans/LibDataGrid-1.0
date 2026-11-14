Inherits: Frame, Region, ScriptRegion, Object, FrameScriptObject, ScriptRegionResizing, AnimatableObject, ScriptObject, [LibDataGridWidget](LibDataGridWidget.md)

## Fields

| Name | Type | Description |
|------|------|-------------|
| apply | `Button` |  |
| builder | `LibDataGridBuilderMixin?` | made when first opened |
| clear | `Button` | the x that empties the filter |
| edit | `EditBox` |  |
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

### UpdateClear

```lua
function LibDataGridFilterBoxMixin:UpdateClear()
```

The clear button shows only when there is text to clear.

