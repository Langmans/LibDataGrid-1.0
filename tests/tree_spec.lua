-- A filter tree is plain data: groups ({ join, negate?, children }) and conditions
-- ({ column, op, value? }). The library makes and copies them; a caller edits them in place.

describe("a filter tree", function()
    local lib
    before_each(function()
        lib = NewClient()
    end)

    it("starts as an empty AND group, or the join asked for", function()
        assert.are.same({ join = "and", children = {} }, lib.NewFilter())
        assert.are.same({ join = "or", children = {} }, lib.NewFilter(lib.joins["or"]))
    end)

    it("copies a tree, lists included", function()
        local tree = {
            join = "and",
            negate = true,
            children = {
                { column = "level", op = lib.ops.gt, value = 1 },
                { join = "or", children = { { column = "family", op = lib.ops.inList, value = { 1, 2 } } } },
            },
        }
        local copy = lib.Copy(tree)
        assert.are.same(tree, copy)
        assert.are_not.equal(tree.children[2], copy.children[2])
        assert.are_not.equal(tree.children[2].children[1].value, copy.children[2].children[1].value)
    end)
end)
