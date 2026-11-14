---@meta
-- Types for LibDataGrid-1.0. Not loaded by the game (not in the .toc); the language server reads it.
-- Each mixin's class is declared in its own file, over the table its methods go on.

---@class LibDataGrid
---@field pending boolean? set while this copy's files load
---@field events table<string, string>
---@field types table<string, string>
---@field joins table<string, string>
---@field errors table<string, string>
---@field takes table<string, string>
---@field grammar LibDataGridOperator[] the operators, in the order a picker lists them
---@field operators table<string, LibDataGridOperator> each operator by id
---@field ops table<string, string> each operator's id by name
---@field tokens LibDataGridOperator[] the operators as the parser tries them, longest token first
---@field IsBlank fun(value: LibDataGridValue?): boolean
---@field OperatorsFor fun(type: string): LibDataGridOperator[]
---@field NewFilter fun(join: string?): LibDataGridGroup
---@field Copy fun(value: table|LibDataGridValue): table|LibDataGridValue
---@field NewSchema fun(self: LibDataGrid, defs: LibDataGridColumnDef[], ...: table): LibDataGridSchema
---@field ColumnMixin LibDataGridColumnMixin
---@field ParserMixin LibDataGridParserMixin
---@field FormatterMixin LibDataGridFormatterMixin
---@field CompilerMixin LibDataGridCompilerMixin
---@field SchemaMixin LibDataGridSchemaMixin
---@field EventsMixin LibDataGridEventsMixin
---@field RegistryEventsMixin LibDataGridRegistryEventsMixin
---@field CallbackHandlerEventsMixin LibDataGridCallbackHandlerEventsMixin
---@field BlizzardEventsMixin LibDataGridBlizzardEventsMixin
---@field SortMixin LibDataGridSortMixin
---@field ViewMixin LibDataGridViewMixin
---@field name string the library's LibStub name
---@field L table<string, string> the widgets' words, English unless an addon sets them
---@field SCROLLBAR_WIDTH number
---@field pickList LibDataGridPickList? the pick list every picker shares, made when first opened
---@field SkinMixin LibDataGridSkinMixin
---@field ScrollBarMixin LibDataGridScrollBarMixin
---@field PickerMixin LibDataGridPickerMixin
---@field FilterBoxMixin LibDataGridFilterBoxMixin
---@field GridMixin LibDataGridGridMixin
---@field CreateGrid fun(self: LibDataGrid, parent: Frame, view: LibDataGridView, skin: LibDataGridSkinMixin?, ...: table): LibDataGridGridMixin
---@field CreateScrollBar fun(self: LibDataGrid, list: Frame, OnScroll: fun(offset: number)): LibDataGridScrollBarMixin
---@field CreatePicker fun(self: LibDataGrid, parent: Frame, skin: LibDataGridSkinMixin?, OnPick: fun(value: LibDataGridValue)): LibDataGridPickerMixin
---@field CreateFilterBox fun(self: LibDataGrid, parent: Frame, view: LibDataGridView, skin: LibDataGridSkinMixin?, ...: table): LibDataGridFilterBoxMixin

---A row of the list: whatever table the caller keeps; columns read it.
---@alias LibDataGridRow table

---One value in a column or a condition. A date is a time in seconds.
---@alias LibDataGridValue number|string|boolean

---A condition's value: one, a list for IN, or the two ends for BETWEEN.
---@alias LibDataGridOperand LibDataGridValue|LibDataGridValue[]|table<LibDataGridValue, boolean>

---@class LibDataGridOperator
---@field id string
---@field token string how filter text writes it
---@field label string how a picker names it
---@field takes? string a value, a list, both ends, or nothing (lib.takes)
---@field types table<string, boolean> the column types that have it
---@field negates? string the operator it is the opposite of
---@field blank? boolean a test of blankness, which sees blank values
---@field test fun(a: LibDataGridValue?, b: LibDataGridOperand?): boolean

---@class LibDataGridChoice
---@field value LibDataGridValue
---@field text string

---@class LibDataGridColumnDef
---@field key string
---@field label? string the name filter text and a header use; the key when not given
---@field type? string lib.types; string when not given
---@field value? fun(row: LibDataGridRow): LibDataGridValue? the row's value; row[key] when not given
---@field text? fun(row: LibDataGridRow): string what a grid's cell shows; the value as text when not given
---@field choices? LibDataGridChoice[]|fun(): LibDataGridChoice[] an enum's choices
---@field caseSensitive? boolean compare a string column's text as it is
---@field mixin? table goes over ColumnMixin

---@class LibDataGridCondition
---@field column string a column's key
---@field op string an operator's id
---@field value? LibDataGridOperand
---@field children? nil

---@class LibDataGridGroup
---@field join string lib.joins
---@field negate? boolean
---@field children LibDataGridNode[]

---@alias LibDataGridNode LibDataGridGroup|LibDataGridCondition

---@class LibDataGridError
---@field code string lib.errors
---@field pos number the first character it is about, from 1
---@field finish number the last
---@field message string in English

---@class LibDataGridSortKey
---@field key string
---@field descending? boolean

---A schema as lib:NewSchema makes it, the caller's mixins included.
---@class LibDataGridSchema: LibDataGridSchemaMixin

---Anything a view tells of its changes (ViewMixin:AddWidget): the library's widgets, or a caller's.
---@class LibDataGridWidget
---@field OnViewChanged fun(self: LibDataGridWidget, event: string)

---A view as schema:NewView makes it, the caller's mixins included.
---@class LibDataGridView: LibDataGridViewMixin

---@class CallbackHandlerRegistry
---@field Fire fun(self: CallbackHandlerRegistry, event: string, ...: table)

---@class CallbackHandler
---@field New fun(self: CallbackHandler, target: table): CallbackHandlerRegistry
