-- Frames for the widget specs: layout calls do nothing, a frame keeps its scripts, text, size,
-- points, colours and shown state, an edit box its focus, cursor and highlight. Any method the
-- mock does not define (a capitalised key) is a no-op; a lowercase key is a field and reads nil
-- until set, as on a real frame. Install() puts CreateFrame and the rest in the globals.

local M = {}

local function noop() end

local Region = {}
Region.__index = function(_, key)
    if Region[key] then return Region[key] end
    if type(key) == "string" and key:match("^%u") then return noop end
end

---@return table
local function newRegion(fields)
    fields = fields or {}
    fields.shown = fields.shown ~= false
    fields.scripts, fields.points, fields.children = {}, {}, {}
    if fields.parent then table.insert(fields.parent.children, fields) end
    return setmetatable(fields, Region)
end

function Region:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Region:Hide()
    local was = self.shown
    self.shown = false
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Region:IsShown()
    return self.shown
end
function Region:SetShown(shown)
    if shown then
        self:Show()
    else
        self:Hide()
    end
end
function Region:SetScript(script, handler)
    self.scripts[script] = handler
end
function Region:GetScript(script)
    return self.scripts[script]
end
function Region:HookScript(script, handler)
    local old = self.scripts[script]
    self.scripts[script] = function(...)
        if old then old(...) end
        handler(...)
    end
end
function Region:GetParent()
    return self.parent
end
function Region:GetName()
    return self.name
end
function Region:SetText(text)
    self.text = text
end
function Region:GetText()
    return self.text or ""
end
function Region:SetFormattedText(format, ...)
    self.text = format:format(...)
end
function Region:SetWidth(width)
    self.width = width
end
function Region:SetHeight(height)
    self.height = height
end
function Region:SetSize(width, height)
    self.width, self.height = width, height
end
function Region:GetWidth()
    return self.width or 0
end
function Region:GetHeight()
    return self.height or 0
end
function Region:SetPoint(...)
    self.points[#self.points + 1] = { ... }
end
function Region:ClearAllPoints()
    self.points = {}
end
function Region:GetPoint(index)
    return unpack(self.points[index or 1] or {})
end
function Region:SetTextColor(r, g, b)
    self.textColor = { r, g, b }
end
function Region:SetTexture(texture)
    self.texture = texture
end
function Region:SetColorTexture(r, g, b, a)
    self.color = { r, g, b, a }
end
function Region:SetTexCoord(...)
    self.texCoord = { ... }
end
function Region:SetBackdrop(backdrop)
    self.backdrop = backdrop
end
function Region:SetValue(value)
    self.value = value
end
function Region:GetValue()
    return self.value or 0
end
function Region:SetMinMaxValues(low, high)
    self.min, self.max = low, high
end
function Region:CreateTexture()
    return newRegion({ parent = self })
end
function Region:CreateFontString()
    return newRegion({ parent = self })
end
function Region:Enable()
    self.disabled = false
end
function Region:Disable()
    self.disabled = true
end
function Region:IsEnabled()
    return not self.disabled
end

-- An edit box: focus, the cursor and the highlighted range, as the client counts them (from 0).
function Region:SetFocus()
    self.focus = true
end
function Region:ClearFocus()
    self.focus = false
end
function Region:HasFocus()
    return self.focus == true
end
function Region:SetCursorPosition(position)
    self.cursor = position
end
function Region:HighlightText(start, stop)
    self.highlight = { start, stop }
end

---Runs a frame's script as the client would.
---@param frame table
---@param script string
function M.Fire(frame, script, ...)
    local handler = frame.scripts[script]
    if handler then handler(frame, ...) end
end

---A left click (or the button given) on a frame.
function M.Click(frame, button)
    M.Fire(frame, "OnClick", button or "LeftButton")
end

---Types text into an edit box as the user would: the text, then OnTextChanged from user input.
function M.Type(box, text)
    box:SetText(text)
    M.Fire(box, "OnTextChanged", true)
end

---Every frame under `frame` (itself included) for which `match(frame)` holds, in creation order.
---@return table[]
function M.Find(frame, match, found)
    found = found or {}
    if match(frame) then found[#found + 1] = frame end
    for _, child in ipairs(frame.children) do
        M.Find(child, match, found)
    end
    return found
end

---Every shown frame under `frame` whose text is `text`.
function M.WithText(frame, text)
    return M.Find(frame, function(f)
        return f.text == text and f.shown
    end)
end

---Clicks the shown text `text` under `frame`, as the user does: on the nearest frame around it
---that takes clicks. Fails when there is no such text, or more than one.
function M.ClickText(frame, text, button)
    local found = M.WithText(frame, text)
    assert(#found == 1, ("%d shown texts %q"):format(#found, text))
    local target = found[1]
    while not target.scripts.OnClick do
        target = assert(target.parent, "no clickable frame around " .. text)
    end
    M.Click(target, button)
end

---Puts the frame API in the globals, fresh. IsControlKeyDown reads M.ctrl.
function M.Install()
    M.ctrl = false
    UIParent = newRegion()
    UISpecialFrames = {}
    function CreateFrame(kind, name, parent, template)
        local frame = newRegion({ kind = kind, name = name, parent = parent or UIParent, template = template })
        if name then _G[name] = frame end
        return frame
    end
    function IsControlKeyDown()
        return M.ctrl
    end
end

return M
