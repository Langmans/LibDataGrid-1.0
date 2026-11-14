-- How the widgets look: every widget asks its skin, so an addon with its own look (ElvUI, say)
-- passes a skin made from this one with the methods it changes. This one draws plain: a dark
-- backdrop for panels, a dark back for fields, and the Blizzard templates' own fonts and buttons.
--
--   local skin = CreateFromMixins(DG.SkinMixin, { Field = function(self, frame) E:SetTemplate(frame) end })

local lib = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
if not lib.pending then return end

local WHITE = "Interface\\Buttons\\WHITE8X8"
local BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local PANEL =
    { bgFile = WHITE, edgeFile = BORDER, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }

---@class LibDataGridSkinMixin
local SkinMixin = {}
lib.SkinMixin = SkinMixin

---A panel or dialog: a frame made with BackdropTemplate.
---@param frame Frame
function SkinMixin:Backdrop(frame)
    local panel = frame --[[@as BackdropTemplate]]
    panel:SetBackdrop(PANEL)
    panel:SetBackdropColor(0, 0, 0, 0.95)
    panel:SetBackdropBorderColor(0.4, 0.4, 0.4)
end

---A field: a picker chip or a box that holds a value.
---@param frame Frame
function SkinMixin:Field(frame)
    local back = frame:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(1, 1, 1, 0.08)
end

-- Each kind of piece of filter text in its colour, as a colour code takes it (alpha, red, green,
-- blue). All keep WCAG AA or better on the dark edit box.
local K = lib.tokenKinds
local TOKEN_COLOURS = {
    [K.column] = "ffffd100",
    [K.operator] = "ff80c0ff",
    [K.keyword] = "ffff8040",
    [K.value] = "ffffffff",
    [K.bracket] = "ffa0a0a0",
    [K.error] = "ffff4040",
}

---The colour of a kind of piece of filter text (lib.tokenKinds), as a colour code takes it.
---@param kind string
---@return string
function SkinMixin:TokenColour(kind)
    return TOKEN_COLOURS[kind]
end

---Filter text with colour codes, each piece in its kind's colour, for an edit box to show (not for
---parsing). An edit box shows || as two bars rather than one, and a colour code next to a bar goes
---wrong, so a piece with a | in it stays as it is, uncoloured, and so does a piece right against it.
---@param schema LibDataGridSchema
---@param text string
---@return string
function SkinMixin:Highlight(schema, text)
    local parts, at, afterBar = {}, 1, false
    for _, token in ipairs((schema:Tokens(text))) do
        local gap, piece = text:sub(at, token.start - 1), text:sub(token.start, token.finish)
        parts[#parts + 1] = gap
        local plain = piece:find("|", 1, true) ~= nil or (afterBar and gap == "")
        parts[#parts + 1] = plain and piece or ("|c" .. self:TokenColour(token.kind) .. piece .. "|r")
        afterBar = plain and piece:sub(-1) == "|"
        at = token.finish + 1
    end
    parts[#parts + 1] = text:sub(at)
    return table.concat(parts)
end

---The back of every other row in a grid. On the dark backdrop, text over it keeps WCAG AAA (7:1)
---in white (16.6:1), gold (11.3:1) and green (12.1:1); red keeps AA (5.1:1).
---@param texture Texture
function SkinMixin:Stripe(texture)
    texture:SetColorTexture(1, 1, 1, 0.12)
end

---A label's font; the widgets make labels with GameFontHighlightSmall.
---@param fontString FontString
function SkinMixin:Font(fontString) end

---A button made with UIPanelButtonTemplate.
---@param button Button
function SkinMixin:Button(button) end

---An edit box made with InputBoxTemplate.
---@param box EditBox
function SkinMixin:EditBox(box) end
