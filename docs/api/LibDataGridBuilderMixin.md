Inherits: Frame, Region, ScriptRegion, Object, FrameScriptObject, ScriptRegionResizing, AnimatableObject, ScriptObject

## Fields

| Name | Type | Description |
|------|------|-------------|
| bar | `LibDataGridScrollBarMixin` |  |
| body | `Frame` |  |
| columnKeys | `number \| string \| boolean[]` |  |
| columnLabels | `string[]` |  |
| count | `number` | how many entries the last draw had |
| entries | `LibDataGridBuilderEntry[]` |  |
| lines | `LibDataGridBuilderLine[]` |  |
| operatorChoices | `table<string, LibDataGridOperatorChoices>` |  |
| preview | `FontString` |  |
| skin | `LibDataGridSkinMixin` |  |
| tree | `LibDataGridGroup` | the copy being edited |
| view | `LibDataGridView` |  |

## Methods

### AddEntry

```lua
function LibDataGridBuilderMixin:AddEntry(kind, node, parent, depth)
```

The next entry, its table kept from the last draw when there is one.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `kind` | `string` |  |
| `node` | `LibDataGridNode` |  |
| `parent` | `LibDataGridGroup?` |  |
| `depth` | `number` |  |

### Apply

```lua
function LibDataGridBuilderMixin:Apply()
```

Hands the copy to the view and closes.

### Collect

```lua
function LibDataGridBuilderMixin:Collect(node, parent, depth)
```

Every line, in order: a group, its children, its add line.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `node` | `LibDataGridNode` |  |
| `parent` | `LibDataGridGroup?` |  |
| `depth` | `number` |  |

### Draw

```lua
function LibDataGridBuilderMixin:Draw()
```

Draws the copy: every line from the scrolled offset, and the filter as text.

### DrawLine

```lua
function LibDataGridBuilderMixin:DrawLine(line, entry)
```

Shows one entry on a line.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `line` | `LibDataGridBuilderLine` |  |
| `entry` | `LibDataGridBuilderEntry` |  |

### NewCondition

```lua
function LibDataGridBuilderMixin:NewCondition()
  -> LibDataGridCondition
```

A new condition: the first column, with its type's first operator.

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridCondition` |  |

### Open

```lua
function LibDataGridBuilderMixin:Open()
```

Opens on a fresh copy of the view's filter.

### OperatorChoices

```lua
function LibDataGridBuilderMixin:OperatorChoices(type)
  -> number | string | boolean[], string[]
```

The choices of the column and operator pickers, made once: the schema does not change.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `type` | `string` |  |

**Returns:**

| Name | Type | Description |
|------|------|-------------|
| `ids` | `number \| string \| boolean[]` |  |
| `labels` | `string[]` |  |

### ShowPreview

```lua
function LibDataGridBuilderMixin:ShowPreview()
```

The copy as filter text, under the lines.

