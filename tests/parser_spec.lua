-- Filter text into a tree, and errors that say where and why.

local fixtures = require("tests.fixtures")

describe("parsing filter text", function()
    local lib, schema, ops, F
    before_each(function()
        lib = NewClient()
        schema = fixtures.Schema(lib)
        ops, F = lib.ops, fixtures.families
    end)

    local function cond(column, op, value)
        return { column = column, op = op, value = value }
    end

    local function group(join, children, negate)
        return { join = join, children = children, negate = negate }
    end

    it("reads a condition into a group of one", function()
        assert.are.same(group("and", { cond("level", ops.le, 20) }), schema:Parse("[Level] <= 20"))
    end)

    it("reads groups in brackets, AND before OR", function()
        assert.are.same(
            group("and", {
                cond("level", ops.le, 20),
                group("or", { cond("family", ops.eq, F.cat), cond("speed", ops.lt, 2) }),
            }),
            schema:Parse("[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2.0)")
        )
        assert.are.same(
            group("or", {
                cond("level", ops.gt, 1),
                group("and", { cond("level", ops.lt, 5), cond("rare", ops.eq, true) }),
            }),
            schema:Parse("[Level] > 1 OR [Level] < 5 AND [Rare] = true")
        )
    end)

    it("keeps a group that was written in brackets", function()
        assert.are.same(
            group("and", {
                group("and", { cond("level", ops.gt, 1), cond("level", ops.lt, 5) }),
                cond("rare", ops.eq, true),
            }),
            schema:Parse("([Level] > 1 AND [Level] < 5) AND [Rare] = true")
        )
    end)

    it("makes brackets round everything the whole filter", function()
        assert.are.same(
            group("or", { cond("level", ops.gt, 1), cond("rare", ops.eq, true) }),
            schema:Parse("(([Level] > 1 OR [Rare] = true))")
        )
    end)

    it("reads NOT, and the symbols & | ! as AND OR NOT", function()
        local expected = group("and", {
            cond("level", ops.gt, 1),
            group("or", { cond("rare", ops.eq, true), cond("level", ops.lt, 0) }, true),
        })
        assert.are.same(expected, schema:Parse("[Level] > 1 AND NOT ([Rare] = true OR [Level] < 0)"))
        assert.are.same(expected, schema:Parse("[Level] > 1 & !([Rare] = true | [Level] < 0)"))
        assert.are.same(group("and", { cond("rare", ops.eq, true) }, true), schema:Parse("![Rare] = true"))
    end)

    it("reads && and || as AND and OR too, as PHP writes them", function()
        assert.are.same(
            group("or", {
                group("and", { cond("level", ops.gt, 1), cond("rare", ops.eq, true) }),
                cond("level", ops.between, { 1, 5 }),
            }),
            schema:Parse("[Level] > 1 && [Rare] = true || [Level] BETWEEN 1 && 5")
        )
    end)

    it("takes keywords, operators and column names in any case and spacing", function()
        assert.are.same(
            group("and", { cond("level", ops.gt, 1), cond("name", ops.startsWith, "Tim") }),
            schema:Parse("  [level]>1 and [NAME] starts   with Tim ")
        )
    end)

    it("reads every operator", function()
        local cases = {
            { "[Level] = 3", cond("level", ops.eq, 3) },
            { "[Level] != 3", cond("level", ops.ne, 3) },
            { "[Level] >= 3", cond("level", ops.ge, 3) },
            { "[Name] CONTAINS wolf", cond("name", ops.contains, "wolf") },
            { "[Name] NOT CONTAINS wolf", cond("name", ops.notContains, "wolf") },
            { "[Name] ENDS WITH wolf", cond("name", ops.endsWith, "wolf") },
            { "[Family] IN (Cat, wolf)", cond("family", ops.inList, { F.cat, F.wolf }) },
            { "[Name] NOT IN (a,b)", cond("name", ops.notInList, { "a", "b" }) },
            { "[Zone] IS BLANK", cond("zone", ops.blank) },
            { "[Zone] IS NOT BLANK", cond("zone", ops.notBlank) },
            { "[Level] BETWEEN 10 AND 20", cond("level", ops.between, { 10, 20 }) },
            { "[Level] not between 10 & 20", cond("level", ops.notBetween, { 10, 20 }) },
            { "[Seen] >= 2026-11-12", cond("seen", ops.ge, fixtures.Time(2026, 11, 12)) },
            {
                '[Seen] BETWEEN 2026-11-01 AND "2026-11-12 18:30"',
                cond("seen", ops.between, { fixtures.Time(2026, 11, 1), fixtures.Time(2026, 11, 12, 18, 30) }),
            },
        }
        for _, case in ipairs(cases) do
            assert.are.same(group("and", { case[2] }), schema:Parse(case[1]), case[1])
        end
    end)

    it("reads the AND inside BETWEEN apart from the AND that joins", function()
        assert.are.same(
            group("and", { cond("level", ops.between, { 1, 5 }), cond("rare", ops.eq, true) }),
            schema:Parse("[Level] BETWEEN 1 AND 5 AND [Rare] = true")
        )
    end)

    it('reads quoted values, with \\" and \\\\ inside', function()
        assert.are.same(
            group("and", { cond("family", ops.eq, F.windSerpent) }),
            schema:Parse('[Family] = "Wind Serpent"')
        )
        assert.are.same(
            group("and", { cond("name", ops.eq, 'say "hi" \\') }),
            schema:Parse([[[Name] = "say \"hi\" \\"]])
        )
        assert.are.same(group("and", { cond("name", ops.eq, "") }), schema:Parse('[Name] = ""'))
    end)

    it("reads nothing as an empty filter", function()
        assert.are.same(group("and", {}), schema:Parse(""))
        assert.are.same(group("and", {}), schema:Parse("   "))
    end)

    describe("an error", function()
        local E
        before_each(function()
            E = lib.errors
        end)

        ---The error for this text, without its message.
        local function fail(text)
            local tree, err = schema:Parse(text)
            assert.is_nil(tree)
            assert.is_string(err.message)
            return { err.code, err.pos, err.finish }
        end

        it("names where it stopped and what it wanted", function()
            local cases = {
                { "[Diet] = Meat", E.unknownColumn, 2, 5 },
                { "[Level", E.unclosedColumn, 1, 6 },
                { "Level > 2", E.expectedCondition, 1, 5 },
                { "[Level] ~ 2", E.expectedOperator, 9, 9 },
                { "[Rare] > true", E.operatorNotForType, 8, 8 },
                { "[Level] > ten", E.badNumber, 11, 13 },
                { "[Level] >", E.expectedValue, 10, 10 },
                { '[Name] = "abc', E.unclosedString, 10, 13 },
                { "[Level] > 1 [Name] = x", E.unexpected, 13, 13 },
                { "[Level] > 1 )", E.unexpected, 13, 13 },
                { "([Level] > 1", E.unclosedGroup, 13, 13 },
                { "[Family] IN Cat", E.expectedList, 13, 15 },
                { "[Family] IN (Cat, Bear)", E.unknownChoice, 19, 22 },
                { "[Family] IN (Cat", E.unclosedList, 17, 17 },
                { "[Family] IN (Cat Wolf)", E.unclosedList, 18, 21 },
                { "[Level] > 1 AND", E.expectedCondition, 16, 16 },
                { "[] = 1", E.unknownColumn, 2, 1 },
                { "[Level] BETWEEN 10 OR 20", E.expectedRangeAnd, 20, 21 },
                { "[Level] BETWEEN 10", E.expectedRangeAnd, 19, 19 },
                { "[Seen] > 2026-02-30x", E.badDate, 10, 20 },
            }
            for _, case in ipairs(cases) do
                assert.are.same({ case[2], case[3], case[4] }, fail(case[1]), case[1])
            end
        end)

        it("quotes the text it stopped on", function()
            local _, err = schema:Parse("[Diet] = Meat")
            assert.are.equal('Unknown column "Diet"', err.message)
            _, err = schema:Parse("[Level] >")
            assert.are.equal("Expected a value, found the end", err.message)
        end)

        it("is not made of a caller's own bug, which goes on as an error", function()
            local broken = lib:NewSchema({
                {
                    key = "k",
                    mixin = {
                        ParseValue = function()
                            error("boom", 0)
                        end,
                    },
                },
            })
            assert.has_error(function()
                broken:Parse("[k] = 1")
            end, "boom")
        end)
    end)
end)
