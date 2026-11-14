Inherits: Slider, Frame

## Fields

| Name | Type | Description |
|------|------|-------------|
| last | `number` | the furthest offset |
| offset | `number` | rows scrolled past |

## Methods

### ScrollTo

```lua
function LibDataGridScrollBarMixin:ScrollTo(offset)
```

Moves to `offset`, kept within the rows, and tells the owner when that is somewhere new.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `offset` | `number` |  |

### SetRange

```lua
function LibDataGridScrollBarMixin:SetRange(total, visible)
```

How many rows there are and how many show: the bar shows only when they do not all fit, and the  
offset stays within them. Does not tell the owner, who is filling the rows anyway.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `total` | `number` |  |
| `visible` | `number` |  |

## Functions

### OnScroll

```lua
function LibDataGridScrollBarMixin.OnScroll(offset)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `offset` | `number` |  |

