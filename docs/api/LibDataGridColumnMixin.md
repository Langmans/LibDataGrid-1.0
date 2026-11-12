## Fields

| Name | Type | Description |
|------|------|-------------|
| caseSensitive | `boolean?` |  |
| choices | `LibDataGridChoice[] \| fun():LibDataGridChoice[]?` |  |
| key | `string` |  |
| label | `string` |  |
| read | `(fun(row: LibDataGridRow):number \| string \| nil \| boolean)?` |  |
| type | `string` |  |

## Methods

### Choices

```lua
function LibDataGridColumnMixin:Choices()
  -> LibDataGridChoice[]
```

An enum's choices ({ value, text } each); a function in the definition is asked each time.

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridChoice[]` |  |

### Fold

```lua
function LibDataGridColumnMixin:Fold(value)
  -> number | string | nil | boolean
```

A value as tests compare it: a string column's text in lower case unless it is case sensitive.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `value` | `LibDataGridValue?` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `number \| string \| nil \| boolean` |  |

### FormatValue

```lua
function LibDataGridColumnMixin:FormatValue(value)
  -> string
```

The value written as text: a choice's text, a date as MySQL writes it, true/false, a number as  
Lua writes it.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `value` | `LibDataGridValue` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `string` |  |

### Init

```lua
function LibDataGridColumnMixin:Init(def)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `def` | `LibDataGridColumnDef` |  |

### ParseValue

```lua
function LibDataGridColumnMixin:ParseValue(text)
  -> number | string | nil | boolean, string?
```

The value a piece of filter text stands for, or nil and the error code.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `string` |  |

**Returns:**

| Name | Type | Description |
|------|------|-------------|
| `value` | `number \| string \| nil \| boolean` |  |
| `code` | `string?` |  |

### SortValue

```lua
function LibDataGridColumnMixin:SortValue(row)
  -> number | string | nil | boolean
```

The row's value to sort by: a number, a folded string, a choice's folded text, 0 or 1 for a  
boolean, nil when blank.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `row` | `LibDataGridRow` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `number \| string \| nil \| boolean` |  |

### Value

```lua
function LibDataGridColumnMixin:Value(row)
  -> number | string | nil | boolean
```

The row's value in this column: the definition's value function, else the row's field.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `row` | `LibDataGridRow` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `number \| string \| nil \| boolean` |  |

