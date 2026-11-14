-- A picker: a chip showing its choice, which opens the pick list of its choices under it. One pick
-- list serves every picker. A choice, a second click on the picker, Escape, or the picker hiding
-- closes it. Plain frames, so it is the same on every client (the game's dropdowns are not).

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local HEIGHT, ROWS, ROW_HEIGHT, PAD = 20, 12, 18, 4
local ARROW = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"

---@class LibDataGridPickRow: Button
---@field label FontString
---@field value LibDataGridValue?

---@class LibDataGridPickList: Frame
---@field picker LibDataGridPickerMixin?
---@field rows LibDataGridPickRow[]
---@field inner Frame
---@field bar LibDataGridScrollBarMixin

---@class LibDataGridPickerMixin: Button
---@field label FontString
---@field skin LibDataGridSkinMixin
---@field values LibDataGridValue[]
---@field texts string[]
---@field value LibDataGridValue?
---@field OnPick fun(value: LibDataGridValue)
local PickerMixin = {}
lib.PickerMixin = PickerMixin

---Fills the pick list's rows from its picker's choices, from the scrolled offset on.
---@param list LibDataGridPickList
local function Fill(list)
    local picker = list.picker --[[@as LibDataGridPickerMixin]]
    list.bar:SetRange(#picker.values, ROWS)
    for index, row in ipairs(list.rows) do
        local at = index + list.bar.offset
        row.value = picker.values[at]
        row.label:SetText(picker.texts[at] or "")
        row:SetShown(row.value ~= nil)
    end
end

---@param row LibDataGridPickRow
local function OnRowClick(row)
    local inner = row:GetParent() --[[@as Frame]]
    local list = inner:GetParent() --[[@as LibDataGridPickList]]
    local picker = list.picker --[[@as LibDataGridPickerMixin]]
    list:Hide()
    picker.OnPick(row.value --[[@as LibDataGridValue]])
end

---The pick list, made the first time a picker opens it, in the first picker's skin.
---@param skin LibDataGridSkinMixin
---@return LibDataGridPickList
local function PickList(skin)
    if lib.pickList then return lib.pickList end
    local name = lib.name .. "PickList"
    local list = CreateFrame("Frame", name, UIParent, "BackdropTemplate") --[[@as LibDataGridPickList]]
    list:SetFrameStrata("DIALOG")
    list:SetClampedToScreen(true)
    list:Hide()
    table.insert(UISpecialFrames, name)
    skin:Backdrop(list)
    list.inner = CreateFrame("Frame", nil, list)
    list.inner:SetPoint("TOPLEFT", PAD, -PAD)
    list.inner:SetPoint("BOTTOMRIGHT", -PAD - lib.SCROLLBAR_WIDTH - 2, PAD)
    list.rows = {}
    for index = 1, ROWS do
        local row = CreateFrame("Button", nil, list.inner) --[[@as LibDataGridPickRow]]
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT")
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", 4, 0)
        row.label:SetPoint("RIGHT", -4, 0)
        row.label:SetJustifyH("LEFT")
        skin:Font(row.label)
        row:SetHighlightTexture(HIGHLIGHT, "ADD")
        row:SetScript("OnClick", OnRowClick)
        list.rows[index] = row
    end
    list.bar = lib:CreateScrollBar(list.inner, function()
        Fill(list)
    end)
    lib.pickList = list
    return list
end

---@param picker LibDataGridPickerMixin
local function OnClick(picker)
    local list = PickList(picker.skin)
    if list:IsShown() and list.picker == picker then
        list:Hide()
        return
    end
    list.picker, list.bar.offset = picker, 0
    Fill(list)
    list:SetSize(picker:GetWidth() + lib.SCROLLBAR_WIDTH + 2, math.min(#picker.values, ROWS) * ROW_HEIGHT + 2 * PAD)
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", picker, "BOTTOMLEFT", 0, -2)
    list:Show()
end

---@param picker LibDataGridPickerMixin
local function OnHide(picker)
    local list = lib.pickList
    if list and list.picker == picker then list:Hide() end
end

---The choices, in the order they list, and the one chosen; a value not among them shows as none.
---@param values LibDataGridValue[]
---@param texts string[]
---@param chosen LibDataGridValue?
function PickerMixin:SetChoices(values, texts, chosen)
    self.values, self.texts, self.value = values, texts, nil
    local text = ""
    for index, value in ipairs(values) do
        if value == chosen then
            self.value, text = value, texts[index]
        end
    end
    self.label:SetText(text)
end

---A picker chip; a choice clicked calls OnPick with its value. The owner sets its width.
---@param parent Frame
---@param skin LibDataGridSkinMixin?
---@param OnPick fun(value: LibDataGridValue)
---@return LibDataGridPickerMixin
function lib:CreatePicker(parent, skin, OnPick)
    local picker = Mixin(CreateFrame("Button", nil, parent), PickerMixin) --[[@as LibDataGridPickerMixin]]
    picker.skin = skin or lib.SkinMixin
    picker:SetHeight(HEIGHT)
    picker.skin:Field(picker)
    local arrow = picker:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(12, 12)
    arrow:SetPoint("RIGHT", -4, 0)
    arrow:SetTexture(ARROW)
    picker.label = picker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    picker.label:SetPoint("LEFT", 6, 0)
    picker.label:SetPoint("RIGHT", arrow, "LEFT", -2, 0)
    picker.label:SetJustifyH("LEFT")
    picker.label:SetWordWrap(false)
    picker.skin:Font(picker.label)
    picker:SetHighlightTexture(HIGHLIGHT, "ADD")
    picker.OnPick, picker.values, picker.texts = OnPick, {}, {}
    picker:SetScript("OnClick", OnClick)
    picker:SetScript("OnHide", OnHide)
    return picker
end
