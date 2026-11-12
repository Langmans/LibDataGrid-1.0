-- The little of the game the library needs: Blizzard's Mixin and CreateFromMixins (as
-- Blizzard_SharedXMLBase/Mixin.lua has them on both clients), CallbackRegistryMixin for the
-- Blizzard events adapter, time, date and wipe. NewClient() resets those
-- globals and LibStub and loads the .toc's files into the fresh state, so tests never share it.

---Loads every file of the .toc into the current globals.
local function LoadToc()
    for _, file in ipairs(TOC_FILES) do
        assert(loadfile(file))("LibDataGrid-1.0", {})
    end
end

---A fresh client with the library loaded; returns the library.
---@return LibDataGrid
function NewClient()
    LibStub = nil

    function Mixin(object, ...)
        for i = 1, select("#", ...) do
            for k, v in pairs((select(i, ...))) do
                object[k] = v
            end
        end
        return object
    end

    function CreateFromMixins(...)
        return Mixin({}, ...)
    end

    function wipe(t)
        for k in pairs(t) do
            t[k] = nil
        end
        return t
    end

    -- The game's time and date are Lua's os.time and os.date; CallbackHandler calls its handlers
    -- through securecallfunction.
    time, date = os.time, os.date
    function securecallfunction(func, ...)
        return func(...)
    end

    -- Blizzard_SharedXMLBase/CallbackRegistry.lua, the part a view uses: closures only, called
    -- with the owner first, and an error for an event the registry does not define.
    CallbackRegistryMixin = {
        OnLoad = function(self)
            self.callbackTables = {}
        end,
        GenerateCallbackEvents = function(self, events)
            self.Event = self.Event or {}
            for _, event in ipairs(events) do
                self.Event[event] = event
            end
        end,
        RegisterCallback = function(self, event, func, owner)
            self.callbackTables[event] = self.callbackTables[event] or {}
            self.callbackTables[event][owner] = func
            return owner
        end,
        UnregisterCallback = function(self, event, owner)
            if self.callbackTables[event] then self.callbackTables[event][owner] = nil end
        end,
        TriggerEvent = function(self, event, ...)
            if not self.Event[event] then
                error(("CallbackRegistryMixin:TriggerEvent event '%s' doesn't exist."):format(event))
            end
            for owner, func in pairs(self.callbackTables[event] or {}) do
                func(owner, ...)
            end
        end,
    }

    LoadToc()
    return LibStub("LibDataGrid-1.0")
end

---Loads the .toc's files again over the current state, as a second addon embedding the same copy
---does.
function LoadTocAgain()
    LoadToc()
end
