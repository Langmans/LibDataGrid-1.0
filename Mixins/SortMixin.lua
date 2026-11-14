-- Sorting on several keys, each up or down, stable: rows that tie on every key keep the order they
-- came in. Blank values go last either way. A click on a column head goes up, down, then off; with
-- Ctrl it adds a key or turns one, leaving the others.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

---@class LibDataGridSortMixin
---@field schema LibDataGridSchema
---@field sort LibDataGridSortKey[]
---@field sortColumns LibDataGridColumnMixin[]
---@field sortDescending table<number, boolean?>
---@field sortValues table<LibDataGridRow, LibDataGridValue?>[]
---@field order table<LibDataGridRow, number>
---@field compare fun(a: LibDataGridRow, b: LibDataGridRow): boolean
---@field Changed fun(self: LibDataGridSortMixin, event: string)
local SortMixin = {}
lib.SortMixin = SortMixin

function SortMixin:InitSort()
    self.sort = {}
    -- Built for each sort and reused: the sorted columns, which go down, each one's value per row,
    -- and each row's place before sorting.
    self.sortColumns, self.sortDescending, self.sortValues, self.order = {}, {}, {}, {}
    ---@param a LibDataGridRow
    ---@param b LibDataGridRow
    ---@return boolean
    self.compare = function(a, b)
        return self:Compare(a, b)
    end
end

---@param sort LibDataGridSortKey[]
function SortMixin:SetSort(sort)
    self.sort = lib.Copy(sort) --[[@as LibDataGridSortKey[] ]]
    self:Changed(lib.events.SortChanged)
end

---@return LibDataGridSortKey[]
function SortMixin:GetSort()
    return lib.Copy(self.sort) --[[@as LibDataGridSortKey[] ]]
end

---Where this key stands in the sort, and whether it goes down; nil when it is not sorted on.
---@param key string
---@return number? index
---@return boolean? descending
function SortMixin:SortIndex(key)
    for i, entry in ipairs(self.sort) do
        if entry.key == key then return i, entry.descending == true end
    end
    return nil, nil
end

---A click on a column head: up, down, then off. Without `additive` the other keys go; with it
---(Ctrl) they stay and a new key goes last.
---@param key string
---@param additive boolean?
function SortMixin:ToggleSort(key, additive)
    local sort = self.sort
    local index, descending = self:SortIndex(key)
    if not additive then
        wipe(sort)
        if not descending then sort[1] = { key = key, descending = index and true or nil } end
    elseif not index then
        sort[#sort + 1] = { key = key }
    elseif descending then
        table.remove(sort, index)
    else
        sort[index].descending = true
    end
    self:Changed(lib.events.SortChanged)
end

---Whether row a goes before row b. Needs SortRows to have filled in the values; one column's
---values are all numbers or all strings.
---@param a LibDataGridRow
---@param b LibDataGridRow
---@return boolean
function SortMixin:Compare(a, b)
    for i = 1, #self.sortColumns do
        local values = self.sortValues[i] --[[@as table<LibDataGridRow, number?>]]
        local va, vb = values[a], values[b]
        if va ~= vb then
            if va == nil or vb == nil then return vb == nil end
            if self.sortDescending[i] then return va > vb end
            return va < vb
        end
    end
    return self.order[a] < self.order[b]
end

---Sorts the first n rows of a list in place; `order` must hold each row's place in it.
---@param list LibDataGridRow[]
---@param n number
function SortMixin:SortRows(list, n)
    local columns, descending = self.sortColumns, self.sortDescending
    wipe(columns)
    wipe(descending)
    for _, entry in ipairs(self.sort) do
        local column = self.schema:Column(entry.key)
        if column then
            columns[#columns + 1] = column
            descending[#columns] = entry.descending
        end
    end
    if #columns == 0 then return end
    for i, column in ipairs(columns) do
        local values = self.sortValues[i] or {}
        wipe(values)
        self.sortValues[i] = values
        for r = 1, n do
            values[list[r]] = column:SortValue(list[r])
        end
    end
    table.sort(list, self.compare)
end
