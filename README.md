# LibDataGrid-1.0

Filtering and sorting for lists of rows in World of Warcraft addons, the way a
data grid does it: a filter written as text, such as

```text
[Level] <= 20 AND ([Family] = Cat OR [Speed] < 2.0)
```

or built as a tree of AND/OR groups, and a sort on several columns at once
(Ctrl-click a header to add a key). Works on WoW: Forever and Classic Era.

```lua
local DG = LibStub("LibDataGrid-1.0")
local view = DG:NewSchema({
    { key = "name", label = "Name" },
    { key = "level", label = "Level", type = DG.types.number },
}):NewView()

view:SetFilterText("[Level] BETWEEN 10 AND 20 AND [Name] CONTAINS wolf")
view:ToggleSort("level")
local shown = {}
view:Refresh(beasts, shown)
```

On top of that, three widgets: a filter box (the text, Apply, the error under
it), a grid (headers that sort, Ctrl for a second key, a scrollbar) and a Builder
dialog for AND/OR groups with column, operator and value chips. All plain
frames, with a skin an addon can swap for its own look.

## Docs

- [Using it in an addon](docs/usage.md): embedding, columns, filter text, the
  filter tree, sorting, keeping the filter, events.
- [API](docs/api/index.md): every class, method and field, generated from the
  docblocks by WoW Lua LS (`lua tests/check.lua docs`; the pre-commit hook runs
  it, and CI fails when the docs are out of date).
- [How it fits together](docs/architecture.md): the parts, a diagram, the
  patterns behind them.

## Versions

The major version is in the name: `LibDataGrid-1.0` keeps its API; a change
that breaks it becomes `LibDataGrid-2.0`. Within it, `MINOR` in
`LibDataGrid-1.0.lua` is a whole number that goes up by one with every release,
and the release tag is that same number. LibStub keeps the copy with the
highest minor. CI fails on a release tag that is not MINOR.

## Development

The same setup as [LibGoThere-1.0](https://github.com/Langmans/LibGoThere-1.0):
busted and luacov on Lua 5.1, StyLua, WoW Lua LS, all through `tests/check.lua`
(`tests\setup-lua.ps1` builds the tools on Windows and turns on the hooks in
`.githooks`). Line and type coverage are held at 100%, and `docs/api` is never
edited by hand. `tests/wow.lua` and `tests/frames.lua` stand in for the little
of the game the library uses: `Mixin`, `CreateFromMixins`,
`CallbackRegistryMixin`, `time`, `date`, `wipe`, and frames.

What only the real client can tell (the Blizzard code the library builds on,
how edit boxes and font strings treat `|`) is tested in the game too:
`InGame/Tests.lua` holds [WoWUnit](https://github.com/Jaliborc/WoWUnit) tests
that run at login when WoWUnit is installed, in development copies only (the
packager drops them). `tests/ingame_spec.lua` runs the same tests on the test
client, so a test that fails in the game points at the client.

## License

MIT, see [LICENSE](LICENSE).
