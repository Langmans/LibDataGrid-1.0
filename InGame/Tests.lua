--@debug@
-- Tests that run in the game, through WoWUnit (an addon of its own: install it to run them). They
-- check what only the real client can say: the Blizzard code the library builds on, and how font
-- strings and edit boxes behave, which the busted specs' test client only assumes. Only the
-- library's own .toc loads this file, and the packager drops what is between the debug markers.
-- tests/ingame_spec.lua runs the same tests on the test client.

local Unit = WoWUnit
if not Unit then return end

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
local AreEqual, IsTrue, IsFalse, Exists = Unit.AreEqual, Unit.IsTrue, Unit.IsFalse, Unit.Exists
local T = lib.types

local Tests = Unit("LibDataGrid-1.0", "PLAYER_LOGIN")

---@return LibDataGridSchema
local function Schema()
    return lib:NewSchema({
        { key = "level", label = "Level", type = T.number },
        { key = "rare", label = "Rare", type = T.boolean },
        { key = "seen", label = "Seen", type = T.date },
    })
end

---@return LibDataGridRow[]
local function Rows()
    return { { level = 3, rare = true }, { level = 1, rare = false }, { level = 2 } }
end

function Tests:BlizzardMixinsExist()
    Exists(Mixin)
    Exists(CreateFromMixins)
    Exists(CallbackRegistryMixin)
end

function Tests:DatesGoThroughTimeAndDate()
    local seen = Schema():Column("seen") --[[@as LibDataGridColumnMixin]]
    AreEqual("2026-11-12 18:30:00", seen:FormatValue(seen:ParseValue("2026-11-12 18:30") --[[@as number]]))
    IsFalse(seen:ParseValue("2026-02-30"))
end

function Tests:FilterTextParsesAndFormatsBack()
    local schema = Schema()
    local tree = schema:Parse("[level] between 1 && 5 || ![rare] = true") --[[@as LibDataGridGroup]]
    AreEqual("[Level] BETWEEN 1 AND 5 OR NOT [Rare] = true", schema:Format(tree))
end

function Tests:BlizzardEventsAdapterCalls()
    local view = Schema():NewView(lib.BlizzardEventsMixin) --[[@as LibDataGridBlizzardView]]
    local heard
    view:RegisterCallback(view.Event.SortChanged, function(owner)
        heard = owner
    end, "test")
    view:ToggleSort("level")
    AreEqual("test", heard)
end

function Tests:CallbackHandlerAdapterCalls()
    local view = Schema():NewView(lib.CallbackHandlerEventsMixin) --[[@as LibDataGridCallbackHandlerView]]
    ---@type string?
    local heard
    ---@param event string
    view.RegisterCallback("test", lib.events.SortChanged, function(event)
        heard = event
    end)
    view:ToggleSort("level")
    AreEqual(lib.events.SortChanged, heard)
end

-- The library doubles every | it shows (DG.ToEditBox), counting on font strings and edit boxes
-- showing || as one bar.
function Tests:FontStringShowsDoubledBarAsOne()
    local label = UIParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetText("a||b")
    local doubled = label:GetStringWidth()
    label:SetText("a|b")
    AreEqual(label:GetStringWidth(), doubled)
    label:Hide()
end

-- The filter box takes OnTextChanged from user input as typing; text set in code must not be.
function Tests:SetTextIsNotTyping()
    local edit = CreateFrame("EditBox", nil, UIParent, "InputBoxTemplate")
    edit:SetAutoFocus(false)
    local typed
    ---@param _ EditBox
    ---@param userInput boolean
    edit:SetScript("OnTextChanged", function(_, userInput)
        typed = userInput
    end)
    edit:SetText("[Level] > 1")
    IsFalse(typed)
    edit:Hide()
end

function Tests:FilterBoxShowsColoursAndKeepsText()
    local view = Schema():NewView()
    local box = lib:CreateFilterBox(UIParent, view)
    box:SetWidth(400)
    view:SetFilterText("[Level] > 1 || [Rare] = true")
    AreEqual("[Level] > 1 OR [Rare] = true", box:GetText())
    IsTrue(box.edit:GetText():find("|c", 1, true))
    box:Hide()
end

function Tests:GridSortsOnHeaderClick()
    local view = Schema():NewView()
    local grid = lib:CreateGrid(UIParent, view)
    grid:SetSize(300, 200)
    grid:AddFillColumn("level")
    grid:SetRows(Rows())
    grid.heads[1]:Click()
    AreEqual(1, grid.shown[1].level)
    AreEqual(3, grid.count)
    grid:Hide()
end

function Tests:PickListLiesOverDialogs()
    local picker = lib:CreatePicker(UIParent, nil, function() end)
    picker:SetWidth(100)
    picker:SetChoices({ 1 }, { "One" }, 1)
    picker:Click()
    local list = lib.pickList --[[@as LibDataGridPickList]]
    AreEqual("FULLSCREEN_DIALOG", list:GetFrameStrata())
    list:Hide()
    picker:Hide()
end
--@end-debug@
