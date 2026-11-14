-- The filter box: filter text in an edit box, applied with Enter or Apply, with the parser's error
-- under it and the text it is about highlighted; coloured by kind while it is not being typed in.

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

    ---Types text in the box, which has focus while it is typed in, as in the game, and presses Enter.
    local function enter(text)
        box.edit:SetFocus()
        frames.Type(box.edit, text)
        frames.Fire(box.edit, "OnEnterPressed")
    end

    it("shows the view's filter", function()
        assert.are.equal("[Level] > 1", box:GetText())
        assert.is_false(box.hint:IsShown())
    end)

    it("applies the text on Enter and on Apply, in the schema's words", function()
        box.edit:SetFocus()
        enter("[level]=10")
        assert.are.equal("[Level] = 10", view:GetFilterText())
        assert.are.equal("[Level] = 10", box:GetText())
        assert.is_false(box.edit:HasFocus())
        box.edit:SetFocus()
        frames.Type(box.edit, "[rare] = true")
        frames.ClickText(box, lib.L.APPLY)
        assert.are.equal("[Rare] = true", view:GetFilterText())
    end)

    it("says what is wrong and marks where, leaving the filter as it was", function()
        enter("[Diet] = Meat")
        assert.is_true(box.hint:IsShown())
        assert.are.equal('Unknown column "Diet"', box.hint:GetText())
        assert.are.equal("[Diet] = Meat", box.edit:GetText())
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
        assert.are.equal("[Level] > 2", box:GetText())
    end)

    it("goes back to the view's filter on Escape", function()
        enter("[Diet] = Meat")
        frames.Fire(box.edit, "OnEscapePressed")
        assert.are.equal("[Level] > 1", box:GetText())
        assert.is_false(box.edit:HasFocus())
        assert.is_false(box.hint:IsShown())
    end)

    it("follows the filter set elsewhere, but not while it is being typed in", function()
        view:SetFilterText("[Rare] = true")
        assert.are.equal("[Rare] = true", box:GetText())
        box.edit:SetFocus()
        frames.Type(box.edit, "[Lev")
        view:SetFilterText("[Level] < 3")
        assert.are.equal("[Lev", box.edit:GetText())
        view:ToggleSort("level")
        assert.are.equal("[Lev", box:GetText())
    end)

    it("clears the filter with its x, which shows only when there is text", function()
        assert.is_true(box.clear:IsShown())
        enter("[Diet] = Meat")
        frames.Click(box.clear)
        assert.are.equal("", view:GetFilterText())
        assert.are.equal("", box:GetText())
        assert.is_false(box.hint:IsShown())
        assert.is_false(box.clear:IsShown())
        assert.is_false(box.edit:HasFocus())
        box.edit:SetFocus()
        frames.Type(box.edit, "[")
        assert.is_true(box.clear:IsShown())
        frames.Type(box.edit, "")
        assert.is_false(box.clear:IsShown())
    end)

    describe("its colours", function()
        local function coloured(text)
            return lib.SkinMixin:Highlight(view.schema, text)
        end

        it("shows the text coloured by kind while the box is not being typed in", function()
            assert.are.equal(coloured("[Level] > 1"), box.edit:GetText())
            assert.truthy(box.edit:GetText():find("|c", 1, true))
        end)

        it("shows a long text from its start once applied, not scrolled to its end", function()
            enter("[Level] > 1 AND [Rare] = true")
            assert.are.equal(0, box.edit.cursor)
        end)

        it("shows the plain text while it is typed in, and colours what was typed when left", function()
            box.edit:SetFocus()
            assert.are.equal("[Level] > 1", box.edit:GetText())
            frames.Type(box.edit, "[Level] > ten")
            box.edit:ClearFocus()
            assert.are.equal(coloured("[Level] > ten"), box.edit:GetText())
            assert.are.equal("[Level] > ten", box:GetText())
            assert.are.equal("[Level] > 1", view:GetFilterText())
        end)

        it("takes a typed | as one bar, shows it as the box does, and marks an error after it", function()
            box.edit:SetFocus()
            frames.Type(box.edit, "[Rare] = true | [Level] > 1")
            assert.are.equal("[Rare] = true | [Level] > 1", box:GetText())
            box.edit:ClearFocus()
            box.edit:SetFocus()
            assert.are.equal("[Rare] = true || [Level] > 1", box.edit:GetText())
            frames.Fire(box.edit, "OnEnterPressed")
            assert.are.equal("[Rare] = true OR [Level] > 1", view:GetFilterText())
            enter("[Rare] = true | [Diet] > 1")
            -- [Diet] is characters 18 to 21; in the box, where | is two, 19 to 22.
            assert.are.same({ 18, 22 }, box.edit.highlight)
            assert.are.equal(18, box.edit.cursor)
        end)

        it("takes no change for typing while it has no focus, so the coloured text never gets in", function()
            frames.Fire(box.edit, "OnTextChanged", true)
            assert.are.equal("[Level] > 1", box:GetText())
            frames.Fire(box.edit, "OnEnterPressed")
            assert.are.equal("[Level] > 1", view:GetFilterText())
            assert.is_false(box.hint:IsShown())
        end)

        it("applies the plain text, never the coloured one", function()
            frames.ClickText(box, lib.L.APPLY)
            assert.are.equal("[Level] > 1", view:GetFilterText())
            assert.is_false(box.hint:IsShown())
        end)
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
        assert.are.same({ "EditBox", "Button", "Button" }, skinned)
    end)
end)
