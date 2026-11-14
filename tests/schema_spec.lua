-- Schemas and columns: how a column reads a row, and turns values into text and back.

local fixtures = require("tests.fixtures")

describe("a schema", function()
    local lib, schema
    before_each(function()
        lib = NewClient()
        schema = fixtures.Schema(lib)
    end)

    it("keeps its columns in order, each found by key", function()
        assert.are.equal(7, #schema.columns)
        assert.are.equal("level", schema.columns[2].key)
        assert.are.equal(schema.columns[2], schema:Column("level"))
        assert.is_nil(schema:Column("nope"))
    end)

    it("finds a column by label or key, either case", function()
        assert.are.equal(schema:Column("family"), schema:Find("FAMILY"))
        assert.are.equal(schema:Column("speed"), schema:Find("speed"))
        assert.is_nil(schema:Find("Diet"))
    end)

    it("labels a column by its key and makes it a string column when the definition does not say", function()
        local plain = lib:NewSchema({ { key = "note" } }):Column("note")
        assert.are.equal("note", plain.label)
        assert.are.equal(lib.types.string, plain.type)
    end)

    it("reads a row's field by key, or through the definition's value function", function()
        local row = fixtures.Rows()[3]
        assert.are.equal(10, schema:Column("level"):Value(row))
        assert.are.equal(1.5, schema:Column("speed"):Value(row))
    end)

    it("takes a mixin of the caller's over its own", function()
        local Shouting = {
            Value = function(self, row)
                return row[self.key]:upper()
            end,
        }
        local loud = lib:NewSchema({ { key = "name", mixin = Shouting } }):Column("name")
        assert.are.equal("PROWLER", loud:Value({ name = "Prowler" }))
        assert.are.equal("Prowler", loud:FormatValue("Prowler"))
    end)

    describe("a column's values as text", function()
        it("folds case unless the column is case sensitive", function()
            assert.are.equal("timber wolf", schema:Column("name"):Fold("Timber Wolf"))
            assert.are.equal("Elwynn", schema:Column("zone"):Fold("Elwynn"))
            assert.are.equal(3, schema:Column("level"):Fold(3))
        end)

        it("reads numbers, booleans, strings and choices", function()
            assert.are.equal(2.5, schema:Column("level"):ParseValue("2.5"))
            assert.are.equal(-3, schema:Column("level"):ParseValue("-3"))
            assert.is_true(schema:Column("rare"):ParseValue("TRUE"))
            assert.is_false(schema:Column("rare"):ParseValue("false"))
            assert.are.equal("20", schema:Column("name"):ParseValue("20"))
            assert.are.equal(fixtures.families.windSerpent, schema:Column("family"):ParseValue("wind serpent"))
        end)

        it("says why a value does not fit", function()
            local E = lib.errors
            assert.are.same({ nil, E.badNumber }, { schema:Column("level"):ParseValue("ten") })
            assert.are.same({ nil, E.badBoolean }, { schema:Column("rare"):ParseValue("yes") })
            assert.are.same({ nil, E.unknownChoice }, { schema:Column("family"):ParseValue("Bear") })
        end)

        it("writes values back the way it reads them", function()
            assert.are.equal("2.5", schema:Column("level"):FormatValue(2.5))
            assert.are.equal("true", schema:Column("rare"):FormatValue(true))
            assert.are.equal("Wind Serpent", schema:Column("family"):FormatValue(fixtures.families.windSerpent))
            assert.are.equal("Wolf", schema:Column("name"):FormatValue("Wolf"))
        end)

        it("reads and writes dates the way MySQL does, a day alone meaning its midnight", function()
            local seen = schema:Column("seen")
            assert.are.equal(fixtures.Time(2026, 11, 12), seen:ParseValue("2026-11-12"))
            assert.are.equal(fixtures.Time(2026, 11, 12, 18, 30), seen:ParseValue("2026-11-12 18:30"))
            assert.are.equal(fixtures.Time(2026, 11, 12, 18, 30, 5), seen:ParseValue("2026-11-12 18:30:05"))
            assert.are.equal("2026-11-12", seen:FormatValue(fixtures.Time(2026, 11, 12)))
            assert.are.equal("2026-11-12 18:30:05", seen:FormatValue(fixtures.Time(2026, 11, 12, 18, 30, 5)))
            assert.are.equal(fixtures.Time(2026, 11, 12), seen:SortValue({ seen = fixtures.Time(2026, 11, 12) }))
        end)

        it("says when a date is not one", function()
            local seen, E = schema:Column("seen"), lib.errors
            for _, text in ipairs({
                "12-11-2026",
                "2026-13-01",
                "2026-02-30",
                "2026-11-12 24:00",
                "2026-11-12 18:60",
                "soon",
            }) do
                assert.are.same({ nil, E.badDate }, { seen:ParseValue(text) }, text)
            end
        end)

        it("writes a choice it does not know as its value", function()
            assert.are.equal("99", schema:Column("family"):FormatValue(99))
        end)

        it("takes choices from a function, asked each time", function()
            local list = { { value = "a", text = "Alpha" } }
            local column = lib:NewSchema({
                {
                    key = "k",
                    type = lib.types.enum,
                    choices = function()
                        return list
                    end,
                },
            }):Column("k")
            assert.are.equal("a", column:ParseValue("alpha"))
            list = { { value = "b", text = "Beta" } }
            assert.are.equal("b", column:ParseValue("Beta"))
            assert.are.equal(list, column:Choices())
        end)

        it("has no choices unless it is an enum", function()
            assert.are.same({}, schema:Column("name"):Choices())
        end)
    end)

    describe("a column's cell", function()
        it("shows true and false as a green tick and a red cross, a blank as nothing", function()
            local rare = schema:Column("rare")
            assert.truthy(rare:CellText({ rare = true }):find("ReadyCheck-Ready", 1, true))
            assert.truthy(rare:CellText({ rare = false }):find("ReadyCheck-NotReady", 1, true))
            assert.are.equal("", rare:CellText({}))
            assert.are.equal("true", rare:FormatValue(true))
        end)

        it("takes an addon's own marks for true and false", function()
            lib.BOOLEAN_CELLS[true] = "yes"
            assert.are.equal("yes", schema:Column("rare"):CellText({ rare = true }))
        end)
    end)

    describe("a column's value to sort by", function()
        it("is the number, the folded string, the choice's text, or 0 and 1", function()
            local row = fixtures.Rows()[5]
            assert.are.equal(23, schema:Column("level"):SortValue(row))
            assert.are.equal("thunderhead", schema:Column("name"):SortValue(row))
            assert.are.equal("wind serpent", schema:Column("family"):SortValue(row))
            assert.are.equal(0, schema:Column("rare"):SortValue(row))
            assert.are.equal(1, schema:Column("rare"):SortValue({ rare = true }))
        end)

        it("is nil for a blank value", function()
            assert.is_nil(schema:Column("zone"):SortValue(fixtures.Rows()[5]))
            assert.is_nil(schema:Column("rare"):SortValue({}))
            assert.is_nil(schema:Column("name"):SortValue({ name = "" }))
        end)
    end)
end)
