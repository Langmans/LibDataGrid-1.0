# Using LibDataGrid in an addon

## Embedding

List it as an external in your `.pkgmeta`, pinned to a tag or commit:

```yaml
externals:
  Libs/LibDataGrid-1.0:
    url: https://github.com/Langmans/LibDataGrid-1.0.git
    tag: "1"
```

and include `Libs\LibDataGrid-1.0\lib.xml` after LibStub (and after
CallbackHandler-1.0, if you use that events adapter), in your `embeds.xml` or
`.toc`. The library's own `.toc` also lets it load on its own from the AddOns
folder.

## A schema: the columns

```lua
local DG = LibStub("LibDataGrid-1.0")
local T = DG.types

local schema = DG:NewSchema({
    { key = "name", label = "Name" },
    { key = "level", label = "Level", type = T.number },
    { key = "family", label = "Family", type = T.enum, choices = {
        { value = 1, text = "Cat" }, { value = 2, text = "Wolf" },
    } },
    { key = "speed", label = "Speed", type = T.number, value = function(row) return row.attackSpeed end },
    { key = "rare", label = "Rare", type = T.boolean },
    { key = "seen", label = "Seen", type = T.date },
})
```

| field | |
|---|---|
| `key` | the column's id; filter trees and sorts name it |
| `label` | what filter text and headers call it; the key when not given |
| `type` | `string` (default), `number`, `enum`, `boolean`, `date` |
| `value` | `function(row)` giving the row's value; `row[key]` when not given |
| `choices` | an enum's `{ value, text }` list, or a function returning one (asked each time, so it can follow the locale) |
| `caseSensitive` | compare a string column's text as it is; text compares without case by default |
| `mixin` | a table over `ColumnMixin`, to change how this column reads, writes or sorts values |

A date is a time in seconds, as `time()` gives it. A row is any table your
addon keeps; the library only reads it through the columns.

## A view: filter and sort over the rows

```lua
local view = schema:NewView()
local ok, err = view:SetFilterText("[Level] <= 20 AND [Family] IN (Cat, Wolf)")
if not ok then print(err.message, err.pos, err.finish) end

view:ToggleSort("level")         -- a click on the Level header
view:ToggleSort("name", true)    -- Ctrl-click: Name as the second key

local shown = {}                 -- keep it; Refresh refills it
local _, n = view:Refresh(beasts, shown)
```

`Refresh` fills the list it is given with the rows that pass, sorted, and
clears what was left past them; it builds no tables, so it can run on every
redraw.

## Filter text

| | |
|---|---|
| columns | `[Label]` or `[key]`, any case |
| joins | `AND` / `&`, `OR` / `\|`, `NOT` / `!`; AND binds before OR; brackets group |
| numbers, dates | `=` `!=` `>` `>=` `<` `<=` `BETWEEN a AND b` `NOT BETWEEN a AND b` `IS BLANK` `IS NOT BLANK` |
| text | `=` `!=` `CONTAINS` `NOT CONTAINS` `STARTS WITH` `ENDS WITH` `IN (a, b)` `NOT IN (a, b)` `IS BLANK` `IS NOT BLANK` |
| choices | `=` `!=` `IN (a, b)` `NOT IN (a, b)` `IS BLANK` `IS NOT BLANK`, by the choice's text |
| true/false | `=` `!=` with `true` or `false` |
| values | bare (`Cat`, `2.0`, `2026-11-12`) or quoted (`"Wind Serpent"`, `"say \"hi\""`) |
| dates | as MySQL writes them: `2026-11-12` (its midnight) or `"2026-11-12 18:30[:05]"` |

BETWEEN takes both ends as in range, as MySQL does. A blank value (nil or
`""`) fails every test except `IS BLANK` and the negative ones (`!=`,
`NOT CONTAINS`, `NOT IN`, `NOT BETWEEN`), which it passes.

Text that does not parse leaves the filter as it was and returns an error:
`code` (from `DG.errors`, for an addon that words it itself), `pos` and
`finish` (the characters it is about, from 1) and an English `message`, for
instance `Unknown column "Diet"`.

## The filter as a tree

The same filter as plain data, safe for saved variables. It names columns by
key, so it survives a change of locale where the text (in labels) might not.

```lua
local tree = {
    join = "and",
    children = {
        { column = "level", op = DG.ops.le, value = 20 },
        { join = "or", children = {
            { column = "family", op = DG.ops.eq, value = 1 },
            { column = "speed", op = DG.ops.lt, value = 2 },
        } },
        { join = "and", negate = true, children = { { column = "rare", op = DG.ops.eq, value = true } } },
    },
}
view:SetFilterModel(tree)       -- a copy goes in
local saved = view:GetFilterModel()   -- a copy comes out
print(view:GetFilterText())     -- [Level] <= 20 AND ([Family] = Cat OR [Speed] < 2) AND NOT [Rare] = true
```

IN takes a list as its value, BETWEEN its two ends (`{ 10, 20 }`). A condition
that is not finished (no value yet, an unknown column) is left out of the
filter, so a half-filled row in a builder filters nothing. To edit the view's
own tree in place, take it with `view:GetFilter()` and call
`view:FilterEdited()` afterwards.

## Sorting

`view:ToggleSort(key, additive)` is a header click: up, down, then off, and
without `additive` the other keys go. `view:SortIndex(key)` gives a header its
place and direction, for an arrow and a 1/2/3 marker. `SetSort` and `GetSort`
take and give `{ { key = "level", descending = true }, { key = "name" } }`. The
sort is stable, and blank values go last either way.

## Keeping the filter and sort

The library keeps nothing. A view says `FilterChanged` and `SortChanged`; store
what you want when you hear one, and set it back when the addon loads:

```lua
view:SetFilterModel(db.profile.filter)
view:SetSort(db.profile.sort or {})
view:RegisterCallback(DG.events.FilterChanged, function(_, v) db.profile.filter = v:GetFilterModel() end, MyAddon)
view:RegisterCallback(DG.events.SortChanged, function(_, v) db.profile.sort = v:GetSort() end, MyAddon)
```

## Events: three ways out

How the events go out is an adapter, picked when the view is made:

```lua
-- Default: the view's own registry, called like Blizzard's (owner, then the view).
local view = schema:NewView()
view:RegisterCallback(DG.events.FilterChanged, function(owner, view) end, MyAddon)

-- Blizzard's CallbackRegistryMixin.
local view = schema:NewView(DG.BlizzardEventsMixin)
view:RegisterCallback(view.Event.FilterChanged, function(owner, view) end, MyAddon)

-- CallbackHandler-1.0, for an Ace3 addon (embed CallbackHandler yourself).
local view = schema:NewView(DG.CallbackHandlerEventsMixin)
view.RegisterCallback(MyAddon, DG.events.SortChanged, function(event, view) end)
```

Your own adapter is a mixin with `InitEvents()` and `Notify(event)`, for
instance one that sends an AceEvent message:

```lua
local MessageEvents = {
    InitEvents = function() end,
    Notify = function(self, event) MyAddon:SendMessage("MYADDON_GRID_" .. event, self) end,
}
local view = schema:NewView(MessageEvents)
```

## Fixed sets

Every method and field is in the generated [API docs](api/index.md). The fixed
sets of names are not classes, so they are here:

| | |
|---|---|
| `DG.types` | `string`, `number`, `enum`, `boolean`, `date` |
| `DG.joins` | `and`, `or` |
| `DG.ops` | `eq` `ne` `gt` `ge` `lt` `le` `between` `notBetween` `contains` `notContains` `startsWith` `endsWith` `inList` `notInList` `blank` `notBlank` |
| `DG.takes` | what an operator takes after it: `value`, `list`, `range` (none for the blank tests) |
| `DG.events` | `FilterChanged`, `SortChanged` |
| `DG.errors` | `unknownColumn` `unclosedColumn` `expectedCondition` `expectedOperator` `operatorNotForType` `expectedValue` `unclosedString` `badNumber` `badBoolean` `badDate` `expectedRangeAnd` `unknownChoice` `expectedList` `unclosedList` `unclosedGroup` `unexpected` |

`DG.grammar` lists the operators in picker order and `DG.operators[id]` finds
one; each has `id`, `token`, `label`, `takes`, `types` and `test`.

## Changing how a part works

Every part is a mixin, and `lib:NewSchema(defs, ...)`, `schema:NewView(...)` and
a column's `mixin` put yours over the library's. A column that sorts by a
number of its own, say:

```lua
local ByRank = { SortValue = function(self, row) return RANK_ORDER[row.rank] end }
{ key = "rank", label = "Rank", mixin = ByRank }
```
