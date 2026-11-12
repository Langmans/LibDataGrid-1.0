-- A tree into one function that says whether a row passes.

local fixtures = require("tests.fixtures")

describe("compiling a filter", function()
    local lib, schema, rows
    before_each(function()
        lib = NewClient()
        schema = fixtures.Schema(lib)
        rows = fixtures.Rows()
    end)

    ---The names of the rows that pass this filter text.
    local function passing(text)
        local passes = schema:Compile(assert(schema:Parse(text)))
        local names = {}
        for _, row in ipairs(rows) do
            if passes(row) then names[#names + 1] = row.name end
        end
        return names
    end

    local all = { "Timber Wolf", "Mangy Wolf", "Prowler", "Humar the Pridelord", "Thunderhead", "Broken Tooth" }

    it("passes every row with no filter", function()
        assert.are.same(all, passing(""))
    end)

    it("compares numbers", function()
        assert.are.same({ "Timber Wolf", "Prowler" }, passing("[Level] = 10"))
        assert.are.same({ "Mangy Wolf" }, passing("[Level] < 10"))
        assert.are.same({ "Timber Wolf", "Mangy Wolf", "Prowler" }, passing("[Level] <= 10"))
        assert.are.same({ "Broken Tooth" }, passing("[Level] > 23"))
        assert.are.same({ "Humar the Pridelord", "Thunderhead", "Broken Tooth" }, passing("[Level] >= 23"))
        assert.are.same({ "Prowler", "Humar the Pridelord", "Broken Tooth" }, passing("[Speed] != 2"))
    end)

    it("compares text without case, unless the column says otherwise", function()
        assert.are.same({ "Timber Wolf", "Mangy Wolf" }, passing("[Name] CONTAINS WOLF"))
        assert.are.same({ "Timber Wolf" }, passing("[Name] STARTS WITH timber"))
        assert.are.same({ "Prowler" }, passing("[Name] = prowler"))
        assert.are.same({ "Humar the Pridelord" }, passing("[Name] ENDS WITH LORD"))
        assert.are.same({}, passing("[Zone] = elwynn"))
        assert.are.same({ "Timber Wolf", "Mangy Wolf" }, passing("[Zone] = Elwynn"))
        assert.are.same({ "Prowler" }, passing("[Zone] IN (westfall, Westfall)"))
    end)

    it("takes BETWEEN's ends as in range, as MySQL does", function()
        assert.are.same(
            { "Timber Wolf", "Prowler", "Humar the Pridelord", "Thunderhead" },
            passing("[Level] BETWEEN 10 AND 23")
        )
        assert.are.same({ "Mangy Wolf", "Broken Tooth" }, passing("[Level] NOT BETWEEN 10 AND 23"))
    end)

    it("compares dates, a day alone being its midnight", function()
        assert.are.same({ "Timber Wolf" }, passing("[Seen] = 2026-11-12"))
        assert.are.same({ "Timber Wolf", "Mangy Wolf" }, passing("[Seen] >= 2026-11-12"))
        assert.are.same({ "Mangy Wolf" }, passing('[Seen] BETWEEN "2026-11-12 12:00" AND 2026-11-13'))
        assert.are.same({ "Timber Wolf" }, passing('[Seen] < "2026-11-12 18:30"'))
    end)

    it("finds text as it is, not as a pattern", function()
        rows = { { name = "50% off" }, { name = "500 off" } }
        assert.are.same({ "50% off" }, passing("[Name] CONTAINS %"))
        assert.are.same({ "50% off" }, passing('[Name] CONTAINS "0% "'))
    end)

    it("compares choices and booleans", function()
        assert.are.same({ "Thunderhead" }, passing('[Family] = "Wind Serpent"'))
        assert.are.same(
            { "Prowler", "Humar the Pridelord", "Thunderhead", "Broken Tooth" },
            passing("[Family] != Wolf")
        )
        assert.are.same({ "Timber Wolf", "Mangy Wolf", "Thunderhead" }, passing('[Family] IN (Wolf, "Wind Serpent")'))
        assert.are.same(
            { "Prowler", "Humar the Pridelord", "Broken Tooth" },
            passing('[Family] NOT IN (Wolf, "Wind Serpent")')
        )
        assert.are.same({ "Humar the Pridelord", "Broken Tooth" }, passing("[Rare] = true"))
        assert.are.same({ "Humar the Pridelord", "Broken Tooth" }, passing("[Rare] != false"))
    end)

    it("fails a blank value on every test but the negative ones and IS BLANK", function()
        rows = { { name = "Nameless" }, { name = "Empty", zone = "" } }
        assert.are.same({ "Nameless", "Empty" }, passing("[Zone] IS BLANK"))
        assert.are.same({}, passing("[Zone] IS NOT BLANK"))
        assert.are.same({}, passing("[Zone] = Elwynn"))
        assert.are.same({ "Nameless", "Empty" }, passing("[Zone] != Elwynn"))
        assert.are.same({}, passing("[Level] < 100"))
        assert.are.same({}, passing("[Zone] CONTAINS e"))
        assert.are.same({ "Nameless", "Empty" }, passing("[Zone] NOT CONTAINS e"))
        assert.are.same({}, passing("[Rare] = false"))
        assert.are.same({ "Nameless", "Empty" }, passing("[Family] NOT IN (Cat)"))
    end)

    it("combines with AND, OR and NOT", function()
        assert.are.same({ "Prowler" }, passing("[Level] = 10 AND [Family] = Cat"))
        assert.are.same({ "Mangy Wolf", "Broken Tooth" }, passing("[Level] < 10 OR [Level] > 23"))
        assert.are.same({ "Timber Wolf", "Mangy Wolf", "Prowler", "Thunderhead" }, passing("NOT [Rare] = true"))
        assert.are.same(
            { "Prowler", "Thunderhead" },
            passing("[Level] >= 10 AND NOT ([Rare] = true OR [Family] = Wolf)")
        )
    end)

    it("leaves out conditions and groups that are not finished", function()
        local ops = lib.ops
        local passes = schema:Compile({
            join = "or",
            children = {
                { column = "level", op = ops.gt },
                { column = "diet", op = ops.eq, value = "Meat" },
                { join = "and", negate = true, children = {} },
                { column = "rare", op = ops.eq, value = true },
            },
        })
        assert.is_true(passes(rows[4]))
        assert.is_false(passes(rows[1]))
        assert.is_true(schema:Compile({ join = "and", negate = true, children = {} })(rows[1]))
    end)
end)
