-- The view's events through CallbackHandler-1.0, for an Ace3 addon: view.RegisterCallback(owner,
-- event, method) as CallbackHandler gives it, and a callback is called with the event's name, then
-- the view. The addon embeds CallbackHandler-1.0 itself.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

---@class LibDataGridCallbackHandlerEventsMixin
---@field handler CallbackHandlerRegistry
local CallbackHandlerEventsMixin = {}
lib.CallbackHandlerEventsMixin = CallbackHandlerEventsMixin

function CallbackHandlerEventsMixin:InitEvents()
    local CallbackHandler = LibStub("CallbackHandler-1.0", true) --[[@as CallbackHandler?]]
    if not CallbackHandler then
        error("LibDataGrid-1.0: the CallbackHandler events adapter needs CallbackHandler-1.0 loaded", 0)
    end
    self.handler = CallbackHandler:New(self)
end

---@param event string
function CallbackHandlerEventsMixin:Notify(event)
    self.handler:Fire(event, self)
end
