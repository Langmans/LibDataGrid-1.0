-- A tree back into filter text, in the words and labels the parser reads, so the text parses into
-- the same tree. A nested group of more than one is bracketed; a group of one is that one; a
-- condition that is not finished is left out.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local takes = lib.takes

-- A value that needs no quotes: what the parser reads as a bare value.
local BARE = '^[^%s%(%)%[%],&|!"]+$'

---A value as text, quoted when the parser would not read it bare.
---@param column LibDataGridColumnMixin
---@param value LibDataGridValue
---@return string
local function Quote(column, value)
    local text = column:FormatValue(value)
    if text:find(BARE) then return text end
    return '"' .. text:gsub('[\\"]', "\\%0") .. '"'
end

---@param schema LibDataGridSchema
---@param node LibDataGridCondition
---@return string?
local function FormatCondition(schema, node)
    if not schema:IsComplete(node) then return nil end
    local column = schema:Column(node.column) --[[@as LibDataGridColumnMixin]]
    local op = lib.operators[node.op]
    local text = "[" .. column.label .. "] " .. op.token
    local value = node.value
    if op.takes == takes.value then
        return text .. " " .. Quote(column, value --[[@as LibDataGridValue]])
    end
    if op.takes ~= takes.list and op.takes ~= takes.range then return text end
    ---@type LibDataGridValue[], string[]
    local items, values = value, {}
    for i, item in ipairs(items) do
        values[i] = Quote(column, item)
    end
    if op.takes == takes.range then return text .. " " .. values[1] .. " AND " .. values[2] end
    return text .. " (" .. table.concat(values, ", ") .. ")"
end

---@param schema LibDataGridSchema
---@param node LibDataGridNode
---@param nested boolean?
---@return string?
local function FormatNode(schema, node, nested)
    if not node.children then
        return FormatCondition(schema, node --[[@as LibDataGridCondition]])
    end
    local parts = {}
    for _, child in ipairs(node.children) do
        parts[#parts + 1] = FormatNode(schema, child, true)
    end
    if #parts == 0 then return nil end
    local text = table.concat(parts, node.join == lib.joins["or"] and " OR " or " AND ")
    if #parts > 1 and (nested or node.negate) then text = "(" .. text .. ")" end
    return node.negate and "NOT " .. text or text
end

---@class LibDataGridFormatterMixin
local FormatterMixin = {}
lib.FormatterMixin = FormatterMixin

---The filter text for a tree; "" for a tree with nothing finished in it.
---@param tree LibDataGridGroup
---@return string
function FormatterMixin:Format(tree)
    return FormatNode(self --[[@as LibDataGridSchema]], tree) or ""
end
