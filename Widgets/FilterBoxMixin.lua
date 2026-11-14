-- The filter box: the view's filter as text in an edit box, applied with Enter or Apply. Text that
-- does not parse leaves the filter as it was; the parser's message shows under the box and the
-- text it is about is highlighted. Escape goes back to the view's filter. A filter set elsewhere
-- shows here too, unless the box is being typed in.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local ROW, HINT, BUTTON = 22, 16, 70
local ERROR_COLOUR = { 1, 0.3, 0.3 }

---@class LibDataGridFilterBoxMixin: Frame, LibDataGridWidget
---@field view LibDataGridView
---@field skin LibDataGridSkinMixin
---@field edit EditBox
---@field apply Button
---@field open Button opens the Builder
---@field hint FontString
---@field builder LibDataGridBuilderMixin? made when first opened
local FilterBoxMixin = {}
lib.FilterBoxMixin = FilterBoxMixin

---Opens the Builder on the view's filter; the box keeps one, made the first time.
function FilterBoxMixin:OpenBuilder()
    local builder = self.builder or lib:CreateBuilder(self.view, self.skin)
    self.builder = builder
    builder:Open()
end

---Shows the view's filter and drops the hint.
function FilterBoxMixin:Reset()
    self.edit:SetText(self.view:GetFilterText())
    self.hint:Hide()
end

---Applies the box's text to the view, or shows why it cannot.
function FilterBoxMixin:Apply()
    local ok, err = self.view:SetFilterText(self.edit:GetText())
    if ok then
        self.edit:ClearFocus()
        self:Reset()
        return
    end
    ---@cast err LibDataGridError
    self.hint:SetText(err.message)
    self.hint:Show()
    -- The edit box counts from 0 and stops before `stop`; the parser counts from 1, to `finish`.
    self.edit:SetFocus()
    self.edit:SetCursorPosition(err.pos - 1)
    self.edit:HighlightText(err.pos - 1, err.finish)
end

---@param event string
function FilterBoxMixin:OnViewChanged(event)
    if event == lib.events.FilterChanged and not self.edit:HasFocus() then self:Reset() end
end

---@param edit EditBox
local function OnEnterPressed(edit)
    (edit:GetParent() --[[@as LibDataGridFilterBoxMixin]]):Apply()
end

---@param edit EditBox
local function OnEscapePressed(edit)
    edit:ClearFocus();
    (edit:GetParent() --[[@as LibDataGridFilterBoxMixin]]):Reset()
end

---@param edit EditBox
---@param userInput boolean
local function OnTextChanged(edit, userInput)
    if userInput then
        (edit:GetParent() --[[@as LibDataGridFilterBoxMixin]]).hint:Hide()
    end
end

---@param button Button
local function OnApplyClick(button)
    (button:GetParent() --[[@as LibDataGridFilterBoxMixin]]):Apply()
end

---@param button Button
local function OnOpenClick(button)
    (button:GetParent() --[[@as LibDataGridFilterBoxMixin]]):OpenBuilder()
end

---A filter box for a view, with the caller's mixins over FilterBoxMixin. The owner sets its width
---and places it; it is two rows high (the box, and the hint under it).
---@param parent Frame
---@param view LibDataGridView
---@param skin LibDataGridSkinMixin?
---@param ... table
---@return LibDataGridFilterBoxMixin
function lib:CreateFilterBox(parent, view, skin, ...)
    local box = Mixin(CreateFrame("Frame", nil, parent), FilterBoxMixin, ...) --[[@as LibDataGridFilterBoxMixin]]
    box.view, box.skin = view, skin or lib.SkinMixin
    box:SetHeight(ROW + HINT)

    box.open = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    box.open:SetSize(BUTTON, ROW)
    box.open:SetPoint("TOPRIGHT")
    box.open:SetText(lib.L.BUILDER)
    box.open:SetScript("OnClick", OnOpenClick)

    box.apply = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    box.apply:SetSize(BUTTON, ROW)
    box.apply:SetPoint("RIGHT", box.open, "LEFT", -4, 0)
    box.apply:SetText(lib.L.APPLY)
    box.apply:SetScript("OnClick", OnApplyClick)

    box.edit = CreateFrame("EditBox", nil, box, "InputBoxTemplate")
    box.edit:SetHeight(ROW)
    box.edit:SetPoint("TOPLEFT", 6, 0)
    box.edit:SetPoint("RIGHT", box.apply, "LEFT", -6, 0)
    box.edit:SetAutoFocus(false)
    box.edit:SetScript("OnEnterPressed", OnEnterPressed)
    box.edit:SetScript("OnEscapePressed", OnEscapePressed)
    box.edit:SetScript("OnTextChanged", OnTextChanged)

    box.hint = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    box.hint:SetPoint("TOPLEFT", box.edit, "BOTTOMLEFT", 0, -2)
    box.hint:SetPoint("RIGHT")
    box.hint:SetJustifyH("LEFT")
    box.hint:SetTextColor(ERROR_COLOUR[1], ERROR_COLOUR[2], ERROR_COLOUR[3])

    box.skin:EditBox(box.edit)
    box.skin:Button(box.apply)
    box.skin:Button(box.open)
    box.skin:Font(box.hint)
    view:AddWidget(box)
    box:Reset()
    return box
end
