Inherits: [LibDataGridRegistryEventsMixin](LibDataGridRegistryEventsMixin.md), [LibDataGridEventsMixin](LibDataGridEventsMixin.md), [LibDataGridSortMixin](LibDataGridSortMixin.md)

## Fields

| Name | Type | Description |
|------|------|-------------|
| filter | `LibDataGridGroup` |  |
| passes | `function` |  |

## Methods

### FilterEdited

```lua
function LibDataGridViewMixin:FilterEdited()
```

The filter tree changed in place: use it from now on.

### GetFilter

```lua
function LibDataGridViewMixin:GetFilter()
  -> LibDataGridGroup
```

The view's own filter tree, for a caller that edits it in place and then calls FilterEdited.

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridGroup` |  |

### GetFilterModel

```lua
function LibDataGridViewMixin:GetFilterModel()
  -> LibDataGridGroup
```

A copy of the filter tree, to keep.

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridGroup` |  |

### GetFilterText

```lua
function LibDataGridViewMixin:GetFilterText()
  -> string
```

The filter as text, in the schema's labels.

**Returns:**

| Type | Description |
|------|-------------|
| `string` |  |

### Init

```lua
function LibDataGridViewMixin:Init(schema)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `schema` | `LibDataGridSchema` |  |

### Refresh

```lua
function LibDataGridViewMixin:Refresh(rows, out)
  -> table[], number
```

Fills `out` with the rows that pass the filter, sorted, and clears what is left past them.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `rows` | `table[]` |  |
| `out` | `table[]` |  |

**Returns:**

| Name | Type | Description |
|------|------|-------------|
| `out` | `table[]` |  |
| `n` | `number` |  |

### SetFilterModel

```lua
function LibDataGridViewMixin:SetFilterModel(tree)
```

Filters by a copy of this tree; nil is no filter.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `tree` | `LibDataGridGroup?` |  |

### SetFilterText

```lua
function LibDataGridViewMixin:SetFilterText(text)
  -> boolean, LibDataGridError?
```

Filters by this text; when it does not parse, the filter stays as it was.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `string` |  |

**Returns:**

| Name | Type | Description |
|------|------|-------------|
| `ok` | `boolean` |  |
| `err` | `LibDataGridError?` |  |

