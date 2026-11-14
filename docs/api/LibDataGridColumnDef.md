## Fields

| Name | Type | Description |
|------|------|-------------|
| align | `string?` | how cells and header line up (lib.aligns); left when not given |
| caseSensitive | `boolean?` | compare a string column's text as it is |
| choices | `LibDataGridChoice[] \| fun():LibDataGridChoice[]?` | an enum's choices |
| key | `string` |  |
| label | `string?` | the name filter text and a header use; the key when not given |
| mixin | `table?` | goes over ColumnMixin |
| renderer | `LibDataGridRenderer?` | draws the column's grid cells itself (an icon, a button) |
| text | `(fun(row: LibDataGridRow):string)?` | what a grid's cell shows; the value as text when not given |
| type | `string?` | lib.types; string when not given |
| value | `(fun(row: LibDataGridRow):number \| string \| nil \| boolean)?` | the row's value; row[key] when not given |

