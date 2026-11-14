-- A scrollbar beside a list of rows that the owner fills from an offset (rows scrolled past). The
-- list takes the mouse wheel. A plain Slider, so it is the same on every client.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local WIDTH, THUMB = 12, "Interface\\Buttons\\UI-ScrollBar-Knob"

---@class LibDataGridScrollBarMixin: Slider
---@field offset number rows scrolled past
---@field last number the furthest offset
---@field OnScroll fun(offset: number)
local ScrollBarMixin = {}
lib.ScrollBarMixin = ScrollBarMixin

---Moves to `offset`, kept within the rows, and tells the owner when that is somewhere new.
---@param offset number
function ScrollBarMixin:ScrollTo(offset)
    offset = math.max(0, math.min(self.last, math.floor(offset + 0.5)))
    if offset == self.offset then return end
    self.offset = offset
    self:SetValue(offset)
    self.OnScroll(offset)
end

---How many rows there are and how many show: the bar shows only when they do not all fit, and the
---offset stays within them. Does not tell the owner, who is filling the rows anyway.
---@param total number
---@param visible number
function ScrollBarMixin:SetRange(total, visible)
    self.last = math.max(0, total - visible)
    -- Before the bar's own range: a smaller range moves the thumb and fires OnValueChanged.
    self.offset = math.min(self.offset, self.last)
    self:SetMinMaxValues(0, self.last)
    self:SetValue(self.offset)
    self:SetShown(self.last > 0)
end

---@param bar LibDataGridScrollBarMixin
---@param value number
local function OnValueChanged(bar, value)
    bar:ScrollTo(value)
end

---A scrollbar on the right of `list`, outside it. OnScroll gets the new offset.
---@param list Frame
---@param OnScroll fun(offset: number)
---@return LibDataGridScrollBarMixin
function lib:CreateScrollBar(list, OnScroll)
    local bar = Mixin(CreateFrame("Slider", nil, list), ScrollBarMixin) --[[@as LibDataGridScrollBarMixin]]
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(WIDTH)
    bar:SetPoint("TOPLEFT", list, "TOPRIGHT", 2, 0)
    bar:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 2, 0)
    bar:SetValueStep(1)
    bar:SetObeyStepOnDrag(true)
    bar:SetThumbTexture(THUMB)
    bar.offset, bar.last, bar.OnScroll = 0, 0, OnScroll
    bar:SetScript("OnValueChanged", OnValueChanged)
    list:EnableMouseWheel(true)
    ---@param _ Frame
    ---@param delta number 1 up, -1 down
    list:SetScript("OnMouseWheel", function(_, delta)
        bar:ScrollTo(bar.offset - delta)
    end)
    return bar
end

lib.SCROLLBAR_WIDTH = WIDTH
