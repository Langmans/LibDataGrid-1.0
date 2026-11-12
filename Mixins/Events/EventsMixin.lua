-- The base every events adapter comes from: what a view calls on it, InitEvents when it starts and
-- Notify(event) when its filter or sort changed. Here both do nothing, so a view made with this
-- base alone sends no events, and an adapter of a caller's needs only its own Notify:
--
--   local Messages = CreateFromMixins(DG.EventsMixin, { Notify = function(view, event) ... end })

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

---@class LibDataGridEventsMixin
local EventsMixin = {}
lib.EventsMixin = EventsMixin

---When the view starts: set up whatever the adapter keeps.
function EventsMixin:InitEvents() end

---The view's filter or sort changed (lib.events).
---@param event string
function EventsMixin:Notify(event) end
