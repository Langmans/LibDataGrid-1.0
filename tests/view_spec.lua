-- A view: a schema's filter and sort over a list of rows, and the events it sends when they change.

local fixtures = require("tests.fixtures")

describe("a view", function()
    local lib, schema, view, rows, shown
    before_each(function()
        lib = NewClient()
        schema = fixtures.Schema(lib)
        view = schema:NewView()
        rows, shown = fixtures.Rows(), {}
    end)

    ---The names the view shows after a refresh.
    local function names()
        local _, n = view:Refresh(rows, shown)
        return fixtures.Names(shown, n)
    end

    describe("its filter", function()
        it("starts empty and shows every row in the order given", function()
            assert.are.equal("", view:GetFilterText())
            assert.are.same(fixtures.Names(rows), names())
        end)

        it("is set as text, and read back in the schema's words", function()
            assert.is_true(view:SetFilterText("[level] = 10 & [family] = cat"))
            assert.are.same({ "Prowler" }, names())
            assert.are.equal("[Level] = 10 AND [Family] = Cat", view:GetFilterText())
        end)

        it("keeps the filter it had when the text does not parse", function()
            view:SetFilterText("[Level] = 10")
            local ok, err = view:SetFilterText("[Level] =")
            assert.is_false(ok)
            assert.are.equal(lib.errors.expectedValue, err.code)
            assert.are.equal("[Level] = 10", view:GetFilterText())
        end)

        it("is set and read as a tree, a copy each way", function()
            local tree = { join = "and", children = { { column = "rare", op = lib.ops.eq, value = true } } }
            view:SetFilterModel(tree)
            tree.children[1].value = false
            assert.are.same({ "Humar the Pridelord", "Broken Tooth" }, names())
            local model = view:GetFilterModel()
            model.children = {}
            assert.are.equal("[Rare] = true", view:GetFilterText())
        end)

        it("is the empty filter when the tree is nil", function()
            view:SetFilterText("[Level] = 10")
            view:SetFilterModel(nil)
            assert.are.same(lib.NewFilter(), view:GetFilterModel())
        end)

        it("takes the tree it was handed as its own, for a caller that edits it in place", function()
            local tree = view:GetFilter()
            tree.children[1] = { column = "level", op = lib.ops.gt, value = 23 }
            view:FilterEdited()
            assert.are.same({ "Broken Tooth" }, names())
        end)
    end)

    describe("its sort", function()
        it("orders by several keys, each either way, keeping ties in the order given", function()
            view:SetSort({ { key = "level", descending = true }, { key = "name" } })
            assert.are.same({
                "Broken Tooth",
                "Humar the Pridelord",
                "Thunderhead",
                "Prowler",
                "Timber Wolf",
                "Mangy Wolf",
            }, names())
            view:SetSort({ { key = "speed" } })
            assert.are.same(
                { "Broken Tooth", "Humar the Pridelord", "Prowler", "Timber Wolf", "Mangy Wolf", "Thunderhead" },
                names()
            )
        end)

        it("puts blank values last either way", function()
            view:SetSort({ { key = "zone" } })
            local list = names()
            assert.are.equal("Broken Tooth", list[1])
            assert.are.equal("Thunderhead", list[6])
            view:SetSort({ { key = "zone", descending = true } })
            list = names()
            assert.are.equal("Prowler", list[1])
            assert.are.equal("Thunderhead", list[6])
        end)

        it("sorts the rows that pass the filter, and clears what was left in the list", function()
            shown = { 1, 2, 3, 4, 5, 6, 7, 8 }
            view:SetFilterText("[Family] = Cat")
            view:SetSort({ { key = "level", descending = true } })
            assert.are.same({ "Broken Tooth", "Humar the Pridelord", "Prowler" }, names())
            assert.are.equal(3, #shown)
        end)

        it("skips a key with no column", function()
            view:SetSort({ { key = "diet" }, { key = "level" } })
            assert.are.equal("Mangy Wolf", names()[1])
        end)

        it("is read back as a copy", function()
            view:SetSort({ { key = "level" } })
            local sort = view:GetSort()
            sort[1].descending = true
            assert.are.same({ { key = "level" } }, view:GetSort())
        end)

        describe("a click on a column head", function()
            ---The sort as "key+" / "key-" strings.
            local function sorted()
                local list = {}
                for i, entry in ipairs(view:GetSort()) do
                    list[i] = entry.key .. (entry.descending and "-" or "+")
                end
                return list
            end

            it("goes up, down, then off, and drops the other keys", function()
                view:ToggleSort("level")
                assert.are.same({ "level+" }, sorted())
                view:ToggleSort("level")
                assert.are.same({ "level-" }, sorted())
                view:ToggleSort("level")
                assert.are.same({}, sorted())
                view:SetSort({ { key = "level" }, { key = "name", descending = true } })
                view:ToggleSort("name")
                assert.are.same({}, sorted())
                view:ToggleSort("name")
                assert.are.same({ "name+" }, sorted())
            end)

            it("with Ctrl adds a key or turns it, leaving the others", function()
                view:ToggleSort("level")
                view:ToggleSort("name", true)
                assert.are.same({ "level+", "name+" }, sorted())
                view:ToggleSort("level", true)
                assert.are.same({ "level-", "name+" }, sorted())
                view:ToggleSort("level", true)
                assert.are.same({ "name+" }, sorted())
            end)

            it("tells the head its place and direction, for the 1/2/3 marker", function()
                view:SetSort({ { key = "level" }, { key = "name", descending = true } })
                assert.are.same({ 2, true }, { view:SortIndex("name") })
                assert.are.same({ 1, false }, { view:SortIndex("level") })
                assert.is_nil(view:SortIndex("zone"))
            end)
        end)
    end)

    describe("its events", function()
        local heard, owner
        before_each(function()
            heard, owner = {}, {}
            for _, event in pairs(lib.events) do
                view:RegisterCallback(event, function(who, from)
                    assert.are.equal(owner, who)
                    assert.are.equal(view, from)
                    heard[#heard + 1] = event
                end, owner)
            end
        end)

        it("say when the filter or the sort changed", function()
            local E = lib.events
            view:SetFilterText("[Level] = 10")
            view:SetFilterText("[Level] =")
            view:SetFilterModel(nil)
            view:FilterEdited()
            view:SetSort({})
            view:ToggleSort("level")
            assert.are.same({ E.FilterChanged, E.FilterChanged, E.FilterChanged, E.SortChanged, E.SortChanged }, heard)
        end)

        it("stop for an owner that unregisters", function()
            view:UnregisterCallback(lib.events.FilterChanged, owner)
            view:UnregisterCallback(lib.events.FilterChanged, {})
            view:SetFilterText("")
            view:ToggleSort("level")
            assert.are.same({ lib.events.SortChanged }, heard)
        end)

        it("go where a caller's mixin sends them instead", function()
            local sent = {}
            local Forward = {
                Notify = function(_, event)
                    sent[#sent + 1] = event
                end,
            }
            local forwarding = schema:NewView(Forward)
            forwarding:ToggleSort("level")
            assert.are.same({ lib.events.SortChanged }, sent)
        end)
    end)

    describe("its events through an adapter", function()
        it("go through CallbackHandler-1.0: the event's name, then the view", function()
            local cbView = schema:NewView(lib.CallbackHandlerEventsMixin)
            local heard, owner = {}, {}
            cbView.RegisterCallback(owner, lib.events.SortChanged, function(event, from)
                heard[#heard + 1] = { event, from }
            end)
            cbView:ToggleSort("level")
            assert.are.same({ { lib.events.SortChanged, cbView } }, heard)
            cbView.UnregisterCallback(owner, lib.events.SortChanged)
            cbView:ToggleSort("level")
            assert.are.equal(1, #heard)
        end)

        it("go through Blizzard's CallbackRegistryMixin: the owner, then the view", function()
            local blizzView = schema:NewView(lib.BlizzardEventsMixin)
            local heard, owner = {}, {}
            blizzView:RegisterCallback(blizzView.Event.FilterChanged, function(who, from)
                heard[#heard + 1] = { who, from }
            end, owner)
            blizzView:SetFilterText("[Level] = 10")
            assert.are.same({ { owner, blizzView } }, heard)
            assert.has_error(function()
                blizzView:TriggerEvent("Nope")
            end)
        end)

        it("all come from EventsMixin, the base an adapter of a caller's starts from", function()
            for _, adapter in ipairs({
                lib.RegistryEventsMixin,
                lib.BlizzardEventsMixin,
                lib.CallbackHandlerEventsMixin,
            }) do
                assert.is_function(adapter.InitEvents)
                assert.is_function(adapter.Notify)
            end
            local sent = {}
            local Messages = CreateFromMixins(lib.EventsMixin, {
                Notify = function(_, event)
                    sent[#sent + 1] = event
                end,
            })
            schema:NewView(Messages):ToggleSort("level")
            assert.are.same({ lib.events.SortChanged }, sent)
        end)

        it("go nowhere through the base alone", function()
            local quiet = schema:NewView(lib.EventsMixin)
            quiet:ToggleSort("level")
            assert.is_true(quiet:SetFilterText("[Level] = 10"))
        end)

        it("say plainly when the library behind the adapter is not loaded", function()
            LibStub.libs["CallbackHandler-1.0"] = nil
            assert.has_error(function()
                schema:NewView(lib.CallbackHandlerEventsMixin)
            end, "LibDataGrid-1.0: the CallbackHandler events adapter needs CallbackHandler-1.0 loaded")
            _G.CallbackRegistryMixin = nil
            assert.has_error(function()
                schema:NewView(lib.BlizzardEventsMixin)
            end, "LibDataGrid-1.0: the Blizzard events adapter needs CallbackRegistryMixin")
        end)
    end)
end)

describe("the library", function()
    it("takes a caller's mixins over a schema's own", function()
        local lib = NewClient()
        local schema = lib:NewSchema({ { key = "level", type = lib.types.number } }, {
            Format = function()
                return "mine"
            end,
        })
        assert.are.equal("mine", schema:Format(lib.NewFilter()))
    end)

    it("changes nothing when the same copy loads a second time", function()
        local lib = NewClient()
        local before = lib.ViewMixin
        LoadTocAgain()
        assert.are.equal(before, LibStub("LibDataGrid-1.0").ViewMixin)
        assert.is_nil(lib.pending)
    end)
end)
