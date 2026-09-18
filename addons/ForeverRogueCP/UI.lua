
local FRCP = _G.ForeverRogueCP
if not FRCP then return end

local function makeFS(parent, template)
  return parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
end

local function colorText(fs, r, g, b)
  fs:SetTextColor(r, g, b)
  return fs
end

local function styleButton(btn, active)
  if active then
    btn.bg:SetTexture(FRCP.MEDIA .. "button_active.tga")
    btn.label:SetTextColor(1,.97,.92)
  else
    btn.bg:SetTexture(FRCP.MEDIA .. "button_normal.tga")
    btn.label:SetTextColor(.88,.91,.97)
  end
end

local function createButton(parent, text, x, y, w, h, onclick)
  local b = CreateFrame("Button", nil, parent)
  b:SetPoint("TOPLEFT", x, y)
  b:SetSize(w, h)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.bg:SetTexture(FRCP.MEDIA .. "button_normal.tga")
  b.label = makeFS(b, "GameFontNormal")
  b.label:SetPoint("CENTER", 0, 0)
  b.label:SetText(text)
  b.label:SetTextColor(.88,.91,.97)
  b:SetScript("OnEnter", function(self)
    if not self.active then
      self.bg:SetTexture(FRCP.MEDIA .. "button_hover.tga")
      self.label:SetTextColor(1,.94,.78)
    end
  end)
  b:SetScript("OnLeave", function(self) styleButton(self, self.active) end)
  b:SetScript("OnClick", onclick)
  return b
end

local function updateCheckVisual(cb)
  cb.tex:SetTexture(FRCP.MEDIA .. (cb:GetChecked() and "checkbox_on.tga" or "checkbox_off.tga"))
end

local function createCheck(parent, text, x, y, getter, setter)
  local cb = CreateFrame("CheckButton", nil, parent)
  cb:SetPoint("TOPLEFT", x, y)
  cb:SetSize(24, 24)
  cb.tex = cb:CreateTexture(nil, "ARTWORK")
  cb.tex:SetAllPoints()
  cb.txt = makeFS(parent)
  cb.txt:SetPoint("LEFT", cb, "RIGHT", 8, 0)
  cb.txt:SetText(text)
  cb.txt:SetTextColor(.88,.91,.97)
  cb.getter = getter
  cb.setter = setter
  cb.Refresh = function(self)
    self:SetChecked(self.getter())
    updateCheckVisual(self)
  end
  cb:SetScript("OnClick", function(self)
    self.setter(self:GetChecked())
    updateCheckVisual(self)
    FRCP:Layout(); FRCP:Update(); if FRCP.SyncOptions then FRCP:SyncOptions() end
  end)
  return cb
end

local function createSlider(parent, label, x, y, minv, maxv, step, getter, setter)
  local wrap = CreateFrame("Frame", nil, parent)
  wrap:SetPoint("TOPLEFT", x, y)
  wrap:SetSize(270, 56)

  wrap.label = colorText(makeFS(wrap), 1,.86,.42)
  wrap.label:SetPoint("TOPLEFT", 0, 0)
  wrap.label:SetText(label)

  wrap.value = colorText(makeFS(wrap), .96,.97,.99)
  wrap.value:SetPoint("TOPRIGHT", 0, 0)

  local hit = CreateFrame("Frame", nil, wrap)
  hit:SetPoint("TOPLEFT", 0, -18)
  hit:SetSize(270, 26)
  hit:EnableMouse(true)
  hit:EnableMouseWheel(true)

  local track = hit:CreateTexture(nil, "BACKGROUND")
  track:SetTexture(FRCP.MEDIA .. "slider_track.tga")
  track:SetPoint("LEFT", 0, 0)
  track:SetPoint("RIGHT", 0, 0)
  track:SetHeight(13)

  local fill = hit:CreateTexture(nil, "BORDER")
  fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  fill:SetPoint("LEFT", 10, 0)
  fill:SetHeight(2)
  fill:SetVertexColor(.36,.84,1,.85)

  local thumb = hit:CreateTexture(nil, "OVERLAY")
  thumb:SetTexture(FRCP.MEDIA .. "slider_thumb.tga")
  thumb:SetSize(20,20)

  local low = colorText(makeFS(wrap, "GameFontHighlightSmall"), .64,.68,.74)
  low:SetPoint("TOPLEFT", 0, -41)
  low:SetText(tostring(minv))

  local high = colorText(makeFS(wrap, "GameFontHighlightSmall"), .64,.68,.74)
  high:SetPoint("TOPRIGHT", 0, -41)
  high:SetText(tostring(maxv))

  local value = getter()
  local dragging = false

  local function clamp(v)
    if v < minv then v = minv elseif v > maxv then v = maxv end
    local steps = math.floor(((v - minv) / step) + .5)
    return minv + steps * step
  end

  local function updateVisual(v)
    v = clamp(v)
    value = v
    local pct = (v - minv) / (maxv - minv)
    local usable = math.max(1, hit:GetWidth() - 20)
    local px = 10 + pct * usable
    thumb:ClearAllPoints()
    thumb:SetPoint("CENTER", hit, "LEFT", px, 0)
    fill:ClearAllPoints()
    fill:SetPoint("LEFT", hit, "LEFT", 10, 0)
    fill:SetWidth(math.max(1, px - 10))
    wrap.value:SetText(step < 1 and string.format("%.2f", v) or string.format("%.0f", v))
  end

  local function commit(v)
    v = clamp(v)
    if v ~= value then
      value = v
      setter(v)
      FRCP:Layout()
      FRCP:Update()
    end
    updateVisual(v)
  end

  local function valueFromCursor()
    local x = GetCursorPosition()
    local scale = hit:GetEffectiveScale() or 1
    x = x / scale
    local left = hit:GetLeft()
    local width = hit:GetWidth()
    if not left or not width or width <= 0 then return value end
    local pct = (x - left - 10) / math.max(1, width - 20)
    if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
    return minv + pct * (maxv - minv)
  end

  hit:SetScript("OnMouseDown", function(_, button)
    if button ~= "LeftButton" then return end
    dragging = true
    commit(valueFromCursor())
  end)
  hit:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      commit(valueFromCursor())
      dragging = false
    end
  end)
  hit:SetScript("OnUpdate", function()
    if dragging then commit(valueFromCursor()) end
  end)
  hit:SetScript("OnMouseWheel", function(_, delta)
    commit(value + (delta > 0 and step or -step))
  end)
  hit:SetScript("OnEnter", function() track:SetVertexColor(1.07,1.07,1.07,1) end)
  hit:SetScript("OnLeave", function() track:SetVertexColor(1,1,1,1) end)

  wrap.Refresh = function(self)
    value = clamp(getter())
    updateVisual(value)
  end

  wrap:SetScript("OnShow", function(self) self:Refresh() end)
  wrap.hit = hit
  return wrap
end

function FRCP:BuildOptions()
  if self.options then return end
  local f = CreateFrame("Frame", "ForeverRogueCPOptions", UIParent)
  self.options = f
  f:SetSize(1020, 820)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetTexture(FRCP.MEDIA .. "panel_neutral.tga")

  local hd = f:CreateTexture(nil, "BORDER")
  hd:SetTexture(FRCP.MEDIA .. "header_neutral.tga")
  hd:SetPoint("TOPLEFT", 34, -18)
  hd:SetPoint("TOPRIGHT", -34, -18)
  hd:SetHeight(86)

  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(FRCP.MEDIA .. "icon.tga")
  icon:SetSize(44, 44)
  icon:SetPoint("TOPLEFT", 42, -30)

  local title = colorText(makeFS(f, "GameFontNormalLarge"), .97,.98,1)
  title:SetPoint("TOPLEFT", 94, -34)
  title:SetText("Forever |cffffd86bCombat Points|r")

  local sub = colorText(makeFS(f, "GameFontHighlightSmall"), .72,.76,.83)
  sub:SetPoint("TOPLEFT", 94, -58)
  sub:SetText("")

  local author = colorText(makeFS(f, "GameFontHighlightSmall"), .82,.86,.92)
  author:SetPoint("TOPRIGHT", -78, -40)
  author:SetText("by 0xgle")

  local close = CreateFrame("Button", nil, f)
  close:SetSize(28,28)
  close:SetPoint("TOPRIGHT", -32, -26)
  close.tex = close:CreateTexture(nil, "BACKGROUND")
  close.tex:SetAllPoints()
  close.tex:SetTexture(FRCP.MEDIA .. "close_normal.tga")
  close:SetScript("OnEnter", function(self) self.tex:SetTexture(FRCP.MEDIA .. "close_hover.tga") end)
  close:SetScript("OnLeave", function(self) self.tex:SetTexture(FRCP.MEDIA .. "close_normal.tga") end)
  close:SetScript("OnClick", function() f:Hide() end)

  local left = CreateFrame("Frame", nil, f)
  left:SetPoint("TOPLEFT", 80, -132)
  left:SetSize(220, 620)

  local right = CreateFrame("Frame", nil, f)
  right:SetPoint("TOPLEFT", 332, -112)
  right:SetSize(620, 650)

  local leftCardTop = CreateFrame("Frame", nil, left)
  leftCardTop:SetPoint("TOPLEFT", 10, -56)
  leftCardTop:SetSize(190, 126)
  leftCardTop.bg = leftCardTop:CreateTexture(nil, "BACKGROUND")
  leftCardTop.bg:SetAllPoints()
  leftCardTop.bg:SetTexture("Interface\Buttons\WHITE8X8")
  leftCardTop.bg:SetVertexColor(.03, .04, .06, .58)
  leftCardTop.edge = leftCardTop:CreateTexture(nil, "BORDER")
  leftCardTop.edge:SetAllPoints()
  leftCardTop.edge:SetTexture("Interface\Buttons\WHITE8X8")
  leftCardTop.edge:SetVertexColor(.85, .75, .45, .08)

  local leftCardBottom = CreateFrame("Frame", nil, left)
  leftCardBottom:SetPoint("TOPLEFT", 10, -290)
  leftCardBottom:SetSize(190, 166)
  leftCardBottom.bg = leftCardBottom:CreateTexture(nil, "BACKGROUND")
  leftCardBottom.bg:SetAllPoints()
  leftCardBottom.bg:SetTexture("Interface\Buttons\WHITE8X8")
  leftCardBottom.bg:SetVertexColor(.03, .04, .06, .58)
  leftCardBottom.edge = leftCardBottom:CreateTexture(nil, "BORDER")
  leftCardBottom.edge:SetAllPoints()
  leftCardBottom.edge:SetTexture("Interface\Buttons\WHITE8X8")
  leftCardBottom.edge:SetVertexColor(.85, .75, .45, .08)

  local st = colorText(makeFS(left), 1,.86,.42)
  st:SetPoint("TOPLEFT", 20, -12)
  st:SetText("STYLE MODES")

  local st2 = colorText(makeFS(left, "GameFontHighlightSmall"), .66,.70,.76)
  st2:SetPoint("TOPLEFT", 28, -38)
  st2:SetWidth(1)
  st2:SetJustifyH("LEFT")
  st2:SetText("")

  self.modeButtons = {}
  self.modeButtons.WOW = createButton(left, "WoW Fantasy", 17, -74, 176, 40, function() FRCP:SetStyleMode("WOW", true) end)
  self.modeButtons.FUTURE = createButton(left, "Neo Minimal", 17, -122, 176, 40, function() FRCP:SetStyleMode("FUTURE", true) end)

  local desc = colorText(makeFS(left, "GameFontHighlightSmall"), .78,.81,.87)
  desc:SetPoint("TOPLEFT", 28, -156)
  desc:SetWidth(1)
  desc:SetJustifyH("LEFT")
  desc:SetText("")

  local qa = colorText(makeFS(left), 1,.86,.42)
  qa:SetPoint("TOPLEFT", 20, -246)
  qa:SetText("QUICK ACTIONS")
  self.btnUnlock = createButton(left, "Unlock HUD", 17, -286, 176, 38, function() FRCP:SetLocked(false); f:Hide() end)
  self.btnLock = createButton(left, "Lock HUD", 17, -334, 176, 38, function() FRCP:SetLocked(true); FRCP:SyncOptions() end)
  self.btnReset = createButton(left, "Reset", 17, -382, 176, 38, function() FRCP:Reset() end)

  local foot = colorText(makeFS(left, "GameFontHighlightSmall"), .60,.64,.70)
  foot:SetPoint("BOTTOMLEFT", 20, 36)
  foot:SetText("0xgle")

  local sec1 = colorText(makeFS(right), 1,.86,.42)
  sec1:SetPoint("TOPLEFT", 0, -4)
  sec1:SetText("THEME")

  self.themeButtons = {}
  local themes = {
    {"GOLD","Shadow Gold"}, {"CRIMSON","Crimson Edge"}, {"POISON","Deadly Poison"},
    {"ARCANE","Void Violet"}, {"ICE","Cold Steel"}, {"MONO","Clean Mono"},
  }
  for i, v in ipairs(themes) do
    local col = (i-1)%3
    local row = math.floor((i-1)/3)
    self.themeButtons[v[1]] = createButton(right, v[2], 0 + col*206, -30 - row*50, 190, 40, function()
      FRCP.db.theme = v[1]; FRCP:ApplyTheme(); FRCP:Update(); FRCP:SyncOptions()
    end)
  end

  local sec2 = colorText(makeFS(right), 1,.86,.42)
  sec2:SetPoint("TOPLEFT", 0, -140)
  sec2:SetText("GEOMETRY")

  self.sliders = {}
  self.sliders.width = createSlider(right, "Width", 0, -168, 190, 360, 1, function() return FRCP.db.width end, function(v) FRCP.db.width = v end)
  self.sliders.height = createSlider(right, "Height", 320, -168, 22, 52, 1, function() return FRCP.db.height end, function(v) FRCP.db.height = v end)
  self.sliders.gap = createSlider(right, "Point spacing", 0, -244, 0, 18, 1, function() return FRCP.db.gap end, function(v) FRCP.db.gap = v end)
  self.sliders.scale = createSlider(right, "Scale", 320, -244, .70, 1.80, .05, function() return FRCP.db.scale end, function(v) FRCP.db.scale = v end)

  local presetLabel = colorText(makeFS(right), 1,.86,.42)
  presetLabel:SetPoint("TOPLEFT", 0, -308)
  presetLabel:SetText("QUICK PRESETS")
  self.presetButtons = {}
  self.presetButtons.DEFAULT = createButton(right, "Style Default", 0, -332, 190, 36, function() FRCP:ApplyPreset("DEFAULT") end)
  self.presetButtons.COMPACT = createButton(right, "Compact", 206, -332, 190, 36, function() FRCP:ApplyPreset("COMPACT") end)
  self.presetButtons.CINEMATIC = createButton(right, "Cinematic", 412, -332, 190, 36, function() FRCP:ApplyPreset("CINEMATIC") end)

  local orientLabel = colorText(makeFS(right), 1,.86,.42)
  orientLabel:SetPoint("TOPLEFT", 0, -378)
  orientLabel:SetText("ORIENTATION")
  self.orientButtons = {}
  self.orientButtons.HORIZONTAL = createButton(right, "Horizontal", 0, -402, 190, 36, function() FRCP.db.orientation = "HORIZONTAL"; FRCP:Layout(); FRCP:Update(); FRCP:SyncOptions() end)
  self.orientButtons.VERTICAL = createButton(right, "Vertical", 206, -402, 190, 36, function() FRCP.db.orientation = "VERTICAL"; FRCP:Layout(); FRCP:Update(); FRCP:SyncOptions() end)

  local sec3 = colorText(makeFS(right), 1,.86,.42)
  sec3:SetPoint("TOPLEFT", 0, -448)
  sec3:SetText("DISPLAY OPTIONS")

  self.checks = {}
  self.checks.glow = createCheck(right, "Glow effect", 0, -476, function() return FRCP.db.glow end, function(v) FRCP.db.glow = v end)
  self.checks.backdrop = createCheck(right, "Show frame / line", 0, -504, function() return FRCP.db.backdrop end, function(v) FRCP.db.backdrop = v end)
  self.checks.header = createCheck(right, "Show HUD label", 0, -532, function() return FRCP.db.header end, function(v) FRCP.db.header = v end)
  self.checks.smooth = createCheck(right, "Native smooth fill", 0, -560, function() return FRCP.db.smooth end, function(v) FRCP.db.smooth = v end)

  self.checks.target = createCheck(right, "Hide without target", 320, -476, function() return not FRCP.db.showWithoutTarget end, function(v) FRCP.db.showWithoutTarget = not v end)
  self.checks.combat = createCheck(right, "Hide out of combat", 320, -504, function() return not FRCP.db.showOutOfCombat end, function(v) FRCP.db.showOutOfCombat = not v end)
  self.checks.vehicle = createCheck(right, "Hide in vehicle", 320, -532, function() return FRCP.db.hideInVehicle end, function(v) FRCP.db.hideInVehicle = v end)
  self.checks.pulse = createCheck(right, "Pulse at maximum", 320, -560, function() return FRCP.db.pulse end, function(v) FRCP.db.pulse = v end)
end

function FRCP:SyncOptions()
  if not self.options then return end
  for k, b in pairs(self.modeButtons or {}) do
    b.active = (self.db.styleMode == k)
    styleButton(b, b.active)
  end
  for k, b in pairs(self.themeButtons or {}) do
    b.active = (self.db.theme == k)
    styleButton(b, b.active)
  end
  for k, b in pairs(self.orientButtons or {}) do
    b.active = (self.db.orientation == k)
    styleButton(b, b.active)
  end
  for _, s in pairs(self.sliders or {}) do if s.Refresh then s:Refresh() end end
  for _, c in pairs(self.checks or {}) do if c.Refresh then c:Refresh() end end
  for _, b in pairs(self.presetButtons or {}) do b.active = false; styleButton(b, false) end
end

function FRCP:ToggleOptions()
  if not self.options then self:BuildOptions() end
  if self.options:IsShown() then self.options:Hide() else self:SyncOptions(); self.options:Show() end
end
