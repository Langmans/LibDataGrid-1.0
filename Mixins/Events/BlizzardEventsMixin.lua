-- The view's events through Blizzard's CallbackRegistryMixin (Blizzard_SharedXMLBase, on both
-- clients): view:RegisterCallback(view.Event.FilterChanged, func, owner), and a callback is called
-- with the owner, then the view. The registry's methods are mixed in when the view starts, so the
-- game's own copy is the one used.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

---@class LibDataGridBlizzardEventsMixin
---@field Event table<string, string> the events, as CallbackRegistryMixin keeps them
---@field OnLoad fun(self: LibDataGridBlizzardEventsMixin)
---@field GenerateCallbackEvents fun(self: LibDataGridBlizzardEventsMixin, events: string[])
---@field TriggerEvent fun(self: LibDataGridBlizzardEventsMixin, event: string, view: LibDataGridBlizzardEventsMixin)
local BlizzardEventsMixin = {}
lib.BlizzardEventsMixin = BlizzardEventsMixin

-- The events, as CallbackRegistryMixin:GenerateCallbackEvents takes them.
---@type string[]
local EVENTS = {}
for _, event in pairs(lib.events) do
    EVENTS[#EVENTS + 1] = event
end

function BlizzardEventsMixin:InitEvents()
    if not CallbackRegistryMixin then
        error("LibDataGrid-1.0: the Blizzard events adapter needs CallbackRegistryMixin", 0)
    end
    Mixin(self, CallbackRegistryMixin)
    self:OnLoad()
    self:GenerateCallbackEvents(EVENTS)
end

---@param event string
function BlizzardEventsMixin:Notify(event)
    self:TriggerEvent(event, self)
end
