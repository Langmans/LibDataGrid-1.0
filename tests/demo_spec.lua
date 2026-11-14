-- The demo window, a development aid: /libdatagrid opens a filter box and a grid over sample rows.

local frames = require("tests.frames")

describe("the demo", function()
    local lib
    before_each(function()
        lib = NewClient()
    end)

    it("opens on /libdatagrid with a filter box and a grid over its rows, and again the same one", function()
        assert.are.equal("/libdatagrid", SLASH_LIBDATAGRID1)
        SlashCmdList.LIBDATAGRID("")
        local demo = lib.demo
        assert.is_true(demo:IsShown())
        assert.is_true(demo.grid.count > 20)
        assert.is_true(#frames.WithText(demo, lib.L.BUILDER) == 1)
        demo.box.view:SetFilterText("[Rare] = true")
        assert.is_true(demo.grid.count > 0 and demo.grid.count < 10)
        demo:Hide()
        SlashCmdList.LIBDATAGRID("")
        assert.are.equal(demo, lib.demo)
        assert.is_true(demo:IsShown())
    end)
end)
