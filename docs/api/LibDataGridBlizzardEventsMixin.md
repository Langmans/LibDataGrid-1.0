Inherits: [LibDataGridEventsMixin](LibDataGridEventsMixin.md)

## Fields

| Name | Type | Description |
|------|------|-------------|
| Event | `table<string, string>` | the events, as CallbackRegistryMixin keeps them |

## Methods

### GenerateCallbackEvents

```lua
function LibDataGridBlizzardEventsMixin:GenerateCallbackEvents(events)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `events` | `string[]` |  |

### InitEvents

```lua
function LibDataGridBlizzardEventsMixin:InitEvents()
```

### Notify

```lua
function LibDataGridBlizzardEventsMixin:Notify(event)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |

### OnLoad

```lua
function LibDataGridBlizzardEventsMixin:OnLoad()
```

### TriggerEvent

```lua
function LibDataGridBlizzardEventsMixin:TriggerEvent(event, view)
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `event` | `string` |  |
| `view` | `LibDataGridBlizzardEventsMixin` |  |

