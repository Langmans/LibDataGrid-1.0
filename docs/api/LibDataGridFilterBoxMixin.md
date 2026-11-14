Inherits: Frame, Region, ScriptRegion, Object, FrameScriptObject, ScriptRegionResizing, AnimatableObject, ScriptObject, [LibDataGridWidget](LibDataGridWidget.md)

## Fields

| Name | Type | Description |
|------|------|-------------|
| apply | `Button` |  |
| edit | `EditBox` |  |
| hint | `FontString` |  |
| skin | `LibDataGridSkinMixin` |  |
| view | `LibDataGridView` |  |

## Methods

### Apply

```lua
function LibDataGridFilterBoxMixin:Apply()
```

Applies the box's text to the view, or shows why it cannot.

### OnViewChanged

```lua
function LibDataGridFilterBoxMixin:OnViewChanged(event)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |

### Reset

```lua
function LibDataGridFilterBoxMixin:Reset()
```

Shows the view's filter and drops the hint.

