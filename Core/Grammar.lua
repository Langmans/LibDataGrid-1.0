-- The operators, once: how each is written, what it takes, which column types have it, and its
-- test (a strategy per operator). The parser, the formatter, the compiler and the Builder all
-- read this table, so an operator cannot exist in one of them and not in another.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local T = lib.types
local ORDERED = { [T.number] = true, [T.date] = true }
local ANY = { [T.number] = true, [T.string] = true, [T.enum] = true, [T.boolean] = true, [T.date] = true }
local TEXT = { [T.string] = true }
local LIST = { [T.string] = true, [T.enum] = true }
local BLANKABLE = { [T.number] = true, [T.string] = true, [T.enum] = true, [T.date] = true }

-- What an operator takes after it: one value, a list in brackets, two values joined by AND
-- (BETWEEN, as MySQL writes it), or nothing.
lib.takes = { value = "value", list = "list", range = "range" }
local V, L, R = lib.takes.value, lib.takes.list, lib.takes.range

-- The tests. `a` is the row's value and `b` the condition's, both folded (ColumnMixin:Fold); a
-- list's `b` is a set of folded values, a range's its two ends. A test sees no blank `a` except
-- the blank tests' own: every other test fails on a blank value, so a negative operator
-- (`negates`) passes it.

---@param a LibDataGridValue?
---@return boolean
local function IsBlank(a)
    return a == nil or a == ""
end

---@param a LibDataGridValue
---@param b LibDataGridValue
---@return boolean
local function Equal(a, b)
    return a == b
end

---@param a number
---@param b number
---@return boolean
local function Greater(a, b)
    return a > b
end

---@param a number
---@param b number
---@return boolean
local function AtLeast(a, b)
    return a >= b
end

---@param a number
---@param b number
---@return boolean
local function Less(a, b)
    return a < b
end

---@param a number
---@param b number
---@return boolean
local function AtMost(a, b)
    return a <= b
end

---Both ends in range, as MySQL's BETWEEN.
---@param a number
---@param b number[]
---@return boolean
local function Between(a, b)
    return a >= b[1] and a <= b[2]
end

---@param a string
---@param b string
---@return boolean
local function Contains(a, b)
    return a:find(b, 1, true) ~= nil
end

---@param a string
---@param b string
---@return boolean
local function StartsWith(a, b)
    return a:sub(1, #b) == b
end

---@param a string
---@param b string
---@return boolean
local function EndsWith(a, b)
    return b == "" or a:sub(-#b) == b
end

---@param a LibDataGridValue
---@param b table<LibDataGridValue, boolean>
---@return boolean
local function InList(a, b)
    return b[a] == true
end

-- stylua: ignore
---@type LibDataGridOperator[]
lib.grammar = {
    { id = "eq", token = "=", label = "equals", takes = V, types = ANY, test = Equal },
    { id = "ne", token = "!=", label = "does not equal", takes = V, types = ANY, negates = "eq" },
    { id = "gt", token = ">", label = "greater than", takes = V, types = ORDERED, test = Greater },
    { id = "ge", token = ">=", label = "at least", takes = V, types = ORDERED, test = AtLeast },
    { id = "lt", token = "<", label = "less than", takes = V, types = ORDERED, test = Less },
    { id = "le", token = "<=", label = "at most", takes = V, types = ORDERED, test = AtMost },
    { id = "between", token = "BETWEEN", label = "between", takes = R, types = ORDERED, test = Between },
    { id = "notBetween", token = "NOT BETWEEN", label = "not between", takes = R, types = ORDERED, negates = "between" },
    { id = "contains", token = "CONTAINS", label = "contains", takes = V, types = TEXT, test = Contains },
    { id = "notContains", token = "NOT CONTAINS", label = "does not contain", takes = V, types = TEXT, negates = "contains" },
    { id = "startsWith", token = "STARTS WITH", label = "starts with", takes = V, types = TEXT, test = StartsWith },
    { id = "endsWith", token = "ENDS WITH", label = "ends with", takes = V, types = TEXT, test = EndsWith },
    { id = "inList", token = "IN", label = "is one of", takes = L, types = LIST, test = InList },
    { id = "notInList", token = "NOT IN", label = "is none of", takes = L, types = LIST, negates = "inList" },
    { id = "blank", token = "IS BLANK", label = "is blank", types = BLANKABLE, blank = true, test = IsBlank },
    { id = "notBlank", token = "IS NOT BLANK", label = "is not blank", types = BLANKABLE, blank = true, negates = "blank" },
}

-- Each operator by id, and the ids by name (lib.ops.eq) for callers building a tree. A negative
-- operator's test is its opposite's, turned round.
lib.operators, lib.ops = {}, {}
for _, op in ipairs(lib.grammar) do
    lib.operators[op.id], lib.ops[op.id] = op, op.id
end
for _, op in ipairs(lib.grammar) do
    if op.negates then
        local test = lib.operators[op.negates].test
        ---@param a LibDataGridValue?
        ---@param b LibDataGridOperand?
        ---@return boolean
        op.test = function(a, b)
            return not test(a, b)
        end
    end
end

-- The operators as the parser tries them: longest token first, so `>=` is not read as `>`.
lib.tokens = {}
for i, op in ipairs(lib.grammar) do
    lib.tokens[i] = op
end
---@param a LibDataGridOperator
---@param b LibDataGridOperator
---@return boolean
local function LongestFirst(a, b)
    if #a.token ~= #b.token then return #a.token > #b.token end
    return a.id < b.id
end
table.sort(lib.tokens, LongestFirst)

-- Each type's operators in the table's order, built when first asked for.
---@type table<string, LibDataGridOperator[]>
local byType = {}

---The operators a column of this type has, in the table's order; the same list each time.
---@param type string
---@return LibDataGridOperator[]
function lib.OperatorsFor(type)
    local list = byType[type]
    if not list then
        list = {}
        for _, op in ipairs(lib.grammar) do
            if op.types[type] then list[#list + 1] = op end
        end
        byType[type] = list
    end
    return list
end

lib.IsBlank = IsBlank
