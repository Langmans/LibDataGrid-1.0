-- The grid: a header row and, under it, the rows that pass the view's filter in the view's order,
-- as many as fit, with a scrollbar for the rest. A header click sorts by that column (up, down,
-- off); with Ctrl it adds the column as the next key, and the headers show the order 1, 2, 3.
-- Columns are added the way Blizzard's TableBuilder adds them (fixed width, or a share of what is
-- left), without needing it: Classic Era has no TableBuilder.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local HEADER, ROW, PAD = 20, 18, 4
local ARROW = "Interface\\Buttons\\UI-SortArrow"
local HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"
-- The arrow's texture points down; flipped, it points up.
local DOWN, UP = { 0, 0.5625, 0, 1 }, { 0, 0.5625, 1, 0 }

---@class LibDataGridGridColumn
---@field column LibDataGridColumnMixin
---@field width number? fixed
---@field weight number? a share of what the fixed columns leave

---@class LibDataGridGridHead: Button
---@field key string
---@field label FontString
---@field arrow Texture
---@field order FontString

---@class LibDataGridGridLine: Button
---@field cells FontString[]
---@field row LibDataGridRow?

---@class LibDataGridGridMixin: Frame, LibDataGridWidget
---@field view LibDataGridView
---@field skin LibDataGridSkinMixin
---@field columns LibDataGridGridColumn[]
---@field heads LibDataGridGridHead[]
---@field lines LibDataGridGridLine[]
---@field body Frame
---@field bar LibDataGridScrollBarMixin
---@field rows LibDataGridRow[] every row, as the owner gave them
---@field shown LibDataGridRow[] the rows that pass, in order
---@field count number how many pass
local GridMixin = {}
lib.GridMixin = GridMixin

---A clicked row; does nothing unless a caller's mixin says otherwise.
---@param row LibDataGridRow
---@param button string
function GridMixin:OnRowClick(row, button) end

---@param head LibDataGridGridHead
local function OnHeadClick(head)
    local grid = head:GetParent() --[[@as LibDataGridGridMixin]]
    grid.view:ToggleSort(head.key, IsControlKeyDown())
end

---@param line LibDataGridGridLine
---@param button string
local function OnLineClick(line, button)
    local body = line:GetParent() --[[@as Frame]]
    local grid = body:GetParent() --[[@as LibDataGridGridMixin]]
    grid:OnRowClick(line.row --[[@as LibDataGridRow]], button)
end

---@param key string
---@return LibDataGridColumnMixin
function GridMixin:FindColumn(key)
    local column = self.view.schema:Column(key)
    if not column then error(('LibDataGrid-1.0: no column "%s" in the schema'):format(key), 0) end
    return column
end

---@param entry LibDataGridGridColumn
function GridMixin:AddColumn(entry)
    self.columns[#self.columns + 1] = entry
    local head = CreateFrame("Button", nil, self) --[[@as LibDataGridGridHead]]
    head.key = entry.column.key
    head:SetHeight(HEADER)
    head.label = head:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    head.label:SetPoint("LEFT", PAD, 0)
    head.label:SetJustifyH("LEFT")
    head.label:SetText(entry.column.label)
    head.arrow = head:CreateTexture(nil, "ARTWORK")
    head.arrow:SetSize(9, 8)
    head.arrow:SetPoint("LEFT", head.label, "RIGHT", 3, 0)
    head.arrow:SetTexture(ARROW)
    head.order = head:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    head.order:SetPoint("LEFT", head.arrow, "RIGHT", 1, 0)
    head:SetHighlightTexture(HIGHLIGHT, "ADD")
    head:SetScript("OnClick", OnHeadClick)
    self.skin:Font(head.label)
    self.heads[#self.heads + 1] = head
    self:Layout()
end

---A column of this width.
---@param key string
---@param width number
function GridMixin:AddFixedWidthColumn(key, width)
    self:AddColumn({ column = self:FindColumn(key), width = width })
end

---A column sharing, by weight (1 when not given), what the fixed columns leave.
---@param key string
---@param weight number?
function GridMixin:AddFillColumn(key, weight)
    self:AddColumn({ column = self:FindColumn(key), weight = weight or 1 })
end

---Places the headers and cells by the columns' widths, and makes as many lines as fit.
function GridMixin:Layout()
    local fixed, weights = 0, 0
    for _, entry in ipairs(self.columns) do
        fixed, weights = fixed + (entry.width or 0), weights + (entry.weight or 0)
    end
    local left = math.max(0, self:GetWidth() - lib.SCROLLBAR_WIDTH - 2 - fixed)
    local visible = math.max(0, math.floor((self:GetHeight() - HEADER) / ROW))
    for index = #self.lines + 1, visible do
        local line = CreateFrame("Button", nil, self.body) --[[@as LibDataGridGridLine]]
        line:SetHeight(ROW)
        line:SetPoint("TOPLEFT", 0, -(index - 1) * ROW)
        line:SetPoint("RIGHT")
        line:SetHighlightTexture(HIGHLIGHT, "ADD")
        line:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        line:SetScript("OnClick", OnLineClick)
        line.cells = {}
        self.lines[index] = line
    end
    local x = 0
    for i, entry in ipairs(self.columns) do
        local width = entry.width or left * entry.weight / weights
        self.heads[i]:SetWidth(width)
        self.heads[i]:ClearAllPoints()
        self.heads[i]:SetPoint("TOPLEFT", x, 0)
        for _, line in ipairs(self.lines) do
            local cell = line.cells[i]
            if not cell then
                cell = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                cell:SetJustifyH("LEFT")
                cell:SetWordWrap(false)
                self.skin:Font(cell)
                line.cells[i] = cell
            end
            cell:SetWidth(width - 2 * PAD)
            cell:ClearAllPoints()
            cell:SetPoint("LEFT", x + PAD, 0)
        end
        x = x + width
    end
    self.visible = visible
    self:Draw()
end

---Fills the lines from the scrolled offset, and the headers' sort markers.
function GridMixin:Draw()
    self.bar:SetRange(self.count, self.visible)
    for index = 1, self.visible do
        local line = self.lines[index]
        local row = self.shown[index + self.bar.offset]
        line.row = row
        line:SetShown(row ~= nil)
        if row then
            for i, entry in ipairs(self.columns) do
                line.cells[i]:SetText(entry.column:CellText(row))
            end
        end
    end
    for index = self.visible + 1, #self.lines do
        self.lines[index]:Hide()
    end
    local keys = #self.view.sort
    for _, head in ipairs(self.heads) do
        local at, descending = self.view:SortIndex(head.key)
        head.arrow:SetShown(at ~= nil)
        head.arrow:SetTexCoord(unpack(descending and DOWN or UP))
        head.order:SetText(at and tostring(at) or "")
        head.order:SetShown(at ~= nil and keys > 1)
    end
end

---Runs the view over the rows again and draws them.
function GridMixin:Refresh()
    local _, count = self.view:Refresh(self.rows, self.shown)
    self.count = count
    self:Draw()
end

---The rows the grid shows from: every row, as the owner keeps them. Call again, or Refresh,
---after they change.
---@param rows LibDataGridRow[]
function GridMixin:SetRows(rows)
    self.rows = rows
    self:Refresh()
end

---@param event string
function GridMixin:OnViewChanged(event)
    self:Refresh()
end

---@param grid LibDataGridGridMixin
local function OnSizeChanged(grid)
    grid:Layout()
end

---A grid over a view, with the caller's mixins over GridMixin. The owner sets its size, adds the
---columns, and hands it the rows.
---@param parent Frame
---@param view LibDataGridView
---@param skin LibDataGridSkinMixin?
---@param ... table
---@return LibDataGridGridMixin
function lib:CreateGrid(parent, view, skin, ...)
    local grid = Mixin(CreateFrame("Frame", nil, parent), GridMixin, ...) --[[@as LibDataGridGridMixin]]
    grid.view, grid.skin = view, skin or lib.SkinMixin
    grid.columns, grid.heads, grid.lines, grid.rows, grid.shown, grid.count = {}, {}, {}, {}, {}, 0
    grid.visible = 0
    grid.body = CreateFrame("Frame", nil, grid)
    grid.body:SetPoint("TOPLEFT", 0, -HEADER)
    grid.body:SetPoint("BOTTOMRIGHT", -lib.SCROLLBAR_WIDTH - 2, 0)
    grid.bar = lib:CreateScrollBar(grid.body, function()
        grid:Draw()
    end)
    grid:SetScript("OnSizeChanged", OnSizeChanged)
    view:AddWidget(grid)
    return grid
end
