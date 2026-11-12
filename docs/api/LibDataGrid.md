## Fields

| Name | Type | Description |
|------|------|-------------|
| BlizzardEventsMixin | `LibDataGridBlizzardEventsMixin` |  |
| CallbackHandlerEventsMixin | `LibDataGridCallbackHandlerEventsMixin` |  |
| ColumnMixin | `LibDataGridColumnMixin` |  |
| CompilerMixin | `LibDataGridCompilerMixin` |  |
| EventsMixin | `LibDataGridEventsMixin` |  |
| FormatterMixin | `LibDataGridFormatterMixin` |  |
| ParserMixin | `LibDataGridParserMixin` |  |
| RegistryEventsMixin | `LibDataGridRegistryEventsMixin` |  |
| SchemaMixin | `LibDataGridSchemaMixin` |  |
| SortMixin | `LibDataGridSortMixin` |  |
| ViewMixin | `LibDataGridViewMixin` |  |
| errors | `table<string, string>` |  |
| events | `table<string, string>` |  |
| grammar | `LibDataGridOperator[]` | the operators, in the order a picker lists them |
| joins | `table<string, string>` |  |
| operators | `table<string, LibDataGridOperator>` | each operator by id |
| ops | `table<string, string>` | each operator's id by name |
| pending | `boolean?` | set while this copy's files load |
| takes | `table<string, string>` |  |
| tokens | `LibDataGridOperator[]` | the operators as the parser tries them, longest token first |
| types | `table<string, string>` |  |

## Methods

### NewSchema

```lua
function LibDataGrid:NewSchema(defs, ...)
  -> LibDataGridSchema
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `defs` | `LibDataGridColumnDef[]` |  |
| `...` | `table` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridSchema` |  |

## Functions

### Copy

```lua
function LibDataGrid.Copy(value)
  -> table | number | string | boolean
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `value` | `table \| LibDataGridValue` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `table \| number \| string \| boolean` |  |

### IsBlank

```lua
function LibDataGrid.IsBlank(value)
  -> boolean
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `value` | `LibDataGridValue?` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `boolean` |  |

### NewFilter

```lua
function LibDataGrid.NewFilter(join)
  -> LibDataGridGroup
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `join` | `string?` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridGroup` |  |

### OperatorsFor

```lua
function LibDataGrid.OperatorsFor(type)
  -> LibDataGridOperator[]
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `type` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridOperator[]` |  |

