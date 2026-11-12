## Fields

| Name | Type | Description |
|------|------|-------------|
| callbacks | `table<string, table<table, function>>` |  |

## Methods

### InitEvents

```lua
function LibDataGridRegistryEventsMixin:InitEvents()
```

### Notify

```lua
function LibDataGridRegistryEventsMixin:Notify(event)
```

What the view calls when something changed.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |

### RegisterCallback

```lua
function LibDataGridRegistryEventsMixin:RegisterCallback(event, func, owner)
```

Calls func(owner, view) on this event, one callback per owner.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |
| `func` | `LibDataGridCallback` |  |
| `owner` | `table` |  |

### TriggerEvent

```lua
function LibDataGridRegistryEventsMixin:TriggerEvent(event, view)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |
| `view` | `LibDataGridView` |  |

### UnregisterCallback

```lua
function LibDataGridRegistryEventsMixin:UnregisterCallback(event, owner)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |
| `owner` | `table` |  |

