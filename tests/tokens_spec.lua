-- Filter text as tokens, for syntax highlighting: each piece with its kind, as the parser read it.

local fixtures = require("tests.fixtures")

describe("filter text as tokens", function()
    local lib, schema, K
    before_each(function()
        lib = NewClient()
        schema = fixtures.Schema(lib)
        K = lib.tokenKinds
    end)

    ---Each token as { kind, the text it covers }.
    local function tokens(text)
        local out = {}
        for i, token in ipairs((schema:Tokens(text))) do
            out[i] = { token.kind, text:sub(token.start, token.finish) }
        end
        return out
    end

    it("names every piece: columns, operators, values, keywords and brackets", function()
        assert.are.same({
            { K.column, "[Level]" },
            { K.operator, ">=" },
            { K.value, "10" },
            { K.keyword, "AND" },
            { K.bracket, "(" },
            { K.column, "[Family]" },
            { K.operator, "in" },
            { K.bracket, "(" },
            { K.value, "Cat" },
            { K.bracket, "," },
            { K.value, "Wolf" },
            { K.bracket, ")" },
            { K.keyword, "|" },
            { K.keyword, "NOT" },
            { K.column, "[Name]" },
            { K.operator, "NOT   CONTAINS" },
            { K.value, '"a b"' },
            { K.bracket, ")" },
        }, tokens('[Level] >= 10 AND ([Family] in (Cat, Wolf) | NOT [Name] NOT   CONTAINS "a b")'))
    end)

    it("reads BETWEEN's AND as part of the operator, not as the AND that joins", function()
        assert.are.same({
            { K.column, "[Level]" },
            { K.operator, "BETWEEN" },
            { K.value, "1" },
            { K.operator, "&" },
            { K.value, "5" },
            { K.keyword, "AND" },
            { K.column, "[Rare]" },
            { K.operator, "=" },
            { K.value, "true" },
        }, tokens("[Level] BETWEEN 1 & 5 AND [Rare] = true"))
    end)

    it("marks everything from where the text stops making sense as an error", function()
        assert.are.same({
            { K.column, "[Level]" },
            { K.operator, ">=" },
            { K.error, "ten AND [x" },
        }, tokens("[Level] >= ten AND [x"))
        local list, err = schema:Tokens("[Level] >= ten")
        assert.are.equal(lib.errors.badNumber, err.code)
        assert.are.equal(3, #list)
    end)

    it("has nothing to mark past the end, or in no text", function()
        assert.are.same({ { K.column, "[Level]" }, { K.operator, ">" } }, tokens("[Level] >"))
        assert.are.same({}, tokens(""))
        assert.is_nil(select(2, schema:Tokens("[Level] > 1")))
    end)

    it("leaves Parse as it was", function()
        schema:Tokens("[Level] > 1")
        assert.are.same(
            { join = "and", children = { { column = "rare", op = lib.ops.eq, value = true } } },
            schema:Parse("[Rare] = true")
        )
    end)
end)
