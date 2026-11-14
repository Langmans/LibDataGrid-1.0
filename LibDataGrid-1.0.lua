-- LibDataGrid-1.0: filtering and sorting for lists of rows, the way a data grid does it. A schema
-- names the columns; a view holds a filter (a tree of AND/OR groups of conditions, also written as
-- text such as `[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2.0)`) and a sort on several keys,
-- and fills a list with the rows that pass, in order. Every part is a mixin a caller can extend.
--
--   local DG = LibStub("LibDataGrid-1.0")
--   local view = DG:NewSchema({ { key = "level", type = DG.types.number } }):NewView()
--   view:SetFilterText("[level] > 10")
--   view:Refresh(rows, shown)

-- MINOR goes up by one with every release, and the release tag is the same number (README).
local MAJOR, MINOR = "LibDataGrid-1.0", 1

---@type LibDataGrid?
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- The files in Core\ and Mixins\ add to the library only while this copy is loading: each returns
-- early unless `pending` is set, and the last one (ViewMixin.lua) clears it. A copy that LibStub
-- turned away leaves `pending` unset, so its other files change nothing.
lib.pending = true

-- The library's name, for the few names the game sees (the pick list's frame).
lib.name = MAJOR

-- The events a view sends (ViewMixin:TriggerEvent).
lib.events = {
    FilterChanged = "FilterChanged",
    SortChanged = "SortChanged",
}

-- The kinds of value a column holds. A date is a time in seconds, as time() gives it.
lib.types = {
    number = "number",
    string = "string",
    enum = "enum",
    boolean = "boolean",
    date = "date",
}

-- How a column's cells and header line up, as SetJustifyH takes it.
lib.aligns = {
    left = "LEFT",
    center = "CENTER",
    right = "RIGHT",
}

-- How the conditions in a group combine.
lib.joins = {
    ["and"] = "and",
    ["or"] = "or",
}

-- The kinds of piece filter text is made of, for syntax highlighting (SchemaMixin:Tokens).
lib.tokenKinds = {
    column = "column",
    operator = "operator",
    keyword = "keyword",
    value = "value",
    bracket = "bracket",
    error = "error",
}

-- Why filter text did not parse: an error's code, for a caller that words it itself.
lib.errors = {
    unknownColumn = "unknownColumn",
    unclosedColumn = "unclosedColumn",
    expectedCondition = "expectedCondition",
    expectedOperator = "expectedOperator",
    operatorNotForType = "operatorNotForType",
    expectedValue = "expectedValue",
    unclosedString = "unclosedString",
    badNumber = "badNumber",
    badBoolean = "badBoolean",
    badDate = "badDate",
    expectedRangeAnd = "expectedRangeAnd",
    unknownChoice = "unknownChoice",
    expectedList = "expectedList",
    unclosedList = "unclosedList",
    unclosedGroup = "unclosedGroup",
    unexpected = "unexpected",
}

---A new filter: an empty group, AND unless another join is asked for.
---@param join string?
---@return LibDataGridGroup
function lib.NewFilter(join)
    return { join = join or lib.joins["and"], children = {} }
end

-- An edit box keeps a typed | as || and shows || as one bar, as font strings do. Text goes in
-- with its bars doubled and comes out with them single, so the rest of the library only ever sees
-- what was typed.

---Text as an edit box or a font string should get it.
---@param text string
---@return string
function lib.ToEditBox(text)
    return (text:gsub("|", "||"))
end

---Text as typed, from what an edit box holds.
---@param text string
---@return string
function lib.FromEditBox(text)
    return (text:gsub("||", "|"))
end

---A deep copy of a filter tree or a sort, so a caller's and the view's never share a table.
---@generic T
---@param value T
---@return T
function lib.Copy(value)
    if type(value) ~= "table" then return value end
    ---@type table<string|number, table|LibDataGridValue>
    local source, copy = value, {}
    for k, v in pairs(source) do
        copy[k] = lib.Copy(v)
    end
    return copy
end
