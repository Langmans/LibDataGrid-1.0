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

---The back of every other row in a grid. On the dark backdrop, text over it keeps WCAG AAA (7:1)
---in white (12.6:1), gold (8.7:1) and green (9.2:1); red falls to 3.9:1.
---@param texture Texture
function SkinMixin:Stripe(texture)
    texture:SetColorTexture(1, 1, 1, 0.2)
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
