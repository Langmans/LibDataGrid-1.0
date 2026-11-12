Inherits: [LibDataGridParserMixin](LibDataGridParserMixin.md), [LibDataGridFormatterMixin](LibDataGridFormatterMixin.md), [LibDataGridCompilerMixin](LibDataGridCompilerMixin.md)

## Fields

| Name | Type | Description |
|------|------|-------------|
| byKey | `table<string, LibDataGridColumnMixin>` |  |
| columns | `LibDataGridColumnMixin[]` |  |

## Methods

### Column

```lua
function LibDataGridSchemaMixin:Column(key)
  -> LibDataGridColumnMixin?
```

The column with this key.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `key` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridColumnMixin?` |  |

### Find

```lua
function LibDataGridSchemaMixin:Find(name)
  -> LibDataGridColumnMixin?
```

The column with this label or key, in any case: how filter text names one.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `name` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridColumnMixin?` |  |

### Init

```lua
function LibDataGridSchemaMixin:Init(defs)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `defs` | `LibDataGridColumnDef[]` |  |

### IsComplete

```lua
function LibDataGridSchemaMixin:IsComplete(node)
  -> boolean
```

Whether a condition says something: a known column, an operator its type has, and the value,  
list or both ends the operator takes.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `node` | `LibDataGridCondition` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `boolean` |  |

### NewView

```lua
function LibDataGridSchemaMixin:NewView(...)
  -> LibDataGridView
```

A view over this schema's rows, with the caller's mixins over the view's own.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `...` | `table` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridView` |  |

