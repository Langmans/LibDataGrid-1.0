-- The in-game tests (InGame/Tests.lua), run here on a stand-in for WoWUnit and the test client, so a
-- test that fails in the game points at the client, not at the test.

local function FakeWoWUnit()
    local groups = {}
    local unit = setmetatable({ groups = groups }, {
        __call = function(_, name, ...)
            local group = { name = name, events = { ... }, tests = {} }
            groups[#groups + 1] = group
            return setmetatable({}, {
                __newindex = function(_, test, run)
                    group.tests[#group.tests + 1] = { name = test, run = run }
                end,
            })
        end,
    })
    function unit.AreEqual(expected, actual)
        if expected ~= actual then error(("expected %s, got %s"):format(tostring(expected), tostring(actual)), 2) end
    end
    function unit.IsTrue(value)
        if not value then error("expected true", 2) end
    end
    unit.Exists = unit.IsTrue
    function unit.IsFalse(value)
        if value then error("expected false", 2) end
    end
    return unit
end

describe("the in-game tests", function()
    it("are left out without WoWUnit", function()
        _G.WoWUnit = nil
        NewClient()
    end)

    it("register one group, run at login, and all pass on the test client", function()
        local unit = FakeWoWUnit()
        _G.WoWUnit = unit
        NewClient()
        local groups = unit.groups
        assert.are.equal(1, #groups)
        assert.are.equal("LibDataGrid-1.0", groups[1].name)
        assert.are.same({ "PLAYER_LOGIN" }, groups[1].events)
        assert.is_true(#groups[1].tests >= 10)
        for _, test in ipairs(groups[1].tests) do
            local ok, err = pcall(test.run)
            assert(ok, test.name .. ": " .. tostring(err))
        end
        _G.WoWUnit = nil
    end)
end)
