-- Filter text into a tree (an interpreter's parser, by recursive descent). OR binds loosest, then
-- AND, then NOT; brackets make a group that is kept as written. An error says what was wanted and
-- where: { code, pos, finish, message }, positions counted in characters from 1.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local E, takes = lib.errors, lib.takes

-- Characters a value written without quotes may hold.
local BARE = '^[^%s%(%)%[%],&|!"]+'

local MESSAGES = {
    [E.unknownColumn] = "Unknown column %s",
    [E.unclosedColumn] = "Column %s is missing its ]",
    [E.expectedCondition] = "Expected a condition like [Column] = value, found %s",
    [E.expectedOperator] = "Expected an operator, found %s",
    [E.operatorNotForType] = "Operator %s does not work on this column",
    [E.expectedValue] = "Expected a value, found %s",
    [E.unclosedString] = "Text %s is missing its closing quote",
    [E.badNumber] = "Expected a number, found %s",
    [E.badBoolean] = "Expected true or false, found %s",
    [E.badDate] = 'Expected a date like 2026-11-12 or "2026-11-12 18:30", found %s',
    [E.expectedRangeAnd] = "Expected AND between the two ends, found %s",
    [E.unknownChoice] = "Not one of the column's choices: %s",
    [E.expectedList] = "Expected a list in brackets, found %s",
    [E.unclosedList] = 'Expected "," or ")" in the list, found %s',
    [E.unclosedGroup] = 'Expected ")", found %s',
    [E.unexpected] = "Expected AND or OR, found %s",
}

---A token as a pattern on the lower-cased text: any spacing between words, a word ending at a
---word's end.
---@param token string
---@return string
local function Pattern(token)
    local pattern = token:lower():gsub("%p", "%%%0"):gsub("%s+", "%%s+")
    if token:match("%a$") then pattern = pattern .. "%f[^%w]" end
    return "^" .. pattern
end

local OPERATORS = {}
for i, op in ipairs(lib.tokens) do
    OPERATORS[i] = Pattern(op.token)
end
local AND, AND_SIGN = Pattern("and"), Pattern("&")
local OR, OR_SIGN = Pattern("or"), Pattern("|")
local NOT, NOT_SIGN = Pattern("not"), Pattern("!")

-- The text being read, lower-cased, where the reader is, and whose columns. One Parse at a time.
---@type string, string, number, LibDataGridSchema
local src, lower, at, schema

-- The pieces read so far, while SchemaMixin:Tokens asks for them; nil for a plain Parse.
---@type LibDataGridToken[]?
local marks

local K = lib.tokenKinds

---Notes a piece of the text, when Tokens is collecting them.
---@param kind string
---@param start number
---@param finish number
local function Mark(kind, start, finish)
    if marks then marks[#marks + 1] = { kind = kind, start = start, finish = finish } end
end

local function SkipSpace()
    at = src:find("%S", at) or #src + 1
end

---Moves past the token at the reader if it is this one, noting it as `kind` when given.
---@param pattern string
---@param kind string?
---@return boolean
local function Take(pattern, kind)
    SkipSpace()
    local start = at
    local _, finish = lower:find(pattern, at)
    if not finish then return false end
    at = finish + 1
    if kind then Mark(kind, start, finish) end
    return true
end

---Stops the parse: the error for the text from pos to finish, by default the word or the one
---character there.
---@param code string
---@param pos number
---@param finish number?
local function Fail(code, pos, finish)
    finish = finish or select(2, src:find(BARE, pos)) or pos
    local found = pos > #src and "the end" or ('"' .. src:sub(pos, finish) .. '"')
    error({ code = code, pos = pos, finish = finish, message = MESSAGES[code]:format(found) }, 0)
end

---One value as written, quoted or bare, and where it stood.
---@return string text
---@return number start
---@return number finish
local function ReadValue()
    SkipSpace()
    local start = at
    if src:sub(at, at) ~= '"' then
        local _, finish = src:find(BARE, at)
        if not finish then Fail(E.expectedValue, at) end
        ---@cast finish number
        at = finish + 1
        return src:sub(start, finish), start, finish
    end
    local text, i = "", at + 1
    while src:sub(i, i) ~= '"' do
        if src:sub(i, i) == "\\" then i = i + 1 end
        if i > #src then Fail(E.unclosedString, start, #src) end
        text, i = text .. src:sub(i, i), i + 1
    end
    at = i + 1
    return text, start, i
end

---@param column LibDataGridColumnMixin
---@return LibDataGridValue
local function ParseValue(column)
    local text, start, finish = ReadValue()
    local value, code = column:ParseValue(text)
    if code then Fail(code, start, finish) end
    Mark(K.value, start, finish)
    return value --[[@as LibDataGridValue]]
end

---@param column LibDataGridColumnMixin
---@return LibDataGridValue[]
local function ParseList(column)
    SkipSpace()
    if src:sub(at, at) ~= "(" then Fail(E.expectedList, at) end
    Mark(K.bracket, at, at)
    at = at + 1
    local list = {}
    while true do
        list[#list + 1] = ParseValue(column)
        SkipSpace()
        local char = src:sub(at, at)
        if char ~= "," and char ~= ")" then Fail(E.unclosedList, at) end
        Mark(K.bracket, at, at)
        at = at + 1
        if char == ")" then return list end
    end
end

---`[Column] operator value`
---@return LibDataGridCondition
local function ParseCondition()
    SkipSpace()
    if src:sub(at, at) ~= "[" then Fail(E.expectedCondition, at) end
    local close = src:find("]", at + 1, true)
    if not close then Fail(E.unclosedColumn, at, #src) end
    ---@cast close number
    local column = schema:Find(src:sub(at + 1, close - 1))
    if not column then Fail(E.unknownColumn, at + 1, close - 1) end
    ---@cast column LibDataGridColumnMixin
    Mark(K.column, at, close)
    at = close + 1

    SkipSpace()
    ---@type number, LibDataGridOperator?
    local start, op = at, nil
    for i, pattern in ipairs(OPERATORS) do
        if Take(pattern) then
            op = lib.tokens[i]
            break
        end
    end
    if not op then Fail(E.expectedOperator, start) end
    ---@cast op LibDataGridOperator
    if not op.types[column.type] then Fail(E.operatorNotForType, start, at - 1) end
    Mark(K.operator, start, at - 1)

    ---@type LibDataGridCondition
    local condition = { column = column.key, op = op.id }
    if op.takes == takes.value then
        condition.value = ParseValue(column)
    elseif op.takes == takes.list then
        condition.value = ParseList(column)
    elseif op.takes == takes.range then
        local low = ParseValue(column)
        if not (Take(AND, K.keyword) or Take(AND_SIGN, K.keyword)) then Fail(E.expectedRangeAnd, at) end
        condition.value = { low, ParseValue(column) }
    end
    return condition
end

---@type fun(): LibDataGridNode
local ParseOr

---NOT, a group in brackets, or a condition.
---@return LibDataGridNode
local function ParseUnary()
    if Take(NOT, K.keyword) or Take(NOT_SIGN, K.keyword) then
        local node = ParseUnary()
        if node.children and not node.negate then
            node.negate = true
            return node
        end
        return { join = lib.joins["and"], negate = true, children = { node } }
    end
    if Take("^%(", K.bracket) then
        local node = ParseOr()
        if not Take("^%)", K.bracket) then Fail(E.unclosedGroup, at) end
        return node
    end
    return ParseCondition()
end

---A run of nodes joined by one word: a group of them, or the one node.
---@param join string
---@param word string
---@param sign string
---@param Next fun(): LibDataGridNode
---@return LibDataGridNode
local function ParseJoined(join, word, sign, Next)
    local children = { Next() }
    while Take(word, K.keyword) or Take(sign, K.keyword) do
        children[#children + 1] = Next()
    end
    if #children == 1 then return children[1] end
    return { join = join, children = children }
end

---@return LibDataGridNode
local function ParseAnd()
    return ParseJoined(lib.joins["and"], AND, AND_SIGN, ParseUnary)
end

---@return LibDataGridNode
ParseOr = function()
    return ParseJoined(lib.joins["or"], OR, OR_SIGN, ParseAnd)
end

---The whole text: always a group, empty for no text.
---@return LibDataGridGroup
local function ParseFilter()
    SkipSpace()
    if at > #src then return lib.NewFilter() end
    local node = ParseOr()
    SkipSpace()
    if at <= #src then Fail(E.unexpected, at) end
    if node.children then
        return node --[[@as LibDataGridGroup]]
    end
    return { join = lib.joins["and"], children = { node } }
end

---@class LibDataGridParserMixin
local ParserMixin = {}
lib.ParserMixin = ParserMixin

---The tree this filter text stands for, or nil and why not.
---@param text string
---@return LibDataGridGroup? tree
---@return LibDataGridError? err
function ParserMixin:Parse(text)
    src, lower, at, schema = text, text:lower(), 1, self --[[@as LibDataGridSchema]]
    local ok, result = pcall(ParseFilter)
    if ok then return result end
    if type(result) ~= "table" then error(result, 0) end
    return nil, result --[[@as LibDataGridError]]
end

---The pieces of filter text as the parser reads them, for syntax highlighting: each with its kind
---(lib.tokenKinds) and the characters it covers. Text that does not parse is one error piece from
---where it stops making sense to the end; the error comes second.
---@param text string
---@return LibDataGridToken[] tokens
---@return LibDataGridError? err
function ParserMixin:Tokens(text)
    marks = {}
    local _, err = self:Parse(text)
    local tokens = marks
    marks = nil
    if err and err.pos <= #text then tokens[#tokens + 1] = { kind = K.error, start = err.pos, finish = #text } end
    return tokens, err
end
