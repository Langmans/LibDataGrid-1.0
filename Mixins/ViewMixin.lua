-- A view: one schema's filter and sort over a list of rows. Refresh fills a list with the rows
-- that pass, in order. The filter is set as text or as a tree; a change to either, or to the sort,
-- goes out as an event through the events adapter (RegistryEventsMixin unless the view was made
-- with another). The library keeps nothing: a caller that wants the filter kept stores the model or
-- the text when it hears FilterChanged.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

---@class LibDataGridViewMixin: LibDataGridRegistryEventsMixin, LibDataGridSortMixin
---@field filter LibDataGridGroup
---@field passes LibDataGridPredicate
---@field widgets LibDataGridWidget[]
local ViewMixin = {}
Mixin(ViewMixin, lib.RegistryEventsMixin, lib.SortMixin)
lib.ViewMixin = ViewMixin

---@param schema LibDataGridSchema
function ViewMixin:Init(schema)
    self.schema = schema
    self.filter = lib.NewFilter()
    self.passes = schema:Compile(self.filter)
    self.widgets = {}
    self:InitEvents()
    self:InitSort()
end

---A widget that shows this view (a filter box, a grid, a builder): it hears every change through
---its OnViewChanged(event), whichever events adapter the view has. Added once however often asked.
---@param widget LibDataGridWidget
function ViewMixin:AddWidget(widget)
    for _, known in ipairs(self.widgets) do
        if known == widget then return end
    end
    self.widgets[#self.widgets + 1] = widget
end

---Something changed: the widgets first, so they show it, then the events adapter.
---@param event string
function ViewMixin:Changed(event)
    for _, widget in ipairs(self.widgets) do
        widget:OnViewChanged(event)
    end
    self:Notify(event)
end

---The view's own filter tree, for a caller that edits it in place and then calls FilterEdited.
---@return LibDataGridGroup
function ViewMixin:GetFilter()
    return self.filter
end

---The filter tree changed in place: use it from now on.
function ViewMixin:FilterEdited()
    self.passes = self.schema:Compile(self.filter)
    self:Changed(lib.events.FilterChanged)
end

---A copy of the filter tree, to keep.
---@return LibDataGridGroup
function ViewMixin:GetFilterModel()
    return lib.Copy(self.filter) --[[@as LibDataGridGroup]]
end

---Filters by a copy of this tree; nil is no filter.
---@param tree LibDataGridGroup?
function ViewMixin:SetFilterModel(tree)
    self.filter = tree and lib.Copy(tree) --[[@as LibDataGridGroup]] or lib.NewFilter()
    self:FilterEdited()
end

---The filter as text, in the schema's labels.
---@return string
function ViewMixin:GetFilterText()
    return self.schema:Format(self.filter)
end

---Filters by this text; when it does not parse, the filter stays as it was.
---@param text string
---@return boolean ok
---@return LibDataGridError? err
function ViewMixin:SetFilterText(text)
    local tree, err = self.schema:Parse(text)
    if not tree then return false, err end
    self.filter = tree
    self:FilterEdited()
    return true
end

---Fills `out` with the rows that pass the filter, sorted, and clears what is left past them.
---@param rows LibDataGridRow[]
---@param out LibDataGridRow[]
---@return LibDataGridRow[] out
---@return number n
function ViewMixin:Refresh(rows, out)
    local passes, order, n = self.passes, wipe(self.order), 0
    for _, row in ipairs(rows) do
        if passes(row) then
            n = n + 1
            out[n], order[row] = row, n
        end
    end
    for i = #out, n + 1, -1 do
        out[i] = nil
    end
    self:SortRows(out, n)
    return out, n
end

-- The last file: this copy of the library is loaded.
lib.pending = nil
