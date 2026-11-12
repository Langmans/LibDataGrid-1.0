-- The operator table: one list that the parser, the formatter, the compiler and the Builder read.

describe("the grammar", function()
    local lib
    before_each(function()
        lib = NewClient()
    end)

    it("names every operator once, by its id", function()
        for _, op in ipairs(lib.grammar) do
            assert.are.equal(op, lib.operators[op.id])
            assert.are.equal(op.id, lib.ops[op.id])
        end
    end)

    it("tries tokens longest first, so no token is cut short by an earlier one", function()
        local tokens = lib.tokens
        for i = 1, #tokens do
            for j = i + 1, #tokens do
                local a, b = tokens[i].token:lower(), tokens[j].token:lower()
                -- A later token that starts with an earlier one would never be reached.
                assert.is_false(#b > #a and b:sub(1, #a) == a, a .. " before " .. b)
            end
        end
    end)

    it("lists each type's operators in the table's order", function()
        local T, ops = lib.types, lib.ops
        local function ids(type)
            local list = {}
            for i, op in ipairs(lib.OperatorsFor(type)) do
                list[i] = op.id
            end
            return list
        end
        local ordered =
            { ops.eq, ops.ne, ops.gt, ops.ge, ops.lt, ops.le, ops.between, ops.notBetween, ops.blank, ops.notBlank }
        assert.are.same(ordered, ids(T.number))
        assert.are.same(ordered, ids(T.date))
        assert.are.same({
            ops.eq,
            ops.ne,
            ops.contains,
            ops.notContains,
            ops.startsWith,
            ops.endsWith,
            ops.inList,
            ops.notInList,
            ops.blank,
            ops.notBlank,
        }, ids(T.string))
        assert.are.same({ ops.eq, ops.ne, ops.inList, ops.notInList, ops.blank, ops.notBlank }, ids(T.enum))
        assert.are.same({ ops.eq, ops.ne }, ids(T.boolean))
        assert.are.same({}, ids("colour"))
    end)

    it("gives the same list each time", function()
        assert.are.equal(lib.OperatorsFor(lib.types.number), lib.OperatorsFor(lib.types.number))
    end)
end)
