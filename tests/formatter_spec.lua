-- A tree back into filter text, which parses into the same tree.

local fixtures = require("tests.fixtures")

describe("formatting a filter", function()
    local lib, schema, ops
    before_each(function()
        lib = NewClient()
        schema = fixtures.Schema(lib)
        ops = lib.ops
    end)

    it("writes text that reads back as itself", function()
        local texts = {
            "[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2)",
            "[Level] > 1 OR ([Level] < 5 AND [Rare] = false)",
            "([Level] > 1 AND [Level] < 5) AND [Rare] = true",
            "[Name] CONTAINS wolf",
            "[Name] NOT CONTAINS wolf",
            "[Name] STARTS WITH Tim",
            '[Family] = "Wind Serpent"',
            [[[Name] = "say \"hi\" \\"]],
            '[Name] = ""',
            '[Name] = "a(b"',
            "[Family] IN (Cat, Wolf)",
            '[Family] NOT IN ("Wind Serpent")',
            "[Zone] IS BLANK",
            "[Zone] IS NOT BLANK",
            "NOT [Rare] = true",
            "NOT ([Level] > 1 OR [Level] < 0)",
            "[Level] > 1 AND NOT [Rare] = true",
            "[Level] >= -2.5",
            "[Level] BETWEEN 10 AND 20",
            "[Level] NOT BETWEEN 10 AND 20 OR [Rare] = true",
            "[Seen] >= 2026-11-12",
            '[Seen] BETWEEN 2026-11-01 AND "2026-11-12 18:30:00"',
            "",
        }
        for _, text in ipairs(texts) do
            assert.are.equal(text, schema:Format((schema:Parse(text))), text)
        end
    end)

    it("writes the words for the symbols, and the schema's labels", function()
        assert.are.equal(
            "[Level] > 1 AND NOT ([Rare] = true OR [Speed] < 2)",
            schema:Format((schema:Parse("[level]>1 & !([rare] = TRUE | [SPEED]<2.0)")))
        )
    end)

    it("parses what it writes into the same tree", function()
        local tree = {
            join = "and",
            children = {
                { column = "level", op = ops.gt, value = 1 },
                {
                    join = "and",
                    children = {
                        { column = "name", op = ops.inList, value = { "x y", "z" } },
                        { join = "and", negate = true, children = { { column = "zone", op = ops.blank } } },
                    },
                },
            },
        }
        assert.are.same(tree, schema:Parse(schema:Format(tree)))
    end)

    it("leaves out conditions that are not finished, and groups left with one", function()
        local tree = {
            join = "or",
            children = {
                { column = "level", op = ops.gt },
                { column = "diet", op = ops.eq, value = "Meat" },
                { column = "level", op = "near", value = 3 },
                { column = "rare", op = ops.eq, value = true },
                { join = "and", children = { { column = "level", op = ops.lt, value = 5 } } },
                { join = "and", children = {} },
                { column = "family", op = ops.inList, value = {} },
                { column = "level", op = ops.between, value = { 1 } },
            },
        }
        assert.are.equal("[Rare] = true OR [Level] < 5", schema:Format(tree))
    end)

    it("writes a group of one as that one", function()
        local tree = {
            join = "and",
            children = { { join = "or", children = { { column = "rare", op = ops.eq, value = true } } } },
        }
        assert.are.equal("[Rare] = true", schema:Format(tree))
    end)
end)
