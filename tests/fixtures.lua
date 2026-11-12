-- A schema and rows the specs share: beasts, with a column of every type.

local M = {}

M.families = { cat = 1, wolf = 2, windSerpent = 3 }

---The beasts' schema for a freshly loaded library.
---@param lib LibDataGrid
---@return LibDataGridSchema
function M.Schema(lib)
    local T = lib.types
    return lib:NewSchema({
        { key = "name", label = "Name", type = T.string },
        { key = "level", label = "Level", type = T.number },
        {
            key = "family",
            label = "Family",
            type = T.enum,
            choices = {
                { value = M.families.cat, text = "Cat" },
                { value = M.families.wolf, text = "Wolf" },
                { value = M.families.windSerpent, text = "Wind Serpent" },
            },
        },
        {
            key = "speed",
            label = "Speed",
            type = T.number,
            value = function(row)
                return row.attackSpeed
            end,
        },
        { key = "rare", label = "Rare", type = T.boolean },
        { key = "zone", label = "Zone", type = T.string, caseSensitive = true },
        { key = "seen", label = "Seen", type = T.date },
    })
end

---A time in seconds, as time{} gives it for this local date.
---@return number
function M.Time(year, month, day, hour, min, sec)
    return os.time({ year = year, month = month, day = day, hour = hour or 0, min = min or 0, sec = sec or 0 })
end

---The rows, new each call so a test may change them.
---@return table[]
function M.Rows()
    local f = M.families
    return {
        {
            name = "Timber Wolf",
            level = 10,
            family = f.wolf,
            attackSpeed = 2.0,
            rare = false,
            zone = "Elwynn",
            seen = M.Time(2026, 11, 12),
        },
        {
            name = "Mangy Wolf",
            level = 6,
            family = f.wolf,
            attackSpeed = 2.0,
            rare = false,
            zone = "Elwynn",
            seen = M.Time(2026, 11, 12, 18, 30),
        },
        { name = "Prowler", level = 10, family = f.cat, attackSpeed = 1.5, rare = false, zone = "Westfall" },
        { name = "Humar the Pridelord", level = 23, family = f.cat, attackSpeed = 1.2, rare = true, zone = "Barrens" },
        { name = "Thunderhead", level = 23, family = f.windSerpent, attackSpeed = 2.0, rare = false },
        { name = "Broken Tooth", level = 37, family = f.cat, attackSpeed = 1.0, rare = true, zone = "Badlands" },
    }
end

---The names of rows, in order.
---@param rows table[]
---@param n number?
---@return string[]
function M.Names(rows, n)
    local names = {}
    for i = 1, n or #rows do
        names[i] = rows[i].name
    end
    return names
end

return M
