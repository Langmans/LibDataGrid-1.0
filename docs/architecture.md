# How it fits together

Each part is a mixin in its own file under `Mixins\`; `lib:NewSchema(defs, ...)`
and `schema:NewView(...)` put the caller's mixins over the library's, so any
method can be replaced. The operators live in one table (`Core\Grammar.lua`):
the parser, the formatter, the compiler and later the Builder all read it, so an
operator cannot exist in one and not in another.

```mermaid
flowchart LR
    subgraph Core
        Grammar["Grammar<br/>operators: token, types, test"]
    end
    subgraph Schema["SchemaMixin"]
        Column["ColumnMixin<br/>read, fold, parse and write values"]
        Parser["ParserMixin<br/>text → tree"]
        Formatter["FormatterMixin<br/>tree → text"]
        Compiler["CompilerMixin<br/>tree → predicate"]
    end
    subgraph View["ViewMixin"]
        Sort["SortMixin<br/>multi-key, stable"]
        Events["events adapter<br/>Registry · Blizzard · CallbackHandler"]
    end
    Grammar --> Parser & Formatter & Compiler
    Column --> Parser & Formatter & Compiler & Sort
    Text(["filter text"]) --> Parser --> Tree(["filter tree"])
    Tree --> Formatter --> Text
    Tree --> Compiler --> Passes(["passes(row)"])
    Rows(["rows"]) --> Refresh["view:Refresh"]
    Passes --> Refresh
    Sort --> Refresh --> Shown(["shown rows"])
    View -- FilterChanged / SortChanged --> Events
```

## Patterns

- **Mixin** for composition, with Blizzard's own `Mixin` and `CreateFromMixins`
  (both clients have them in `Blizzard_SharedXMLBase`). `SchemaMixin` is the
  parser, formatter and compiler mixins together; `ViewMixin` is the events
  and sort mixins plus its own methods.
- **Strategy**: each operator carries its test. A negative operator is its
  opposite's test turned round, so a blank value, which fails every test,
  passes the negative ones.
- **Composite**: a filter is a tree of groups (`children`) and conditions; the
  only tag is whether a node has `children`.
- **Interpreter**: the parser reads text into the tree by recursive descent (OR
  binds loosest, then AND, then NOT; brackets keep the group they make), and
  the compiler turns the tree into one closure, built once per filter, so a
  refresh parses nothing and builds no tables.
- **Observer** with **adapters**: the view only calls `InitEvents` and
  `Notify(event)`; the adapter decides where the event goes.

## Loading

`LibDataGrid-1.0.lua` registers the library with LibStub and sets
`lib.pending`; every other file returns at once unless it is set, and
`ViewMixin.lua`, the last in `lib.xml`, clears it. A copy LibStub turned away
(the same or an older MINOR) so changes nothing.

## Filter text and the tree

The formatter writes what the parser reads: a nested group of more than one is
bracketed, a group of one is written as that one, conditions that are not
finished are left out, and values are quoted when the parser would not read
them bare. So `Parse(Format(tree))` gives the tree back, except that a group of
one comes back as its one child (a negated one as a negated AND group of it),
and `Format(Parse(text))` is the text in the schema's words.
