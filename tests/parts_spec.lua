-- The parts the widgets are built from: the skin, the scrollbar beside a list, and the picker
-- (a chip that opens a pick list).

local frames = require("tests.frames")

describe("the skin", function()
    local lib
    before_each(function()
        lib = NewClient()
    end)

    it("gives panels a dark backdrop and fields a dark back, and leaves fonts and buttons as they are", function()
        local skin = lib.SkinMixin
        local panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        skin:Backdrop(panel)
        assert.is_table(panel.backdrop)
        -- Nearly opaque: what lies under a dialog should not show through.
        assert.are.equal(0.95, panel.backdropColor[4])
        local field = CreateFrame("Button")
        skin:Field(field)
        assert.are.equal(1, #field.children)
        skin:Font(field:CreateFontString())
        skin:Button(field)
        skin:EditBox(field)
    end)
end)

describe("the skin's syntax highlighting", function()
    local lib, schema
    before_each(function()
        lib = NewClient()
        schema = require("tests.fixtures").Schema(lib)
    end)

    it("colours each piece by its kind and leaves the spaces between", function()
        assert.are.equal(
            "|cffffd100[Level]|r |cff80c0ff>=|r |cffffffff1|r |cffff8040AND|r |cffa0a0a0(|r|cffffd100[Rare]|r |cff80c0ff=|r |cffffffffTRUE|r|cffa0a0a0)|r",
            lib.SkinMixin:Highlight(schema, "[Level] >= 1 AND ([Rare] = TRUE)")
        )
    end)

    -- An edit box shows || as two bars and does not end a colour on it (seen on Forever), so a | is
    -- left as it is, uncoloured, and so is a piece right against it, which would else start with
    -- |c straight after the bar.
    it("leaves a | as it is, uncoloured, and the piece right against it too", function()
        assert.are.equal(
            "|cffffd100[Rare]|r |cff80c0ff=|r |cfffffffftrue|r | |cffffd100[Level]|r |cff80c0ff>|r |cffffffff1|r",
            lib.SkinMixin:Highlight(schema, "[Rare] = true | [Level] > 1")
        )
        assert.are.equal(
            "|cffffd100[Rare]|r |cff80c0ff=|r |cfffffffftrue|r |!|cffffd100[Level]|r",
            lib.SkinMixin:Highlight(schema, "[Rare] = true |![Level]")
        )
        assert.are.equal('|cffffd100[Name]|r |cff80c0ff=|r "a|b"', lib.SkinMixin:Highlight(schema, '[Name] = "a|b"'))
    end)

    it("colours what does not parse as an error, and text it never reached as it is", function()
        assert.are.equal(
            "|cffffd100[Level]|r |cff80c0ff>|r |cffff4040ten|r",
            lib.SkinMixin:Highlight(schema, "[Level] > ten")
        )
        assert.are.equal("|cffffd100[Level]|r |cff80c0ff>|r ", lib.SkinMixin:Highlight(schema, "[Level] > "))
        assert.are.equal("", lib.SkinMixin:Highlight(schema, ""))
    end)

    it("takes an addon's own colours", function()
        local skin = CreateFromMixins(lib.SkinMixin, {
            TokenColour = function()
                return "ff00ff00"
            end,
        })
        assert.are.equal("|cff00ff00[Rare]|r |cff00ff00=|r |cff00ff00true|r", skin:Highlight(schema, "[Rare] = true"))
    end)
end)

describe("a scrollbar", function()
    local lib, list, bar, scrolled
    before_each(function()
        lib = NewClient()
        list = CreateFrame("Frame")
        scrolled = {}
        bar = lib:CreateScrollBar(list, function(offset)
            scrolled[#scrolled + 1] = offset
        end)
    end)

    it("shows only when the rows do not all fit", function()
        bar:SetRange(10, 4)
        assert.is_true(bar:IsShown())
        assert.are.same({ 0, 6 }, { bar.min, bar.max })
        bar:SetRange(3, 4)
        assert.is_false(bar:IsShown())
    end)

    it("moves with the list's mouse wheel and its own thumb, within the rows", function()
        bar:SetRange(10, 4)
        frames.Fire(list, "OnMouseWheel", -1)
        frames.Fire(list, "OnMouseWheel", 1)
        frames.Fire(list, "OnMouseWheel", 1)
        frames.Fire(bar, "OnValueChanged", 4.6)
        frames.Fire(bar, "OnValueChanged", 99)
        assert.are.same({ 1, 0, 5, 6 }, scrolled)
        assert.are.equal(6, bar.offset)
    end)

    it("keeps its place inside a shorter list, without telling the owner", function()
        bar:SetRange(10, 4)
        bar:ScrollTo(6)
        bar:SetRange(6, 4)
        assert.are.equal(2, bar.offset)
        assert.are.same({ 6 }, scrolled)
    end)
end)

describe("a picker", function()
    local lib, picker, picked
    before_each(function()
        lib = NewClient()
        picked = {}
        picker = lib:CreatePicker(UIParent, nil, function(value)
            picked[#picked + 1] = value
        end)
        picker:SetChoices({ 1, 2 }, { "Cat", "Wolf" }, 2)
    end)

    local function list()
        return _G[lib.name .. "PickList"]
    end

    it("says what is chosen", function()
        assert.are.equal("Wolf", picker.label:GetText())
        assert.are.equal(2, picker.value)
        picker:SetChoices({ 1, 2 }, { "Cat", "Wolf" }, 3)
        assert.are.equal("", picker.label:GetText())
        assert.is_nil(picker.value)
    end)

    it("opens its choices under it, over any dialog, and a click on one picks it and closes them", function()
        frames.Click(picker)
        assert.is_true(list():IsShown())
        -- The Builder is a DIALOG; the list must lie over its buttons.
        assert.are.equal("FULLSCREEN_DIALOG", list().strata)
        frames.ClickText(list(), "Cat")
        assert.are.same({ 1 }, picked)
        assert.is_false(list():IsShown())
    end)

    it("closes its choices on a second click, on Escape, or when it hides", function()
        frames.Click(picker)
        frames.Click(picker)
        assert.is_false(list():IsShown())
        assert.are.same({ lib.name .. "PickList" }, UISpecialFrames)
        frames.Click(picker)
        picker:Hide()
        assert.is_false(list():IsShown())
    end)

    it("hands the open list to another picker", function()
        local other = lib:CreatePicker(UIParent, nil, function() end)
        other:SetChoices({ "a" }, { "Alpha" }, "a")
        frames.Click(picker)
        frames.Click(other)
        assert.is_true(list():IsShown())
        assert.are.equal(other, list().picker)
        picker:Hide()
        assert.is_true(list():IsShown())
    end)

    it("scrolls a long list of choices", function()
        local values, texts = {}, {}
        for i = 1, 30 do
            values[i], texts[i] = i, "Choice " .. i
        end
        picker:SetChoices(values, texts, 1)
        frames.Click(picker)
        assert.is_true(list().bar:IsShown())
        assert.are.equal(0, #frames.WithText(list(), "Choice 20"))
        list().bar:ScrollTo(10)
        assert.are.equal(1, #frames.WithText(list(), "Choice 20"))
    end)

    it("takes a skin's field and font", function()
        local skinned = {}
        local skin = CreateFromMixins(lib.SkinMixin, {
            Field = function(_, frame)
                skinned[#skinned + 1] = frame
            end,
        })
        local chip = lib:CreatePicker(UIParent, skin, function() end)
        assert.are.same({ chip }, skinned)
    end)
end)
