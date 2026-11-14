## Methods

### Backdrop

```lua
function LibDataGridSkinMixin:Backdrop(frame)
```

A panel or dialog: a frame made with BackdropTemplate.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `frame` | `Frame` |  |

### Button

```lua
function LibDataGridSkinMixin:Button(button)
```

A button made with UIPanelButtonTemplate.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `button` | `Button` |  |

### EditBox

```lua
function LibDataGridSkinMixin:EditBox(box)
```

An edit box made with InputBoxTemplate.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `box` | `EditBox` |  |

### Field

```lua
function LibDataGridSkinMixin:Field(frame)
```

A field: a picker chip or a box that holds a value.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `frame` | `Frame` |  |

### Font

```lua
function LibDataGridSkinMixin:Font(fontString)
```

A label's font; the widgets make labels with GameFontHighlightSmall.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fontString` | `FontString` |  |

### Stripe

```lua
function LibDataGridSkinMixin:Stripe(texture)
```

The back of every other row in a grid. On the dark backdrop, text over it keeps WCAG AAA (7:1)  
in white (12.6:1), gold (8.7:1) and green (9.2:1); red falls to 3.9:1.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `texture` | `Texture` |  |

