-- The Builder: a dialog over a copy of the view's filter, with a line per group, condition and
-- add-row; Apply hands the copy to the view.

local fixtures = require("tests.fixtures")
local frames = require("tests.frames")

describe("the builder", function()
    local lib, view, builder, ops, F
    before_each(function()
        lib = NewClient()
        ops, F = lib.ops, fixtures.families
        view = fixtures.Schema(lib):NewView()
        view:SetFilterText("[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2)")
        builder = lib:CreateBuilder(view)
        builder:Open()
    end)

    ---Each shown line as "<kind><depth>".
    local function shape()
        local out = {}
        for i, entry in ipairs(builder.entries) do
            out[i] = entry.kind .. entry.depth
        end
        return table.concat(out, " ")
    end

    ---The line showing the entry at this place.
    local function line(index)
        return builder.lines[index]
    end

    it("draws the view's filter as lines, and the filter as text under them", function()
        assert.is_true(builder:IsShown())
        assert.are.equal("group0 condition1 group1 condition2 condition2 add2 add1", shape())
        assert.are.equal(lib.L.AND, line(1).join:GetText())
        assert.are.equal(lib.L.OR, line(3).join:GetText())
        assert.are.equal("Level", line(2).columnPicker.label:GetText())
        assert.are.equal("at most", line(2).opPicker.label:GetText())
        assert.are.equal("20", line(2).valueEdit:GetText())
        assert.are.equal("Cat", line(4).valuePicker.label:GetText())
        assert.are.equal("[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2)", builder.preview:GetText())
        assert.is_false(line(1).remove:IsShown())
        assert.is_true(line(3).remove:IsShown())
    end)

    it("changes only its copy until Apply, and Cancel leaves the view as it was", function()
        frames.Click(line(1).join)
        frames.Click(line(3).negate)
        assert.are.equal("[Level] <= 20 OR NOT ([Family] = Cat OR [Speed] < 2)", builder.preview:GetText())
        assert.are.equal("[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2)", view:GetFilterText())
        frames.ClickText(builder, lib.L.CANCEL)
        assert.is_false(builder:IsShown())
        assert.are.equal("[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2)", view:GetFilterText())
        builder:Open()
        frames.Click(line(3).negate)
        frames.Click(line(3).negate)
        frames.Click(line(3).join)
        frames.ClickText(builder, lib.L.APPLY)
        assert.is_false(builder:IsShown())
        assert.are.equal("[Level] <= 20 AND ([Family] = Cat AND [Speed] < 2)", view:GetFilterText())
    end)

    it("adds a condition, left out until it has a value, and a group with one in it", function()
        frames.Click(line(7).addCondition)
        assert.are.equal("group0 condition1 group1 condition2 condition2 add2 condition1 add1", shape())
        assert.are.equal("Name", line(7).columnPicker.label:GetText())
        assert.are.equal("equals", line(7).opPicker.label:GetText())
        assert.are.equal("[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2)", builder.preview:GetText())
        frames.Type(line(7).valueEdit, "Prowler")
        assert.are.equal(
            "[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2) AND [Name] = Prowler",
            builder.preview:GetText()
        )
        frames.Click(line(6).addGroup)
        assert.are.equal(
            "group0 condition1 group1 condition2 condition2 group2 condition3 add3 add2 condition1 add1",
            shape()
        )
    end)

    it("removes a condition or a group", function()
        frames.Click(line(4).remove)
        assert.are.equal("[Level] <= 20 AND [Speed] < 2", builder.preview:GetText())
        frames.Click(line(3).remove)
        assert.are.equal("group0 condition1 add1", shape())
    end)

    it("starts a condition over when its column changes, and its value when the operator takes another kind", function()
        line(2).columnPicker.OnPick("family")
        assert.are.equal("equals", line(2).opPicker.label:GetText())
        assert.is_nil(builder.entries[2].node.value)
        assert.is_true(line(2).valuePicker:IsShown())
        assert.is_false(line(2).valueEdit:IsShown())
        line(2).valuePicker.OnPick(F.wolf)
        line(2).opPicker.OnPick(ops.ne)
        assert.are.equal(F.wolf, builder.entries[2].node.value)
        line(2).opPicker.OnPick(ops.inList)
        assert.is_nil(builder.entries[2].node.value)
        assert.is_true(line(2).valueEdit:IsShown())
    end)

    it("reads a value as the column does, marking text that is not one", function()
        local edit = line(2).valueEdit
        frames.Type(edit, "ten")
        assert.is_nil(builder.entries[2].node.value)
        assert.are.same({ 1, 0.3, 0.3 }, edit.textColor)
        frames.Type(edit, "12")
        assert.are.equal(12, builder.entries[2].node.value)
        assert.are.same({ 1, 1, 1 }, edit.textColor)
        edit:SetText("by code")
        frames.Fire(edit, "OnTextChanged", false)
        assert.are.equal(12, builder.entries[2].node.value)
    end)

    it("takes a list for IN and both ends for BETWEEN, and nothing for IS BLANK", function()
        line(4).opPicker.OnPick(ops.inList)
        frames.Type(line(4).valueEdit, "Cat, Wolf")
        assert.are.same({ F.cat, F.wolf }, builder.entries[4].node.value)
        assert.are.equal("Cat, Wolf", line(4).valueEdit:GetText())
        frames.Type(line(4).valueEdit, "Cat, Bear")
        assert.is_nil(builder.entries[4].node.value)
        frames.Type(line(4).valueEdit, "Cat, Wolf")
        line(2).opPicker.OnPick(ops.between)
        assert.is_true(line(2).valueHigh:IsShown())
        frames.Type(line(2).valueEdit, "5")
        assert.is_nil(builder.entries[2].node.value)
        frames.Type(line(2).valueHigh, "15")
        assert.are.same({ 5, 15 }, builder.entries[2].node.value)
        assert.are.equal("5", line(2).valueEdit:GetText())
        line(5).opPicker.OnPick(ops.blank)
        assert.is_false(line(5).valueEdit:IsShown())
        assert.are.equal(
            "[Level] BETWEEN 5 AND 15 AND ([Family] IN (Cat, Wolf) OR [Speed] IS BLANK)",
            builder.preview:GetText()
        )
    end)

    it("picks true or false for a yes/no column", function()
        line(2).columnPicker.OnPick("rare")
        assert.are.same({ true, false }, line(2).valuePicker.values)
        line(2).valuePicker.OnPick(false)
        assert.is_false(builder.entries[2].node.value)
    end)

    it("scrolls when there are more lines than fit", function()
        for _ = 1, 20 do
            frames.Click(line(1).join)
            builder.tree.children[#builder.tree.children + 1] = { column = "level", op = ops.gt, value = 1 }
        end
        builder:Draw()
        assert.is_true(builder.bar:IsShown())
        builder.bar:ScrollTo(3)
        assert.are.equal(builder.entries[4].node, builder.lines[1].entry.node)
    end)

    it("is opened by the filter box's Builder button, one per box", function()
        local box = lib:CreateFilterBox(UIParent, view)
        frames.ClickText(box, lib.L.BUILDER)
        local first = box.builder
        assert.is_true(first:IsShown())
        first:Hide()
        frames.ClickText(box, lib.L.BUILDER)
        assert.are.equal(first, box.builder)
        assert.is_true(first:IsShown())
    end)

    it("closes on Escape", function()
        assert.are.equal(builder, _G[UISpecialFrames[#UISpecialFrames]])
    end)
end)
