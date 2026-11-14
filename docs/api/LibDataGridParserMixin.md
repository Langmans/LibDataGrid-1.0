## Methods

### Parse

```lua
function LibDataGridParserMixin:Parse(text)
  -> LibDataGridGroup?, LibDataGridError?
```

The tree this filter text stands for, or nil and why not.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `string` |  |

**Returns:**

| Name | Type | Description |
|------|------|-------------|
| `tree` | `LibDataGridGroup?` |  |
| `err` | `LibDataGridError?` |  |

### Tokens

```lua
function LibDataGridParserMixin:Tokens(text)
  -> LibDataGridToken[], LibDataGridError?
```

The pieces of filter text as the parser reads them, for syntax highlighting: each with its kind  
(lib.tokenKinds) and the characters it covers. Text that does not parse is one error piece from  
where it stops making sense to the end; the error comes second.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `string` |  |

**Returns:**

| Name | Type | Description |
|------|------|-------------|
| `tokens` | `LibDataGridToken[]` |  |
| `err` | `LibDataGridError?` |  |

