--@debug@
-- A demo window for checking the widgets in the game: /libdatagrid opens a filter box and a grid
-- over sample beasts, with the Builder behind the filter box's button. Only the library's own .toc
-- loads it (an addon embedding lib.xml never does), and the packager drops everything between the
-- debug markers, so a release has none of it.

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]

local T = lib.types
local NAMES = {
    "Timber Wolf",
    "Mangy Wolf",
    "Prowler",
    "Thunderhead",
    "Broken Tooth",
    "Humar",
    "Bloodmane",
    "Silithid Swarmer",
    "Ironjaw",
    "Cliff Stormer",
    "Sludge Beast",
    "Snarler",
}
local FAMILIES = { "Wolf", "Cat", "Wind Serpent", "Bear", "Boar" }
local ZONES = { "Elwynn Forest", "Westfall", "The Barrens", "Badlands" }
local SPEEDS = { 1.0, 1.2, 1.5, 2.0 }
local SIZE, PAD, TOP = { 600, 420 }, 10, 30

---Sample rows, the same each time but for when they were seen.
---@return LibDataGridRow[]
local function Rows()
    local rows, now = {}, time()
    for i = 1, 3 * #NAMES do
        rows[i] = {
            name = NAMES[(i - 1) % #NAMES + 1] .. (i > #NAMES and (" " .. math.ceil(i / #NAMES)) or ""),
            level = 1 + (i * 7) % 60,
            family = i % #FAMILIES + 1,
            speed = SPEEDS[i % #SPEEDS + 1],
            rare = i % 9 == 0,
            zone = i % 10 ~= 0 and ZONES[i % #ZONES + 1] or nil,
            seen = now - i * 5 * 3600,
        }
    end
    return rows
end

---@return LibDataGridSchema
local function Schema()
    local choices = {}
    for value, text in ipairs(FAMILIES) do
        choices[value] = { value = value, text = text }
    end
    return lib:NewSchema({
        { key = "name", label = "Name" },
        { key = "level", label = "Level", type = T.number },
        { key = "family", label = "Family", type = T.enum, choices = choices },
        { key = "speed", label = "Speed", type = T.number },
        { key = "rare", label = "Rare", type = T.boolean },
        { key = "zone", label = "Zone" },
        { key = "seen", label = "Seen", type = T.date },
    })
end

---@class LibDataGridDemo: Frame
---@field box LibDataGridFilterBoxMixin
---@field grid LibDataGridGridMixin

local function Open()
    if lib.demo then
        lib.demo:Show()
        return
    end
    local name = lib.name .. "Demo"
    local demo = CreateFrame("Frame", name, UIParent, "BackdropTemplate") --[[@as LibDataGridDemo]]
    demo:SetSize(SIZE[1], SIZE[2])
    demo:SetPoint("CENTER")
    demo:SetMovable(true)
    demo:EnableMouse(true)
    demo:RegisterForDrag("LeftButton")
    demo:SetScript("OnDragStart", demo.StartMoving)
    demo:SetScript("OnDragStop", demo.StopMovingOrSizing)
    table.insert(UISpecialFrames, name)
    lib.SkinMixin:Backdrop(demo)
    local title = demo:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetText(lib.name)
    CreateFrame("Button", nil, demo, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -2, -2)

    local view = Schema():NewView()
    demo.box = lib:CreateFilterBox(demo, view)
    demo.box:SetPoint("TOPLEFT", PAD, -TOP)
    demo.box:SetPoint("TOPRIGHT", -PAD, -TOP)
    demo.grid = lib:CreateGrid(demo, view)
    demo.grid:SetPoint("TOPLEFT", demo.box, "BOTTOMLEFT", 0, -4)
    demo.grid:SetSize(SIZE[1] - 2 * PAD, SIZE[2] - TOP - demo.box:GetHeight() - 4 - PAD)
    demo.grid:AddFillColumn("name", 2)
    demo.grid:AddFixedWidthColumn("level", 50)
    demo.grid:AddFillColumn("family")
    demo.grid:AddFixedWidthColumn("speed", 50)
    demo.grid:AddFixedWidthColumn("rare", 50)
    demo.grid:AddFillColumn("zone")
    demo.grid:AddFillColumn("seen")
    demo.grid:SetRows(Rows())
    lib.demo = demo
end

SLASH_LIBDATAGRID1 = "/libdatagrid"
SlashCmdList.LIBDATAGRID = Open
--@end-debug@
