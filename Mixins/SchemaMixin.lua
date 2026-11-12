-- A schema: the columns of a list, and what can be done with a filter over them. It is the parser,
-- the formatter and the compiler mixed together, plus the columns they share.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local takes = lib.takes
local NONE = {}

---@class LibDataGridSchemaMixin: LibDataGridParserMixin, LibDataGridFormatterMixin, LibDataGridCompilerMixin
---@field columns LibDataGridColumnMixin[]
---@field byKey table<string, LibDataGridColumnMixin>
local SchemaMixin = {}
Mixin(SchemaMixin, lib.ParserMixin, lib.FormatterMixin, lib.CompilerMixin)
lib.SchemaMixin = SchemaMixin

---@param defs LibDataGridColumnDef[]
function SchemaMixin:Init(defs)
    self.columns, self.byKey = {}, {}
    for i, def in ipairs(defs) do
        local column = CreateFromMixins(lib.ColumnMixin, def.mixin or NONE) --[[@as LibDataGridColumnMixin]]
        column:Init(def)
        self.columns[i], self.byKey[column.key] = column, column
    end
end

---The column with this key.
---@param key string
---@return LibDataGridColumnMixin?
function SchemaMixin:Column(key)
    return self.byKey[key]
end

---The column with this label or key, in any case: how filter text names one.
---@param name string
---@return LibDataGridColumnMixin?
function SchemaMixin:Find(name)
    name = name:lower()
    for _, column in ipairs(self.columns) do
        if column.label:lower() == name or column.key:lower() == name then return column end
    end
    return nil
end

---Whether a condition says something: a known column, an operator its type has, and the value,
---list or both ends the operator takes.
---@param node LibDataGridCondition
---@return boolean
function SchemaMixin:IsComplete(node)
    local column, op = self.byKey[node.column], lib.operators[node.op]
    if not column or not op or not op.types[column.type] then return false end
    local value = node.value
    if op.takes == takes.value then return value ~= nil end
    if op.takes == takes.list then return type(value) == "table" and #value > 0 end
    if op.takes == takes.range then return type(value) == "table" and value[2] ~= nil end
    return true
end

---A view over this schema's rows, with the caller's mixins over the view's own.
---@param ... table
---@return LibDataGridView
function SchemaMixin:NewView(...)
    local view = CreateFromMixins(lib.ViewMixin, ...) --[[@as LibDataGridView]]
    view:Init(self --[[@as LibDataGridSchema]])
    return view
end

---A schema for these columns, with the caller's mixins over the schema's own.
---@param defs LibDataGridColumnDef[]
---@param ... table
---@return LibDataGridSchema
function lib:NewSchema(defs, ...)
    local schema = CreateFromMixins(SchemaMixin, ...) --[[@as LibDataGridSchema]]
    schema:Init(defs)
    return schema
end
