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
  CallbackRegistryMixin or CallbackHandler-1.0.
