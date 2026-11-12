## Fields

| Name | Type | Description |
|------|------|-------------|
| blank | `boolean?` | a test of blankness, which sees blank values |
| id | `string` |  |
| label | `string` | how a picker names it |
| negates | `string?` | the operator it is the opposite of |
| takes | `string?` | a value, a list, both ends, or nothing (lib.takes) |
| token | `string` | how filter text writes it |
| types | `table<string, boolean>` | the column types that have it |

## Functions

### test

```lua
function LibDataGridOperator.test(a, b)
  -> boolean
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `a` | `LibDataGridValue?` |  |
| `b` | `LibDataGridOperand?` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `boolean` |  |

