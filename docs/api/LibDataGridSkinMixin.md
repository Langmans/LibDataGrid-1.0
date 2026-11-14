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

### Highlight

```lua
function LibDataGridSkinMixin:Highlight(schema, text)
  -> string
```

Filter text with colour codes, each piece in its kind's colour, for an edit box to show (not for  
parsing). An edit box shows || as two bars rather than one, and a colour code next to a bar goes  
wrong, so a piece with a | in it stays as it is, uncoloured, and so does a piece right against it.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `schema` | `LibDataGridSchema` |  |
| `text` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `string` |  |

### Stripe

```lua
function LibDataGridSkinMixin:Stripe(texture)
```

The back of every other row in a grid. On the dark backdrop, text over it keeps WCAG AAA (7:1)  
in white (16.6:1), gold (11.3:1) and green (12.1:1); red keeps AA (5.1:1).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `texture` | `Texture` |  |

### TokenColour

```lua
function LibDataGridSkinMixin:TokenColour(kind)
  -> string
```

The colour of a kind of piece of filter text (lib.tokenKinds), as a colour code takes it.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `kind` | `string` |  |

**Returns:**

| Type | Description |
|------|-------------|
| `string` |  |

