-- The grid: a header row and the rows that pass the view's filter, sorted, with a scrollbar.

local fixtures = require("tests.fixtures")
local frames = require("tests.frames")

describe("a grid", function()
    local lib, view, grid
    before_each(function()
        lib = NewClient()
        view = fixtures.Schema(lib):NewView()
        grid = lib:CreateGrid(UIParent, view)
        grid:SetSize(412, 20 + 3 * 18)
        grid:AddFixedWidthColumn("level", 50)
        grid:AddFillColumn("name", 2)
        grid:AddFillColumn("family")
        grid:SetRows(fixtures.Rows())
    end)

    ---The texts of the shown lines, one string per line.
    local function lines()
        local out = {}
        for _, line in ipairs(grid.lines) do
            if line:IsShown() then
                local cells = {}
                for i, cell in ipairs(line.cells) do
                    cells[i] = cell:GetText()
                end
                out[#out + 1] = table.concat(cells, "|")
            end
        end
        return out
    end

    it("lays out fixed columns, and fill columns sharing the rest by weight", function()
        local widths = {}
        for i, head in ipairs(grid.heads) do
            widths[i] = head:GetWidth()
        end
        -- 412 wide, less the scrollbar (12 and 2 apart) and the 50 fixed: 348 shared 2 to 1.
        assert.are.same({ 50, 232, 116 }, widths)
        assert.are.equal("Level", grid.heads[1].label:GetText())
    end)

    it("shows the rows that pass, as many as fit, each column's value as text", function()
        assert.are.same({ "10|Timber Wolf|Wolf", "6|Mangy Wolf|Wolf", "10|Prowler|Cat" }, lines())
        view:SetFilterText("[Family] = Cat")
        assert.are.same({ "10|Prowler|Cat", "23|Humar the Pridelord|Cat", "37|Broken Tooth|Cat" }, lines())
        view:SetFilterText("[Level] > 30")
        assert.are.same({ "37|Broken Tooth|Cat" }, lines())
        assert.are.equal(1, grid.count)
    end)

    it("scrolls when the rows do not all fit", function()
        assert.is_true(grid.bar:IsShown())
        frames.Fire(grid.body, "OnMouseWheel", -1)
        assert.are.same({ "6|Mangy Wolf|Wolf", "10|Prowler|Cat", "23|Humar the Pridelord|Cat" }, lines())
        view:SetFilterText("[Family] = Wolf")
        assert.is_false(grid.bar:IsShown())
        assert.are.same({ "10|Timber Wolf|Wolf", "6|Mangy Wolf|Wolf" }, lines())
    end)

    it("stripes every other row, the stripe moving with its row when scrolled", function()
        local function striped()
            local out = {}
            for i, line in ipairs(grid.lines) do
                out[i] = line.stripe:IsShown()
            end
            return out
        end
        assert.are.same({ false, true, false }, striped())
        frames.Fire(grid.body, "OnMouseWheel", -1)
        assert.are.same({ true, false, true }, striped())
        assert.is_table(grid.lines[1].stripe.color)
    end)

    it("shows more lines when it grows, and fewer when it shrinks", function()
        grid:SetSize(412, 20 + 10 * 18)
        frames.Fire(grid, "OnSizeChanged")
        assert.are.equal(6, #lines())
        assert.is_false(grid.bar:IsShown())
        grid:SetSize(412, 20 + 2 * 18)
        frames.Fire(grid, "OnSizeChanged")
        assert.are.equal(2, #lines())
    end)

    it("sorts by a header click, adds a key with Ctrl, and marks the order", function()
        frames.Click(grid.heads[1])
        assert.are.same({ "6|Mangy Wolf|Wolf", "10|Timber Wolf|Wolf", "10|Prowler|Cat" }, lines())
        assert.is_true(grid.heads[1].arrow:IsShown())
        assert.is_false(grid.heads[1].order:IsShown())
        assert.is_false(grid.heads[2].arrow:IsShown())
        frames.ctrl = true
        frames.Click(grid.heads[2])
        frames.Click(grid.heads[2])
        assert.are.same({ "6|Mangy Wolf|Wolf", "10|Timber Wolf|Wolf", "10|Prowler|Cat" }, lines())
        assert.are.equal("1", grid.heads[1].order:GetText())
        assert.are.equal("2", grid.heads[2].order:GetText())
        assert.are_not.same(grid.heads[1].arrow.texCoord, grid.heads[2].arrow.texCoord)
        frames.ctrl = false
        frames.Click(grid.heads[3])
        assert.is_false(grid.heads[1].arrow:IsShown())
        assert.are.same({ { key = "family" } }, view:GetSort())
    end)

    it("hands a clicked row to OnRowClick", function()
        local clicked = {}
        local own = lib:CreateGrid(UIParent, view, nil, {
            OnRowClick = function(_, row, button)
                clicked[#clicked + 1] = { row.name, button }
            end,
        })
        own:SetSize(200, 100)
        own:AddFillColumn("name")
        own:SetRows(fixtures.Rows())
        frames.Click(own.lines[2], "RightButton")
        frames.Click(grid.lines[1])
        assert.are.same({ { "Mangy Wolf", "RightButton" } }, clicked)
    end)

    it("writes cells with a column's own text, and blanks as nothing", function()
        local schema = lib:NewSchema({
            { key = "name" },
            {
                key = "speed",
                type = lib.types.number,
                text = function(row)
                    return ("%.1fs"):format(row.speed)
                end,
            },
            { key = "zone" },
        })
        local own = lib:CreateGrid(UIParent, schema:NewView())
        own:SetSize(300, 100)
        own:AddFillColumn("name")
        own:AddFillColumn("speed")
        own:AddFillColumn("zone")
        own:SetRows({ { name = "Prowler", speed = 1.5 } })
        assert.are.equal(
            "Prowler|1.5s|",
            table.concat({
                own.lines[1].cells[1]:GetText(),
                own.lines[1].cells[2]:GetText(),
                own.lines[1].cells[3]:GetText(),
            }, "|")
        )
    end)

    it("aligns a column's cells and header as its definition says, left when it says nothing", function()
        local A = lib.aligns
        local schema = lib:NewSchema({
            { key = "name" },
            { key = "level", type = lib.types.number, align = A.right },
            { key = "rare", type = lib.types.boolean, align = A.center },
        })
        local own = lib:CreateGrid(UIParent, schema:NewView())
        own:SetSize(300, 100)
        own:AddFillColumn("name")
        own:AddFillColumn("level")
        own:AddFillColumn("rare")
        own:SetRows({ { name = "Prowler", level = 10, rare = true } })
        local cells, heads = {}, {}
        for i = 1, 3 do
            cells[i], heads[i] = own.lines[1].cells[i].justify, own.heads[i].label.justify
        end
        assert.are.same({ "LEFT", "RIGHT", "CENTER" }, cells)
        assert.are.same({ "LEFT", "RIGHT", "CENTER" }, heads)
    end)

    it("says plainly when a column is not in the schema", function()
        assert.has_error(function()
            grid:AddFillColumn("diet")
        end, 'LibDataGrid-1.0: no column "diet" in the schema')
    end)
end)
