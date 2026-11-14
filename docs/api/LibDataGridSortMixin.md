## Fields

| Name | Type | Description |
|------|------|-------------|
| order | `table<table \| number \| string, number>` |  |
| schema | `LibDataGridSchema` |  |
| sort | `LibDataGridSortKey[]` |  |
| sortColumns | `LibDataGridColumnMixin[]` |  |
| sortDescending | `table<number, boolean?>` |  |
| sortValues | `table<table \| number \| string, number \| string \| nil \| boolean>[]` |  |

## Methods

### Changed

```lua
function LibDataGridSortMixin:Changed(event)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |

### Compare

```lua
function LibDataGridSortMixin:Compare(a, b)
  -> boolean
```

Whether row a goes before row b. Needs SortRows to have filled in the values; one column's  
values are all numbers or all strings.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `a` | `LibDataGridRow` |  |
| `b` | `LibDataGridRow` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `boolean` |  |

### GetSort

```lua
function LibDataGridSortMixin:GetSort()
  -> LibDataGridSortKey[]
```

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridSortKey[]` |  |

### InitSort

```lua
function LibDataGridSortMixin:InitSort()
```

### SetSort

```lua
function LibDataGridSortMixin:SetSort(sort)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `sort` | `LibDataGridSortKey[]` |  |

### SortIndex

```lua
function LibDataGridSortMixin:SortIndex(key)
  -> number?, boolean?
```

Where this key stands in the sort, and whether it goes down; nil when it is not sorted on.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `key` | `string` |  |

**Returns:**

| Name | Type | Description |
|------|------|-------------|
| `index` | `number?` |  |
| `descending` | `boolean?` |  |

### SortRows

```lua
function LibDataGridSortMixin:SortRows(list, n)
```

Sorts the first n rows of a list in place; `order` must hold each row's place in it.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `list` | `LibDataGridRow[]` |  |
| `n` | `number` |  |

### ToggleSort

```lua
function LibDataGridSortMixin:ToggleSort(key, additive)
```

A click on a column head: up, down, then off. Without `additive` the other keys go; with it  
(Ctrl) they stay and a new key goes last.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `key` | `string` |  |
| `additive` | `boolean?` |  |

## Functions

### compare

```lua
function LibDataGridSortMixin.compare(a, b)
  -> boolean
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `a` | `LibDataGridRow` |  |
| `b` | `LibDataGridRow` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `boolean` |  |

