-- The view's own events (an observer registry), the default adapter. It takes callbacks the way
-- Blizzard's CallbackRegistryMixin does: RegisterCallback(event, func, owner), and a callback is
-- called with the owner, then the view.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

---@alias LibDataGridCallback fun(owner: table, view: LibDataGridView)

---@type table<table, LibDataGridCallback>
local NONE = {}

---@class LibDataGridRegistryEventsMixin: LibDataGridEventsMixin
---@field callbacks table<string, table<table, LibDataGridCallback>>
local RegistryEventsMixin = CreateFromMixins(lib.EventsMixin)
lib.RegistryEventsMixin = RegistryEventsMixin

function RegistryEventsMixin:InitEvents()
    self.callbacks = {}
end

---Calls func(owner, view) on this event, one callback per owner.
---@param event string
---@param func LibDataGridCallback
---@param owner table
function RegistryEventsMixin:RegisterCallback(event, func, owner)
    self.callbacks[event] = self.callbacks[event] or {}
    self.callbacks[event][owner] = func
end

---@param event string
---@param owner table
function RegistryEventsMixin:UnregisterCallback(event, owner)
    local callbacks = self.callbacks[event]
    if callbacks then callbacks[owner] = nil end
end

---@param event string
---@param view LibDataGridView
function RegistryEventsMixin:TriggerEvent(event, view)
    ---@type table<table, LibDataGridCallback>
    local callbacks = self.callbacks[event] or NONE
    for owner, func in pairs(callbacks) do
        func(owner, view)
    end
end

---What the view calls when something changed.
---@param event string
function RegistryEventsMixin:Notify(event)
    self:TriggerEvent(event, self --[[@as LibDataGridView]])
end
