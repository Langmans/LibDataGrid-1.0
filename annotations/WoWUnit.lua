---@meta
-- WoWUnit (github.com/Jaliborc/WoWUnit), the addon the in-game tests run in: only what
-- InGame/Tests.lua uses.

---A group of tests: each function set on it is a test.
---@class WoWUnitGroup: { [string]: fun(self: WoWUnitGroup) }

---@class WoWUnitLibrary
---@overload fun(name: string, ...: string): WoWUnitGroup
---@field AreEqual fun(expected: LibDataGridValue|table|nil, actual: LibDataGridValue|table|nil)
---@field IsTrue fun(value: LibDataGridValue|table|nil)
---@field IsFalse fun(value: LibDataGridValue|table|nil)
---@field Exists fun(value: LibDataGridValue|table|function|nil)

---@type WoWUnitLibrary?
WoWUnit = nil
