-- The Builder: a dialog over a copy of the view's filter. A group is a line with its AND/OR chip
-- (the join belongs to the whole group) and a NOT chip, its children indented under it, and a
-- line to add a condition or a group; a condition is a line of three chips, column, operator and
-- value. Apply hands the copy to the view, Cancel drops it. A condition without a value yet stays
-- in the copy and is left out of the filter, so nothing is lost while it is being filled in.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local L, takes, T = lib.L, lib.takes, lib.types
local WIDTH, LINES, LINE, INDENT, PAD, TITLE, FOOT = 560, 14, 24, 16, 10, 28, 56
-- BETWEEN's two boxes and the and between them take the room of one value box.
local COLUMN, OPERATOR, VALUE, HALF, RANGE_AND, CHIP, REMOVE = 120, 110, 150, 59, 24, 44, 22
local ERROR_COLOUR, NORMAL_COLOUR, OFF_COLOUR = { 1, 0.3, 0.3 }, { 1, 1, 1 }, { 0.5, 0.5, 0.5 }
local BOOLEANS, BOOLEAN_TEXTS = { true, false }, { "true", "false" }

-- What a line shows.
local KIND = { group = "group", condition = "condition", add = "add" }

---@class LibDataGridBuilderEntry
---@field kind string KIND
---@field node LibDataGridNode a group or condition; for an add line, the group it adds to
---@field parent LibDataGridGroup? the group a node is in; none for the root
---@field depth number

---@class LibDataGridOperatorChoices
---@field ids LibDataGridValue[]
---@field labels string[]

---@class LibDataGridChip: Button
---@field label FontString

---@class LibDataGridBuilderLine: Frame
---@field builder LibDataGridBuilderMixin
---@field entry LibDataGridBuilderEntry set by every draw before the line shows
---@field controls Region[]
---@field join LibDataGridChip
---@field negate LibDataGridChip
---@field remove Button
---@field columnPicker LibDataGridPickerMixin
---@field opPicker LibDataGridPickerMixin
---@field valuePicker LibDataGridPickerMixin
---@field valueEdit EditBox
---@field valueHigh EditBox
---@field rangeAnd FontString the and between BETWEEN's two boxes
---@field addCondition Button
---@field addGroup Button

---@class LibDataGridBuilderMixin: Frame
---@field view LibDataGridView
---@field skin LibDataGridSkinMixin
---@field tree LibDataGridGroup the copy being edited
---@field entries LibDataGridBuilderEntry[]
---@field count number how many entries the last draw had
---@field columnKeys LibDataGridValue[]
---@field columnLabels string[]
---@field operatorChoices table<string, LibDataGridOperatorChoices>
---@field lines LibDataGridBuilderLine[]
---@field body Frame
---@field bar LibDataGridScrollBarMixin
---@field preview FontString
local BuilderMixin = {}
lib.BuilderMixin = BuilderMixin

---@param text string
---@return string
local function Trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

---What a piece of text in a value box stands for; nil for an empty box or text that is not a value.
---@param column LibDataGridColumnMixin
---@param text string
---@return LibDataGridValue?
local function Parse(column, text)
    text = Trim(text)
    if text == "" then return nil end
    local value, code = column:ParseValue(text)
    if code then return nil end
    return value
end

---A value, or a list of them, as the value box writes it.
---@param column LibDataGridColumnMixin
---@param value LibDataGridOperand?
---@return string
local function ValueText(column, value)
    if value == nil then return "" end
    if type(value) ~= "table" then return column:FormatValue(value) end
    ---@type LibDataGridValue[], string[]
    local items, parts = value, {}
    for i, item in ipairs(items) do
        parts[i] = column:FormatValue(item)
    end
    return table.concat(parts, ", ")
end

---@param edit EditBox
---@param ok boolean
local function Mark(edit, ok)
    local colour = ok and NORMAL_COLOUR or ERROR_COLOUR
    edit:SetTextColor(colour[1], colour[2], colour[3])
end

---A new condition: the first column, with its type's first operator.
---@return LibDataGridCondition
function BuilderMixin:NewCondition()
    local column = self.view.schema.columns[1]
    return { column = column.key, op = lib.OperatorsFor(column.type)[1].id }
end

---The next entry, its table kept from the last draw when there is one.
---@param kind string
---@param node LibDataGridNode
---@param parent LibDataGridGroup?
---@param depth number
function BuilderMixin:AddEntry(kind, node, parent, depth)
    self.count = self.count + 1
    local entry = self.entries[self.count] or {}
    self.entries[self.count] = entry
    entry.kind, entry.node, entry.parent, entry.depth = kind, node, parent, depth
end

---Every line, in order: a group, its children, its add line.
---@param node LibDataGridNode
---@param parent LibDataGridGroup?
---@param depth number
function BuilderMixin:Collect(node, parent, depth)
    if not node.children then
        self:AddEntry(KIND.condition, node, parent, depth)
        return
    end
    self:AddEntry(KIND.group, node, parent, depth)
    for _, child in ipairs(node.children) do
        self:Collect(child, node --[[@as LibDataGridGroup]], depth + 1)
    end
    self:AddEntry(KIND.add, node, nil, depth + 1)
end

---The choices of the column and operator pickers, made once: the schema does not change.
---@param type string
---@return LibDataGridValue[] ids
---@return string[] labels
function BuilderMixin:OperatorChoices(type)
    local choices = self.operatorChoices[type]
    if not choices then
        choices = { ids = {}, labels = {} }
        for i, op in ipairs(lib.OperatorsFor(type)) do
            choices.ids[i], choices.labels[i] = op.id, op.label
        end
        self.operatorChoices[type] = choices
    end
    return choices.ids, choices.labels
end

---Places a control after the one before it on its line.
---@param control Region
---@param x number
---@param width number
---@return number the next x
local function Place(control, x, width)
    control:ClearAllPoints()
    control:SetPoint("LEFT", x, 0)
    control:SetWidth(width)
    control:Show()
    return x + width + 4
end

---Shows one entry on a line.
---@param line LibDataGridBuilderLine
---@param entry LibDataGridBuilderEntry
function BuilderMixin:DrawLine(line, entry)
    line.entry = entry
    for _, control in ipairs(line.controls) do
        control:Hide()
    end
    local x, node = entry.depth * INDENT, entry.node
    if entry.kind == KIND.add then
        x = Place(line.addCondition, x, 90)
        Place(line.addGroup, x, 70)
        return
    end
    if entry.parent then line.remove:Show() end
    if node.children then
        line.join:SetText(node.join == lib.joins["or"] and L.OR or L.AND)
        x = Place(line.join, x, CHIP)
        local colour = node.negate and NORMAL_COLOUR or OFF_COLOUR
        line.negate.label:SetTextColor(colour[1], colour[2], colour[3])
        Place(line.negate, x, CHIP)
        return
    end
    local column = self.view.schema:Column(node.column) --[[@as LibDataGridColumnMixin]]
    line.columnPicker:SetChoices(self.columnKeys, self.columnLabels, node.column)
    x = Place(line.columnPicker, x, COLUMN)
    local ids, labels = self:OperatorChoices(column.type)
    line.opPicker:SetChoices(ids, labels, node.op)
    x = Place(line.opPicker, x, OPERATOR)
    local op, value = lib.operators[node.op], node.value
    if op.takes == takes.range then
        local ends = value --[[@as LibDataGridValue[]? ]]
        line.valueEdit:SetText(ends and column:FormatValue(ends[1]) or "")
        line.valueHigh:SetText(ends and column:FormatValue(ends[2]) or "")
        x = Place(line.valueEdit, x, HALF)
        x = Place(line.rangeAnd, x, RANGE_AND)
        Place(line.valueHigh, x, HALF)
    elseif op.takes == takes.value and (column.type == T.enum or column.type == T.boolean) then
        local values, texts = BOOLEANS, BOOLEAN_TEXTS
        if column.type == T.enum then
            values, texts = {}, {}
            for i, choice in ipairs(column:Choices()) do
                values[i], texts[i] = choice.value, choice.text
            end
        end
        line.valuePicker:SetChoices(values, texts, value --[[@as LibDataGridValue?]])
        Place(line.valuePicker, x, VALUE)
    elseif op.takes then
        line.valueEdit:SetText(lib.ToEditBox(ValueText(column, value)))
        Place(line.valueEdit, x, VALUE)
    end
    Mark(line.valueEdit, true)
    Mark(line.valueHigh, true)
end

---Draws the copy: every line from the scrolled offset, and the filter as text.
function BuilderMixin:Draw()
    self.count = 0
    self:Collect(self.tree, nil, 0)
    for index = #self.entries, self.count + 1, -1 do
        self.entries[index] = nil
    end
    self.bar:SetRange(#self.entries, LINES)
    for index, line in ipairs(self.lines) do
        local entry = self.entries[index + self.bar.offset]
        line:SetShown(entry ~= nil)
        if entry then self:DrawLine(line, entry) end
    end
    self:ShowPreview()
end

---The copy as filter text, under the lines.
function BuilderMixin:ShowPreview()
    local schema = self.view.schema
    self.preview:SetText(self.skin:Highlight(schema, schema:Format(self.tree)))
end

---Opens on a fresh copy of the view's filter.
function BuilderMixin:Open()
    self.tree = self.view:GetFilterModel()
    self.bar.offset = 0
    self:Draw()
    self:Show()
end

---Hands the copy to the view and closes.
function BuilderMixin:Apply()
    self.view:SetFilterModel(self.tree)
    self:Hide()
end

---The line a control is on.
---@param control Region
---@return LibDataGridBuilderLine
local function LineOf(control)
    return control:GetParent() --[[@as LibDataGridBuilderLine]]
end

-- What the line's buttons and pickers do: change the copy, then draw it again.

---@param button Button
local function OnJoin(button)
    local line = LineOf(button)
    local group = line.entry.node --[[@as LibDataGridGroup]]
    group.join = group.join == lib.joins["or"] and lib.joins["and"] or lib.joins["or"]
    line.builder:Draw()
end

---@param button Button
local function OnNegate(button)
    local line = LineOf(button)
    local group = line.entry.node --[[@as LibDataGridGroup]]
    group.negate = not group.negate or nil
    line.builder:Draw()
end

---@param button Button
local function OnRemove(button)
    local line = LineOf(button)
    local entry = line.entry --[[@as LibDataGridBuilderEntry]]
    local children = (entry.parent --[[@as LibDataGridGroup]]).children
    for i, child in ipairs(children) do
        if child == entry.node then
            table.remove(children, i)
            break
        end
    end
    line.builder:Draw()
end

---@param button Button
local function OnAddCondition(button)
    local line = LineOf(button)
    local children = (line.entry.node --[[@as LibDataGridGroup]]).children
    children[#children + 1] = line.builder:NewCondition()
    line.builder:Draw()
end

---@param button Button
local function OnAddGroup(button)
    local line = LineOf(button)
    local children = (line.entry.node --[[@as LibDataGridGroup]]).children
    children[#children + 1] = { join = lib.joins["and"], children = { line.builder:NewCondition() } }
    line.builder:Draw()
end

---A value box typed in: the condition's value as the column reads the text, or none.
---@param edit EditBox
---@param userInput boolean
local function OnValueTyped(edit, userInput)
    if not userInput then return end
    local line = LineOf(edit)
    local node = line.entry.node --[[@as LibDataGridCondition]]
    local column = line.builder.view.schema:Column(node.column) --[[@as LibDataGridColumnMixin]]
    local op, text = lib.operators[node.op], lib.FromEditBox(edit:GetText())
    local value, ok
    if op.takes == takes.list then
        value, ok = {}, true
        for part in text:gmatch("[^,]+") do
            local item = Parse(column, part)
            ok = ok and item ~= nil
            value[#value + 1] = item
        end
        value = ok and #value > 0 and value or nil
    elseif op.takes == takes.range then
        local low = Parse(column, lib.FromEditBox(line.valueEdit:GetText()))
        local high = Parse(column, lib.FromEditBox(line.valueHigh:GetText()))
        ok = Parse(column, text) ~= nil
        value = low ~= nil and high ~= nil and { low, high } or nil
    else
        value = Parse(column, text)
        ok = value ~= nil
    end
    node.value = value
    Mark(edit, ok or Trim(text) == "")
    line.builder:ShowPreview()
end

---A chip: a button with a label, in the skin's field.
---@param line LibDataGridBuilderLine
---@param text string
---@param OnClick fun(button: Button)
---@return LibDataGridChip
local function Chip(line, text, OnClick)
    local chip = CreateFrame("Button", nil, line) --[[@as LibDataGridChip]]
    chip:SetHeight(LINE - 4)
    line.builder.skin:Field(chip)
    chip.label = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chip:SetFontString(chip.label)
    chip:SetText(text)
    line.builder.skin:Font(chip.label)
    chip:SetScript("OnClick", OnClick)
    line.controls[#line.controls + 1] = chip
    return chip
end

---A button made with the panel button template.
---@param parent Frame
---@param text string
---@param OnClick fun(button: Button)
---@param skin LibDataGridSkinMixin
---@return Button
local function PanelButton(parent, text, OnClick, skin)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate") --[[@as Button]]
    button:SetHeight(LINE - 4)
    button:SetText(text)
    button:SetScript("OnClick", OnClick)
    skin:Button(button)
    return button
end

---@param line LibDataGridBuilderLine
---@return EditBox
local function ValueBox(line)
    local edit = CreateFrame("EditBox", nil, line, "InputBoxTemplate") --[[@as EditBox]]
    edit:SetHeight(LINE - 4)
    edit:SetAutoFocus(false)
    edit:SetScript("OnTextChanged", OnValueTyped)
    edit:SetScript("OnEnterPressed", edit.ClearFocus)
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    line.builder.skin:EditBox(edit)
    line.controls[#line.controls + 1] = edit
    return edit
end

---@param line LibDataGridBuilderLine
---@param OnPick fun(value: LibDataGridValue)
---@return LibDataGridPickerMixin
local function LinePicker(line, OnPick)
    local picker = lib:CreatePicker(line, line.builder.skin, OnPick)
    line.controls[#line.controls + 1] = picker
    return picker
end

---One line, with every control a line can show.
---@param builder LibDataGridBuilderMixin
---@param index number
---@return LibDataGridBuilderLine
local function NewLine(builder, index)
    local line = CreateFrame("Frame", nil, builder.body) --[[@as LibDataGridBuilderLine]]
    line.builder, line.controls = builder, {}
    line:SetHeight(LINE)
    line:SetPoint("TOPLEFT", 0, -(index - 1) * LINE)
    line:SetPoint("RIGHT")
    line.join = Chip(line, L.AND, OnJoin)
    line.negate = Chip(line, L.NOT, OnNegate)
    line.remove = PanelButton(line, L.REMOVE, OnRemove, builder.skin)
    line.remove:SetWidth(REMOVE)
    line.remove:SetPoint("RIGHT")
    line.controls[#line.controls + 1] = line.remove
    line.addCondition = PanelButton(line, L.ADD_CONDITION, OnAddCondition, builder.skin)
    line.addGroup = PanelButton(line, L.ADD_GROUP, OnAddGroup, builder.skin)
    line.controls[#line.controls + 1] = line.addCondition
    line.controls[#line.controls + 1] = line.addGroup
    line.columnPicker = LinePicker(line, function(key)
        local node = line.entry.node --[[@as LibDataGridCondition]]
        local column = builder.view.schema:Column(key --[[@as string]]) --[[@as LibDataGridColumnMixin]]
        node.column, node.op, node.value = column.key, lib.OperatorsFor(column.type)[1].id, nil
        builder:Draw()
    end)
    line.opPicker = LinePicker(line, function(id)
        local node = line.entry.node --[[@as LibDataGridCondition]]
        if lib.operators[id].takes ~= lib.operators[node.op].takes then node.value = nil end
        node.op = id --[[@as string]]
        builder:Draw()
    end)
    line.valuePicker = LinePicker(line, function(value)
        (line.entry.node --[[@as LibDataGridCondition]]).value = value
        builder:Draw()
    end)
    line.valueEdit = ValueBox(line)
    line.valueHigh = ValueBox(line)
    -- BETWEEN's and, in the operator's colour as the filter text under the lines writes it.
    line.rangeAnd = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.rangeAnd:SetJustifyH("CENTER")
    line.rangeAnd:SetText("|c" .. builder.skin:TokenColour(lib.tokenKinds.operator) .. L.RANGE_AND .. "|r")
    builder.skin:Font(line.rangeAnd)
    line.controls[#line.controls + 1] = line.rangeAnd
    return line
end

---@param button Button
local function OnApply(button)
    (button:GetParent() --[[@as LibDataGridBuilderMixin]]):Apply()
end

---@param button Button
local function OnCancel(button)
    (button:GetParent() --[[@as LibDataGridBuilderMixin]]):Hide()
end

---A Builder dialog for a view, with the caller's mixins over BuilderMixin; hidden until Open.
---Escape closes it.
---@param view LibDataGridView
---@param skin LibDataGridSkinMixin?
---@param ... table
---@return LibDataGridBuilderMixin
function lib:CreateBuilder(view, skin, ...)
    lib.builders = (lib.builders or 0) + 1
    local name = lib.name .. "Builder" .. lib.builders
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    local builder = Mixin(frame, BuilderMixin, ...) --[[@as LibDataGridBuilderMixin]]
    builder.view, builder.skin, builder.entries, builder.lines = view, skin or lib.SkinMixin, {}, {}
    builder.tree, builder.count, builder.operatorChoices = lib.NewFilter(), 0, {}
    builder.columnKeys, builder.columnLabels = {}, {}
    for i, column in ipairs(view.schema.columns) do
        builder.columnKeys[i], builder.columnLabels[i] = column.key, column.label
    end
    builder:Hide()
    builder:SetSize(WIDTH, TITLE + LINES * LINE + FOOT)
    builder:SetPoint("CENTER")
    builder:SetFrameStrata("DIALOG")
    builder:SetClampedToScreen(true)
    builder:SetMovable(true)
    builder:EnableMouse(true)
    builder:RegisterForDrag("LeftButton")
    builder:SetScript("OnDragStart", builder.StartMoving)
    builder:SetScript("OnDragStop", builder.StopMovingOrSizing)
    table.insert(UISpecialFrames, name)
    builder.skin:Backdrop(builder)

    local title = builder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetText(L.BUILDER_TITLE)
    builder.skin:Font(title)
    CreateFrame("Button", nil, builder, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -2, -2)

    builder.body = CreateFrame("Frame", nil, builder)
    builder.body:SetPoint("TOPLEFT", PAD, -TITLE)
    builder.body:SetPoint("TOPRIGHT", -PAD - lib.SCROLLBAR_WIDTH - 2, -TITLE)
    builder.body:SetHeight(LINES * LINE)
    builder.bar = lib:CreateScrollBar(builder.body, function()
        builder:Draw()
    end)
    for index = 1, LINES do
        builder.lines[index] = NewLine(builder, index)
    end

    builder.preview = builder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    builder.preview:SetPoint("TOPLEFT", builder.body, "BOTTOMLEFT", 0, -6)
    builder.preview:SetPoint("RIGHT", -PAD, 0)
    builder.preview:SetJustifyH("LEFT")
    builder.skin:Font(builder.preview)

    local apply = PanelButton(builder, L.APPLY, OnApply, builder.skin)
    apply:SetWidth(80)
    apply:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    local cancel = PanelButton(builder, L.CANCEL, OnCancel, builder.skin)
    cancel:SetWidth(80)
    cancel:SetPoint("RIGHT", apply, "LEFT", -6, 0)
    return builder
end
