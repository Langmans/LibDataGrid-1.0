-- A column: how to read its value from a row, and how its values turn into text and back. A
-- definition's own mixin goes over this one, so a caller can change any of it.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local T, E = lib.types, lib.errors
---@type LibDataGridChoice[]
local NO_CHOICES = {}

-- What a cell shows for true and false: the ready check's tick and cross (on both clients). Filter
-- text still writes true and false. An addon may set its own.
---@type table<boolean, string>
lib.BOOLEAN_CELLS = lib.BOOLEAN_CELLS
    or {
        [true] = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t",
        [false] = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t",
    }

---A date as MySQL writes one, `2026-11-12` or `2026-11-12 18:30[:05]`, as a local time in seconds;
---nil for anything else, a day the month does not have included.
---@param text string
---@return number?
local function ParseDate(text)
    local year, month, day, rest = text:match("^(%d%d%d%d)-(%d%d)-(%d%d)(.*)$")
    if not year then return nil end
    local hour, min, sec = "0", "0", "0"
    if rest ~= "" then
        hour, min = rest:match("^ (%d%d):(%d%d)$")
        if not hour then
            hour, min, sec = rest:match("^ (%d%d):(%d%d):(%d%d)$")
        end
        if not hour then return nil end
    end
    ---@type table<string, number>
    local fields = {
        year = tonumber(year) --[[@as number]],
        month = tonumber(month) --[[@as number]],
        day = tonumber(day) --[[@as number]],
        hour = tonumber(hour) --[[@as number]],
        min = tonumber(min) --[[@as number]],
        sec = tonumber(sec) or 0,
    }
    -- time() rolls 2026-02-30 over into March; reading the result back catches that.
    local seconds = time(fields --[[@as osdateparam]])
    local back = date("*t", seconds) --[[@as table<string, number>]]
    for key, value in pairs(fields) do
        if back[key] ~= value then return nil end
    end
    return seconds
end

---A time in seconds as MySQL writes it: the day alone at midnight.
---@param seconds number
---@return string
local function FormatDate(seconds)
    if date("%H:%M:%S", seconds) == "00:00:00" then
        return date("%Y-%m-%d", seconds) --[[@as string]]
    end
    return date("%Y-%m-%d %H:%M:%S", seconds) --[[@as string]]
end

---@class LibDataGridColumnMixin
---@field key string
---@field label string
---@field type string
---@field caseSensitive? boolean
---@field choices? LibDataGridChoice[]|fun(): LibDataGridChoice[]
---@field read? fun(row: LibDataGridRow): LibDataGridValue?
---@field cellText? fun(row: LibDataGridRow): string
local ColumnMixin = {}
lib.ColumnMixin = ColumnMixin

---@param def LibDataGridColumnDef
function ColumnMixin:Init(def)
    self.key = def.key
    self.label = def.label or def.key
    self.type = def.type or T.string
    self.caseSensitive = def.caseSensitive
    self.choices = def.choices
    self.read = def.value
    self.cellText = def.text
end

---What a grid's cell shows for the row: the definition's text function, else a tick or a cross for
---true and false, else the value as filter text writes it; nothing for a blank one.
---@param row LibDataGridRow
---@return string
function ColumnMixin:CellText(row)
    if self.cellText then return self.cellText(row) end
    local value = self:Value(row)
    if value == nil or lib.IsBlank(value) then return "" end
    if type(value) == "boolean" then return lib.BOOLEAN_CELLS[value] end
    return self:FormatValue(value)
end

---The row's value in this column: the definition's value function, else the row's field.
---@param row LibDataGridRow
---@return LibDataGridValue?
function ColumnMixin:Value(row)
    if self.read then return self.read(row) end
    return row[self.key] --[[@as LibDataGridValue?]]
end

---A value as tests compare it: a string column's text in lower case unless it is case sensitive.
---@param value LibDataGridValue?
---@return LibDataGridValue?
function ColumnMixin:Fold(value)
    if self.type == T.string and not self.caseSensitive and type(value) == "string" then return value:lower() end
    return value
end

---An enum's choices ({ value, text } each); a function in the definition is asked each time.
---@return LibDataGridChoice[]
function ColumnMixin:Choices()
    local choices = self.choices
    if type(choices) == "function" then
        return (choices --[[@as fun(): LibDataGridChoice[] ]])()
    end
    return choices or NO_CHOICES
end

---The value written as text: a choice's text, a date as MySQL writes it, true/false, a number as
---Lua writes it.
---@param value LibDataGridValue
---@return string
function ColumnMixin:FormatValue(value)
    if self.type == T.date then
        return FormatDate(value --[[@as number]])
    end
    if self.type == T.enum then
        for _, choice in ipairs(self:Choices()) do
            if choice.value == value then return choice.text end
        end
    end
    return tostring(value)
end

---The value a piece of filter text stands for, or nil and the error code.
---@param text string
---@return LibDataGridValue? value
---@return string? code
function ColumnMixin:ParseValue(text)
    if self.type == T.number then
        local number = tonumber(text)
        if not number then return nil, E.badNumber end
        return number
    elseif self.type == T.date then
        local seconds = ParseDate(text)
        if not seconds then return nil, E.badDate end
        return seconds
    elseif self.type == T.boolean then
        local word = text:lower()
        if word == "true" then return true end
        if word == "false" then return false end
        return nil, E.badBoolean
    elseif self.type == T.enum then
        local word = text:lower()
        for _, choice in ipairs(self:Choices()) do
            if choice.text:lower() == word or tostring(choice.value):lower() == word then return choice.value end
        end
        return nil, E.unknownChoice
    end
    return text
end

---The row's value to sort by: a number, a folded string, a choice's folded text, 0 or 1 for a
---boolean, nil when blank.
---@param row LibDataGridRow
---@return LibDataGridValue?
function ColumnMixin:SortValue(row)
    local value = self:Value(row)
    if value == nil or lib.IsBlank(value) then return nil end
    if self.type == T.boolean then return value and 1 or 0 end
    if self.type == T.enum then return self:FormatValue(value):lower() end
    return self:Fold(value)
end
