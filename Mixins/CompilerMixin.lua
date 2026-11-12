-- A tree into one function that says whether a row passes (the interpreter's evaluator). Each
-- condition becomes a closure over its column, its operator's test and its folded value, built
-- once, so a refresh runs no parsing and builds no tables. Conditions that are not finished, and
-- groups left with nothing, are left out.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local IsBlank, takes = lib.IsBlank, lib.takes

---@alias LibDataGridPredicate fun(row: LibDataGridRow): boolean

---@param _ LibDataGridRow
---@return boolean
local function PassAll(_)
    return true
end

---@param schema LibDataGridSchema
---@param node LibDataGridCondition
---@return LibDataGridPredicate?
local function CompileCondition(schema, node)
    if not schema:IsComplete(node) then return nil end
    local column = schema:Column(node.column) --[[@as LibDataGridColumnMixin]]
    local op = lib.operators[node.op]
    local test = op.test
    if op.blank then
        ---@param row LibDataGridRow
        ---@return boolean
        local function IsBlankThere(row)
            return test(column:Value(row))
        end
        return IsBlankThere
    end
    ---@type LibDataGridOperand?
    local wanted = column:Fold(node.value --[[@as LibDataGridValue]])
    local values = node.value --[[@as LibDataGridValue[] ]]
    if op.takes == takes.list then
        ---@type table<LibDataGridValue, boolean>
        local set = {}
        for _, value in ipairs(values) do
            local key = column:Fold(value) --[[@as LibDataGridValue]]
            set[key] = true
        end
        wanted = set
    elseif op.takes == takes.range then
        wanted = { column:Fold(values[1]), column:Fold(values[2]) }
    end
    -- A blank value fails every test, so the negative operators pass it.
    local blankPasses = op.negates ~= nil
    ---@param row LibDataGridRow
    ---@return boolean
    local function Passes(row)
        local value = column:Value(row)
        if IsBlank(value) then return blankPasses end
        return test(column:Fold(value), wanted)
    end
    return Passes
end

---@param schema LibDataGridSchema
---@param node LibDataGridNode
---@return LibDataGridPredicate?
local function CompileNode(schema, node)
    if not node.children then
        return CompileCondition(schema, node --[[@as LibDataGridCondition]])
    end
    ---@type LibDataGridPredicate[]
    local tests = {}
    for _, child in ipairs(node.children) do
        tests[#tests + 1] = CompileNode(schema, child)
    end
    local n = #tests
    if n == 0 then return nil end
    -- An OR group stops at the first test that passes, an AND group at the first that fails.
    local any, negate = node.join == lib.joins["or"], node.negate == true
    ---@param row LibDataGridRow
    ---@return boolean
    local function Passes(row)
        for i = 1, n do
            if tests[i](row) == any then return any ~= negate end
        end
        return any == negate
    end
    return Passes
end

---@class LibDataGridCompilerMixin
local CompilerMixin = {}
lib.CompilerMixin = CompilerMixin

---The function that says whether a row passes this tree; every row passes an empty one.
---@param tree LibDataGridGroup
---@return LibDataGridPredicate
function CompilerMixin:Compile(tree)
    return CompileNode(self --[[@as LibDataGridSchema]], tree) or PassAll
end
