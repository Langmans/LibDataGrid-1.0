Inherits: Button, Frame

## Fields

| Name | Type | Description |
|------|------|-------------|
| label | `FontString` |  |
| skin | `LibDataGridSkinMixin` |  |
| texts | `string[]` |  |
| value | `number \| string \| boolean?` |  |
| values | `number \| string \| boolean[]` |  |

## Methods

### SetChoices

```lua
function LibDataGridPickerMixin:SetChoices(values, texts, chosen)
```

The choices, in the order they list, and the one chosen; a value not among them shows as none.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `values` | `LibDataGridValue[]` |  |
| `texts` | `string[]` |  |
| `chosen` | `LibDataGridValue?` |  |

## Functions

### OnPick

```lua
function LibDataGridPickerMixin.OnPick(value)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `value` | `LibDataGridValue` |  |

