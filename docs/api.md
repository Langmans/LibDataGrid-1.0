# API

`local DG = LibStub("LibDataGrid-1.0")`. Types are in
[annotations/LibDataGrid.lua](../annotations/LibDataGrid.lua).

## The library

| | |
|---|---|
| `DG:NewSchema(defs, ...mixins)` → schema | a schema for these column definitions; the mixins go over `SchemaMixin` |
| `DG.NewFilter(join?)` → group | an empty filter tree, AND unless another join is given |
| `DG.Copy(value)` → copy | a deep copy of a filter tree or a sort |
| `DG.OperatorsFor(type)` → operators | a column type's operators in picker order; the same list each time |
| `DG.IsBlank(value)` → boolean | nil or `""` |

### Fixed sets

| | |
|---|---|
| `DG.types` | `string`, `number`, `enum`, `boolean`, `date` |
| `DG.joins` | `and`, `or` |
| `DG.ops` | `eq` `ne` `gt` `ge` `lt` `le` `between` `notBetween` `contains` `notContains` `startsWith` `endsWith` `inList` `notInList` `blank` `notBlank` |
| `DG.takes` | what an operator takes after it: `value`, `list`, `range` (none for the blank tests) |
| `DG.events` | `FilterChanged`, `SortChanged` |
| `DG.errors` | `unknownColumn` `unclosedColumn` `expectedCondition` `expectedOperator` `operatorNotForType` `expectedValue` `unclosedString` `badNumber` `badBoolean` `badDate` `expectedRangeAnd` `unknownChoice` `expectedList` `unclosedList` `unclosedGroup` `unexpected` |

### The operator table

`DG.grammar` lists the operators in picker order, `DG.operators[id]` finds one.
Each has `id`, `token` (how text writes it), `label` (how a picker names it),
`takes`, `types` (a set of column types), `test(a, b)`, and `negates` (the
operator it is the opposite of) or `blank` (a test of blankness) where they
apply.

## Schema (`SchemaMixin`)

| | |
|---|---|
| `schema.columns` | the columns, in order |
| `schema:Column(key)` → column? | by key |
| `schema:Find(name)` → column? | by label or key, any case: how filter text names one |
| `schema:Parse(text)` → tree? , error? | filter text into a tree; `{ code, pos, finish, message }` when it does not parse |
| `schema:Format(tree)` → text | a tree into filter text that parses into the same tree; `""` for an empty one |
| `schema:Compile(tree)` → `passes(row)` | the function that says whether a row passes |
| `schema:IsComplete(condition)` → boolean | a known column, an operator its type has, and the value it takes |
| `schema:NewView(...mixins)` → view | a view over this schema; the mixins go over `ViewMixin` |

## Column (`ColumnMixin`)

| | |
|---|---|
| `column.key`, `.label`, `.type`, `.caseSensitive` | from the definition |
| `column:Value(row)` → value | the row's value: the definition's `value(row)`, else `row[key]` |
| `column:Fold(value)` → value | as tests compare it: a string column's text in lower case unless case sensitive |
| `column:Choices()` → choices | an enum's `{ value, text }` list |
| `column:ParseValue(text)` → value? , code? | a piece of filter text as a value, or the error code |
| `column:FormatValue(value)` → text | a value as filter text writes it |
| `column:SortValue(row)` → value? | what the row sorts by; nil when blank |

## View (`ViewMixin`)

| | |
|---|---|
| `view:SetFilterText(text)` → ok, error? | filters by this text; unchanged when it does not parse |
| `view:GetFilterText()` → text | the filter in the schema's labels |
| `view:SetFilterModel(tree?)` | filters by a copy of this tree; nil for none |
| `view:GetFilterModel()` → tree | a copy of the filter tree |
| `view:GetFilter()` → tree | the view's own tree, to edit in place |
| `view:FilterEdited()` | the own tree changed: use it from now on |
| `view:SetSort(sort)` / `view:GetSort()` → sort | `{ { key, descending? }, ... }`, copied each way |
| `view:ToggleSort(key, additive?)` | a header click: up, down, off; `additive` keeps the other keys |
| `view:SortIndex(key)` → index?, descending? | the key's place in the sort |
| `view:Refresh(rows, out)` → out, n | fills `out` with the rows that pass, sorted |

## Events

| adapter | register | a callback gets |
|---|---|---|
| default (`RegistryEventsMixin`) | `view:RegisterCallback(event, func, owner)`, `view:UnregisterCallback(event, owner)` | `owner, view` |
| `DG.BlizzardEventsMixin` | `view:RegisterCallback(view.Event.X, func, owner)` (Blizzard's `CallbackRegistryMixin`) | `owner, view` |
| `DG.CallbackHandlerEventsMixin` | `view.RegisterCallback(owner, event, method)` (CallbackHandler-1.0) | `event, view` |

An adapter of your own is a mixin with `InitEvents()` and `Notify(event)`.
