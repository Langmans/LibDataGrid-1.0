-- The filter box: filter text in an edit box, applied with Enter or Apply, with the parser's error
-- under it and the text it is about highlighted.

local fixtures = require("tests.fixtures")
local frames = require("tests.frames")

describe("a filter box", function()
    local lib, view, box
    before_each(function()
        lib = NewClient()
        view = fixtures.Schema(lib):NewView()
        view:SetFilterText("[Level] > 1")
        box = lib:CreateFilterBox(UIParent, view)
    end)

    local function enter(text)
        frames.Type(box.edit, text)
        frames.Fire(box.edit, "OnEnterPressed")
    end

    it("shows the view's filter", function()
        assert.are.equal("[Level] > 1", box.edit:GetText())
        assert.is_false(box.hint:IsShown())
    end)

    it("applies the text on Enter and on Apply, in the schema's words", function()
        box.edit:SetFocus()
        enter("[level]=10")
        assert.are.equal("[Level] = 10", view:GetFilterText())
        assert.are.equal("[Level] = 10", box.edit:GetText())
        assert.is_false(box.edit:HasFocus())
        frames.Type(box.edit, "[rare] = true")
        frames.ClickText(box, lib.L.APPLY)
        assert.are.equal("[Rare] = true", view:GetFilterText())
    end)

    it("says what is wrong and marks where, leaving the filter as it was", function()
        enter("[Diet] = Meat")
        assert.is_true(box.hint:IsShown())
        assert.are.equal('Unknown column "Diet"', box.hint:GetText())
        assert.are.same({ 1, 5 }, box.edit.highlight)
        assert.are.equal(1, box.edit.cursor)
        assert.is_true(box.edit:HasFocus())
        assert.are.equal("[Level] > 1", view:GetFilterText())
    end)

    it("drops the hint once the text is typed in again", function()
        enter("[Diet] = Meat")
        frames.Type(box.edit, "[Level] > 2")
        assert.is_false(box.hint:IsShown())
        box.hint:Show()
        box.edit:SetText("set by code")
        frames.Fire(box.edit, "OnTextChanged", false)
        assert.is_true(box.hint:IsShown())
    end)

    it("goes back to the view's filter on Escape", function()
        enter("[Diet] = Meat")
        frames.Fire(box.edit, "OnEscapePressed")
        assert.are.equal("[Level] > 1", box.edit:GetText())
        assert.is_false(box.edit:HasFocus())
        assert.is_false(box.hint:IsShown())
    end)

    it("follows the filter set elsewhere, but not while it is being typed in", function()
        view:SetFilterText("[Rare] = true")
        assert.are.equal("[Rare] = true", box.edit:GetText())
        box.edit:SetFocus()
        frames.Type(box.edit, "[Lev")
        view:SetFilterText("[Level] < 3")
        assert.are.equal("[Lev", box.edit:GetText())
        view:ToggleSort("level")
        assert.are.equal("[Lev", box.edit:GetText())
    end)

    it("takes a skin and the caller's mixins", function()
        local skinned = {}
        local skin = CreateFromMixins(lib.SkinMixin, {
            EditBox = function(_, frame)
                skinned[#skinned + 1] = frame.kind
            end,
            Button = function(_, frame)
                skinned[#skinned + 1] = frame.kind
            end,
        })
        local own = lib:CreateFilterBox(UIParent, view, skin, {
            Apply = function(self)
                self.applied = true
            end,
        })
        frames.Fire(own.edit, "OnEnterPressed")
        assert.is_true(own.applied)
        assert.are.same({ "EditBox", "Button" }, skinned)
    end)
end)
