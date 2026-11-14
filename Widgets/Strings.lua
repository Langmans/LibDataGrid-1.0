-- The widgets' words, in English. An addon with its own locales sets these after loading:
--   DG.L.APPLY = L["Apply"]
-- A newer copy of the library keeps what an addon set, and adds the words it did not have.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

---@type table<string, string>
local L = lib.L or {}
lib.L = L

local ENGLISH = {
    APPLY = "Apply",
    CANCEL = "Cancel",
    BUILDER = "Builder",
    BUILDER_TITLE = "Filter builder",
    AND = "AND",
    OR = "OR",
    NOT = "NOT",
    RANGE_AND = "and",
    ADD_CONDITION = "+ condition",
    ADD_GROUP = "+ group",
    REMOVE = "x",
}
for key, text in pairs(ENGLISH) do
    L[key] = L[key] or text
end
