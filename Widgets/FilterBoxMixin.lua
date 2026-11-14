-- The filter box: the view's filter as text in an edit box, applied with Enter or Apply. Text that
-- does not parse leaves the filter as it was; the parser's message shows under the box and the
-- text it is about is highlighted. Escape goes back to the view's filter. A filter set elsewhere
-- shows here too, unless the box is being typed in. While it is not being typed in, the text is
-- coloured by kind (the skin's Highlight); the box keeps the plain text apart, and that is what it
-- applies.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local ROW, HINT, BUTTON = 22, 16, 70
local ERROR_COLOUR = { 1, 0.3, 0.3 }
local CLEAR, CLEAR_ICON = 14, "Interface\\FriendsFrame\\ClearBroadcastIcon"

---@class LibDataGridFilterBoxMixin: Frame, LibDataGridWidget
---@field view LibDataGridView
---@field skin LibDataGridSkinMixin
---@field edit EditBox
---@field apply Button
---@field open Button opens the Builder
---@field hint FontString
---@field clear Button the x that empties the filter
---@field builder LibDataGridBuilderMixin? made when first opened
---@field filterText string the text as typed; the edit box may show it coloured
local FilterBoxMixin = {}
lib.FilterBoxMixin = FilterBoxMixin

---Opens the Builder on the view's filter; the box keeps one, made the first time.
function FilterBoxMixin:OpenBuilder()
    local builder = self.builder or lib:CreateBuilder(self.view, self.skin)
    self.builder = builder
    builder:Open()
end

---The filter text in the box as typed: never the coloured text the box shows.
---@return string
function FilterBoxMixin:GetText()
    return self.filterText
end

---Puts filter text in the box.
---@param text string
function FilterBoxMixin:SetText(text)
    self.filterText = text
    self:ShowText()
end

---Shows the text: plain while the box is being typed in, so the cursor and a marked error sit
---where they should; coloured by kind otherwise. The clear button shows when there is text.
function FilterBoxMixin:ShowText()
    local text, edit = self.filterText, self.edit
    if edit:HasFocus() then
        edit:SetText(lib.ToEditBox(text))
    else
        edit:SetText(self.skin:Highlight(self.view.schema, text))
        -- From its start: the edit box keeps a long text scrolled to wherever the cursor was.
        edit:SetCursorPosition(0)
    end
    self.clear:SetShown(text ~= "")
end

---Where character `pos` of the text sits in the edit box, counted from 0, every | before it
---taking two there.
---@param pos number
---@return number
function FilterBoxMixin:EditPosition(pos)
    local _, bars = self.filterText:sub(1, pos - 1):gsub("|", "")
    return pos - 1 + bars
end

---Shows the view's filter and drops the hint.
function FilterBoxMixin:Reset()
    self:SetText(self.view:GetFilterText())
    self.hint:Hide()
end

---Empties the filter.
function FilterBoxMixin:Clear()
    self.edit:ClearFocus()
    self.view:SetFilterModel(nil)
end

---Applies the box's text to the view, or shows why it cannot.
function FilterBoxMixin:Apply()
    local ok, err = self.view:SetFilterText(self.filterText)
    if ok then
        self.edit:ClearFocus()
        self:Reset()
        return
    end
    ---@cast err LibDataGridError
    self.hint:SetText(err.message)
    self.hint:Show()
    -- The edit box stops before `stop`; the parser's `finish` is the last character it is about.
    self.edit:SetFocus()
    self.edit:SetCursorPosition(self:EditPosition(err.pos))
    self.edit:HighlightText(self:EditPosition(err.pos), self:EditPosition(err.finish + 1))
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
    -- Without focus nobody is typing, whatever the game says: the box holds the coloured text then.
    if not userInput or not edit:HasFocus() then return end
    local box = edit:GetParent() --[[@as LibDataGridFilterBoxMixin]]
    box.filterText = lib.FromEditBox(edit:GetText())
    box.hint:Hide()
    box.clear:SetShown(box.filterText ~= "")
end

---Focus gained or lost: plain text to type in, or coloured text to look at.
---@param edit EditBox
local function OnFocusChanged(edit)
    (edit:GetParent() --[[@as LibDataGridFilterBoxMixin]]):ShowText()
end

---@param button Button
local function OnClearClick(button)
    (button:GetParent() --[[@as LibDataGridFilterBoxMixin]]):Clear()
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
    box.edit:SetScript("OnEditFocusGained", OnFocusChanged)
    box.edit:SetScript("OnEditFocusLost", OnFocusChanged)
    box.edit:SetTextInsets(0, CLEAR, 0, 0)

    -- The x inside the box's right end, as the game's own search boxes have it.
    box.clear = CreateFrame("Button", nil, box)
    box.clear:SetSize(CLEAR, CLEAR)
    box.clear:SetPoint("RIGHT", box.edit, "RIGHT", -2, 0)
    box.clear:SetFrameLevel(box.edit:GetFrameLevel() + 2)
    local icon = box.clear:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(CLEAR_ICON)
    icon:SetAlpha(0.6)
    box.clear:SetScript("OnClick", OnClearClick)

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
