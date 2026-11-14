# Changelog

## Unreleased

- Schemas of columns (string, number, enum, boolean, date), each a mixin a
  caller can extend.
- Filter text with AND/OR/NOT (also & | !), brackets, and per type the
  operators = != > >= < <= BETWEEN, NOT BETWEEN, CONTAINS, NOT CONTAINS,
  STARTS WITH, ENDS WITH, IN, NOT IN, IS BLANK, IS NOT BLANK; errors with a
  code and the characters they are about.
- Filter trees as plain data, written back as text that parses into the same
  tree.
- Views: a filter and a stable sort on several keys over a list of rows, with
  header-click toggling (Ctrl adds a key).
- FilterChanged and SortChanged through the view's own registry, Blizzard's
  CallbackRegistryMixin or CallbackHandler-1.0; each adapter, and any of a
  caller's, comes from the EventsMixin base.
- Widgets: a filter box (Apply, the parser's error under it, the text it is
  about highlighted), a grid (fixed and fill columns, sorting headers with
  Ctrl for more keys and 1/2/3 markers, a scrollbar, OnRowClick) and a Builder
  dialog (AND/OR and NOT chips, column/operator/value chips, add and remove,
  Apply or Cancel). Plain frames on every client, a SkinMixin for an addon's
  own look, and DG.L for their words.
- /libdatagrid in development copies: a demo window with the widgets.
- The grid stripes every other row (SkinMixin:Stripe), and the pick list opens
  over dialogs.
