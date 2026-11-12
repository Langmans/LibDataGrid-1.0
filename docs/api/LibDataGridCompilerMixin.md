## Methods

### Compile

```lua
function LibDataGridCompilerMixin:Compile(tree)
  -> fun(row: LibDataGridRow):boolean
```

The function that says whether a row passes this tree; every row passes an empty one.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `tree` | `LibDataGridGroup` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `fun(row: LibDataGridRow):boolean` |  |

