## Fields

| Name | Type | Description |
|------|------|-------------|
| caseSensitive | `boolean?` | compare a string column's text as it is |
| choices | `LibDataGridChoice[] \| fun():LibDataGridChoice[]?` | an enum's choices |
| key | `string` |  |
| label | `string?` | the name filter text and a header use; the key when not given |
| mixin | `table?` | goes over ColumnMixin |
| type | `string?` | lib.types; string when not given |
| value | `(fun(row: LibDataGridRow):number \| string \| nil \| boolean)?` | the row's value; row[key] when not given |

