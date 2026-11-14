## Fields

| Name | Type | Description |
|------|------|-------------|
| BOOLEAN_CELLS | `table<boolean, string>` | what a cell shows for true and false |
| BlizzardEventsMixin | `LibDataGridBlizzardEventsMixin` |  |
| BuilderMixin | `LibDataGridBuilderMixin` |  |
| CallbackHandlerEventsMixin | `LibDataGridCallbackHandlerEventsMixin` |  |
| ColumnMixin | `LibDataGridColumnMixin` |  |
| CompilerMixin | `LibDataGridCompilerMixin` |  |
| EventsMixin | `LibDataGridEventsMixin` |  |
| FilterBoxMixin | `LibDataGridFilterBoxMixin` |  |
| FormatterMixin | `LibDataGridFormatterMixin` |  |
| GridMixin | `LibDataGridGridMixin` |  |
| L | `table<string, string>` | the widgets' words, English unless an addon sets them |
| ParserMixin | `LibDataGridParserMixin` |  |
| PickerMixin | `LibDataGridPickerMixin` |  |
| RegistryEventsMixin | `LibDataGridRegistryEventsMixin` |  |
| SCROLLBAR_WIDTH | `number` |  |
| SchemaMixin | `LibDataGridSchemaMixin` |  |
| ScrollBarMixin | `LibDataGridScrollBarMixin` |  |
| SkinMixin | `LibDataGridSkinMixin` |  |
| SortMixin | `LibDataGridSortMixin` |  |
| ViewMixin | `LibDataGridViewMixin` |  |
| aligns | `table<string, string>` |  |
| builders | `number?` | how many Builder dialogs there are, for their frame names |
| errors | `table<string, string>` |  |
| events | `table<string, string>` |  |
| grammar | `LibDataGridOperator[]` | the operators, in the order a picker lists them |
| joins | `table<string, string>` |  |
| name | `string` | the library's LibStub name |
| operators | `table<string, LibDataGridOperator>` | each operator by id |
| ops | `table<string, string>` | each operator's id by name |
| pending | `boolean?` | set while this copy's files load |
| pickList | `LibDataGridPickList?` | the pick list every picker shares, made when first opened |
| takes | `table<string, string>` |  |
| tokenKinds | `table<string, string>` |  |
| tokens | `LibDataGridOperator[]` | the operators as the parser tries them, longest token first |
| types | `table<string, string>` |  |

## Methods

### CreateBuilder

```lua
function LibDataGrid:CreateBuilder(view, skin, ...)
  -> LibDataGridBuilderMixin
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `view` | `LibDataGridView` |  |
| `skin` | `LibDataGridSkinMixin?` |  |
| `...` | `table` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridBuilderMixin` |  |

### CreateFilterBox

```lua
function LibDataGrid:CreateFilterBox(parent, view, skin, ...)
  -> LibDataGridFilterBoxMixin
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `parent` | `Frame` |  |
| `view` | `LibDataGridView` |  |
| `skin` | `LibDataGridSkinMixin?` |  |
| `...` | `table` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridFilterBoxMixin` |  |

### CreateGrid

```lua
function LibDataGrid:CreateGrid(parent, view, skin, ...)
  -> LibDataGridGridMixin
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `parent` | `Frame` |  |
| `view` | `LibDataGridView` |  |
| `skin` | `LibDataGridSkinMixin?` |  |
| `...` | `table` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridGridMixin` |  |

### CreatePicker

```lua
function LibDataGrid:CreatePicker(parent, skin, OnPick)
  -> LibDataGridPickerMixin
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `parent` | `Frame` |  |
| `skin` | `LibDataGridSkinMixin?` |  |
| `OnPick` | `fun(value: LibDataGridValue)` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridPickerMixin` |  |

### CreateScrollBar

```lua
function LibDataGrid:CreateScrollBar(list, OnScroll)
  -> LibDataGridScrollBarMixin
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `list` | `Frame` |  |
| `OnScroll` | `fun(offset: number)` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `LibDataGridScrollBarMixin` |  |

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

### FromEditBox

```lua
function LibDataGrid.FromEditBox(text)
  -> string
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `string` |  |

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

### ToEditBox

```lua
function LibDataGrid.ToEditBox(text)
  -> string
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `string` |  |

