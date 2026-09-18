local ADDON = ...
local FRCP = CreateFrame("Frame")
_G.ForeverRogueCP = FRCP

FRCP.VERSION = "1.0.0"
FRCP.MEDIA = "Interface\\AddOns\\ForeverRogueCP\\Media\\"

local defaults = {
  x = 0, y = -145, scale = 1, locked = true,
  width = 244, height = 32, gap = 6, alpha = 1,
  orientation = "HORIZONTAL",
  showOutOfCombat = true, showWithoutTarget = true, hideInVehicle = true,
  theme = "GOLD", styleMode = "WOW", glow = false, backdrop = true, header = false,
  smooth = true, pulse = true, pulseSpeed = 4.2,
  migration = 0,
}
FRCP.defaults = defaults

local function mergeDefaults(src, dst)
  dst = dst or {}
  for k,v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      mergeDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

local function secret(v)
  return issecretvalue and issecretvalue(v) or false
end

FRCP.IsSecret = secret
local POWER = (Enum and Enum.PowerType) or {}
FRCP.powerType = POWER.ComboPoints or 4
FRCP.maxPoints = 5
FRCP.points = {}

FRCP.themes = {
  GOLD    = {fill={1.00,.76,.18}, glow={1.00,.84,.32}, empty={.14,.15,.18}},
  CRIMSON = {fill={1.00,.18,.15}, glow={1.00,.34,.30}, empty={.14,.07,.07}},
  POISON  = {fill={.38,1.00,.18}, glow={.58,1.00,.32}, empty={.08,.13,.09}},
  ARCANE  = {fill={.55,.36,1.00}, glow={.70,.49,1.00}, empty={.10,.08,.15}},
  ICE     = {fill={.58,.88,1.00}, glow={.75,.95,1.00}, empty={.08,.11,.14}},
  MONO    = {fill={.94,.95,.98}, glow={1.00,1.00,1.00}, empty={.11,.12,.14}},
}

FRCP.styles = {
  WOW = {
    track = "wow_track.tga",
    capL = "wow_cap_left.tga",
    capR = "wow_cap_right.tga",
    pointEmpty = "wow_point_empty.tga",
    pointFill = "wow_point_fill.tga",
    pointGloss = "wow_point_gloss.tga",
    pointGlow = "wow_point_glow.tga",
    label = "WoW Fantasy",
    preset = { width = 244, height = 32, gap = 6, backdrop = true, glow = false },
  },
  FUTURE = {
    track = "future_track.tga",
    capL = "future_cap_left.tga",
    capR = "future_cap_right.tga",
    pointEmpty = "future_point_empty.tga",
    pointFill = "future_point_fill.tga",
    pointGloss = "future_point_gloss.tga",
    pointGlow = "future_point_glow.tga",
    label = "Neo Minimal",
    preset = { width = 236, height = 28, gap = 8, backdrop = true, glow = false },
  },
}

local root = CreateFrame("Frame", "ForeverRogueCPFrame", UIParent)
FRCP.root = root
root:SetClampedToScreen(true)
root:SetMovable(true)
root:RegisterForDrag("LeftButton")
root:EnableMouse(false)

local track = root:CreateTexture(nil, "BACKGROUND")
track:SetAllPoints()
local capL = root:CreateTexture(nil, "BORDER")
local capR = root:CreateTexture(nil, "BORDER")
local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("BOTTOM", root, "TOP", 0, 6)
title:SetTextColor(.84,.84,.88)
local hint = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hint:SetPoint("TOP", root, "BOTTOM", 0, -6)
hint:SetTextColor(.68,.72,.78)
hint:SetText("Drag to position  •  /frcp lock")

local function getMax()
  local ok, v = pcall(UnitPowerMax, "player", FRCP.powerType)
  if not ok or v == nil or secret(v) then return FRCP.maxPoints end
  if type(v) == "number" and v > 0 and v <= 10 then return math.floor(v + .5) end
  return FRCP.maxPoints
end

local function getValue()
  local ok, v = pcall(UnitPower, "player", FRCP.powerType)
  if not ok then return nil end
  return v
end

local function interpolation()
  if FRCP.db and FRCP.db.smooth and Enum and Enum.StatusBarInterpolation then
    return Enum.StatusBarInterpolation.ExponentialEaseOut
  end
end

local function ensurePoints(n)
  for i = 1, n do
    if not FRCP.points[i] then
      local shell = CreateFrame("Frame", nil, root)
      local empty = shell:CreateTexture(nil, "BACKGROUND")
      empty:SetAllPoints()
      local bar = CreateFrame("StatusBar", nil, shell)
      bar:SetAllPoints()
      bar:SetOrientation("HORIZONTAL")
      local gloss = shell:CreateTexture(nil, "OVERLAY")
      gloss:SetAllPoints()
      gloss:SetBlendMode("ADD")
      local glow = shell:CreateTexture(nil, "ARTWORK")
      glow:SetPoint("TOPLEFT", -8, 8)
      glow:SetPoint("BOTTOMRIGHT", 8, -8)
      glow:SetBlendMode("ADD")
      FRCP.points[i] = { shell = shell, empty = empty, bar = bar, gloss = gloss, glow = glow }
    end
  end
  for i = n + 1, #FRCP.points do FRCP.points[i].shell:Hide() end
end

function FRCP:SetStyleMode(mode, applyPreset)
  if not self.db then return end
  if not self.styles[mode] then return end
  self.db.styleMode = mode
  if applyPreset then
    local p = self.styles[mode].preset
    self.db.width = p.width
    self.db.height = p.height
    self.db.gap = p.gap
    self.db.backdrop = p.backdrop
    self.db.glow = p.glow
  end
  self:Layout()
  self:Update()
  if self.SyncOptions then self:SyncOptions() end
end

function FRCP:ApplyPreset(kind)
  if not self.db then return end
  if kind == "COMPACT" then
    self.db.width = (self.db.styleMode == "FUTURE") and 220 or 232
    self.db.height = (self.db.styleMode == "FUTURE") and 24 or 28
    self.db.gap = (self.db.styleMode == "FUTURE") and 7 or 5
    self.db.scale = 1
  elseif kind == "CINEMATIC" then
    self.db.width = (self.db.styleMode == "FUTURE") and 266 or 278
    self.db.height = (self.db.styleMode == "FUTURE") and 34 or 38
    self.db.gap = (self.db.styleMode == "FUTURE") and 10 or 8
    self.db.scale = 1
  else
    local p = self.styles[self.db.styleMode or "WOW"].preset
    self.db.width = p.width
    self.db.height = p.height
    self.db.gap = p.gap
  end
  self:Layout()
  self:Update()
  if self.SyncOptions then self:SyncOptions() end
end

function FRCP:ApplyStyle()
  if not self.db then return end
  local style = self.styles[self.db.styleMode or "WOW"] or self.styles.WOW
  if self.db.orientation == "VERTICAL" then
    track:SetTexture("Interface\Buttons\WHITE8X8")
  else
    track:SetTexture(self.MEDIA .. style.track)
  end
  capL:SetTexture(self.MEDIA .. style.capL)
  capR:SetTexture(self.MEDIA .. style.capR)
  title:SetText("Forever Combat Points  •  " .. style.label)
  for _, p in ipairs(self.points) do
    p.empty:SetTexture(self.MEDIA .. style.pointEmpty)
    p.bar:SetStatusBarTexture(self.MEDIA .. style.pointFill)
    p.gloss:SetTexture(self.MEDIA .. style.pointGloss)
    p.glow:SetTexture(self.MEDIA .. style.pointGlow)
  end
  self:ApplyTheme()
end

function FRCP:ApplyTheme()
  if not self.db then return end
  local t = self.themes[self.db.theme] or self.themes.GOLD
  for _, p in ipairs(self.points) do
    p.bar:SetStatusBarColor(t.fill[1], t.fill[2], t.fill[3], 1)
    p.empty:SetVertexColor(t.empty[1], t.empty[2], t.empty[3], 1)
    p.gloss:SetVertexColor(1, 1, 1, .32)
    p.glow:SetVertexColor(t.glow[1], t.glow[2], t.glow[3], .95)
    p.glow:SetShown(self.db.glow)
  end
  if self.db.orientation == "VERTICAL" then
    track:SetVertexColor(t.glow[1], t.glow[2], t.glow[3], .22)
    track:SetShown(self.db.backdrop)
    capL:SetShown(false)
    capR:SetShown(false)
  else
    track:SetVertexColor(1, 1, 1, 1)
    track:SetShown(self.db.backdrop)
    capL:SetShown(self.db.backdrop)
    capR:SetShown(self.db.backdrop)
  end
  title:SetShown(self.db.header)
end

function FRCP:Layout()
  if not self.db then return end
  local n = getMax(); if n < 1 or n > 10 then n = 5 end
  ensurePoints(n)

  local pointSize = self.db.height
  local inner = n * pointSize + self.db.gap * (n - 1)
  local vertical = (self.db.orientation == "VERTICAL")

  local rootW, rootH
  if vertical then
    rootW = pointSize
    rootH = math.max(self.db.width, inner)
  else
    rootW = math.max(self.db.width, inner)
    rootH = pointSize
  end

  root:SetSize(rootW, rootH)
  root:SetScale(self.db.scale)
  if not root._moving then
    root:ClearAllPoints()
    root:SetPoint("CENTER", UIParent, "CENTER", self.db.x, self.db.y)
  end

  local capSize = math.floor(pointSize * 1.10)
  local trackPad = math.floor(pointSize * .34)

  if vertical then
    local startY = math.floor((rootH - inner) / 2)
    local trackBottom = startY + math.floor(pointSize * .20)
    local trackTop = startY + inner - math.floor(pointSize * .20)
    local lineW = math.max(3, math.floor(pointSize * .12))

    track:ClearAllPoints()
    track:SetPoint("BOTTOM", root, "BOTTOM", 0, trackBottom)
    track:SetWidth(lineW)
    track:SetHeight(math.max(1, trackTop - trackBottom))

    capL:SetSize(capSize, capSize)
    capR:SetSize(capSize, capSize)
    capL:ClearAllPoints()
    capR:ClearAllPoints()
    capL:SetPoint("BOTTOM", root, "BOTTOM", 0, trackBottom)
    capR:SetPoint("TOP", root, "BOTTOM", 0, trackTop)
    if capL.SetRotation then capL:SetRotation(0) end
    if capR.SetRotation then capR:SetRotation(0) end

    for i = 1, n do
      local p = self.points[i]
      p.shell:ClearAllPoints()
      p.shell:SetSize(pointSize, pointSize)
      p.shell:SetPoint("BOTTOM", root, "BOTTOM", 0, startY + (i - 1) * (pointSize + self.db.gap))
      p.bar:ClearAllPoints()
      p.bar:SetAllPoints()
      p.bar:SetOrientation("VERTICAL")
      p.shell:Show()
    end
  else
    local startX = math.floor((rootW - inner) / 2)
    local trackLeft = startX - trackPad
    local trackRight = startX + inner + trackPad

    track:ClearAllPoints()
    track:SetPoint("TOPLEFT", root, "TOPLEFT", trackLeft, 0)
    track:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", trackLeft, 0)
    track:SetWidth(trackRight - trackLeft)

    capL:SetSize(capSize, capSize)
    capR:SetSize(capSize, capSize)
    capL:ClearAllPoints()
    capR:ClearAllPoints()
    capL:SetPoint("RIGHT", root, "LEFT", trackLeft + math.floor(capSize * .55), 0)
    capR:SetPoint("LEFT", root, "LEFT", trackRight - math.floor(capSize * .55), 0)
    if capL.SetRotation then capL:SetRotation(0) end
    if capR.SetRotation then capR:SetRotation(0) end

    for i = 1, n do
      local p = self.points[i]
      p.shell:ClearAllPoints()
      p.shell:SetSize(pointSize, pointSize)
      p.shell:SetPoint("LEFT", root, "LEFT", startX + (i - 1) * (pointSize + self.db.gap), 0)
      p.bar:ClearAllPoints()
      p.bar:SetAllPoints()
      p.bar:SetOrientation("HORIZONTAL")
      p.shell:Show()
    end
  end

  self:ApplyStyle()
end

function FRCP:UpdateVisibility()
  if self.db.hideInVehicle and UnitInVehicle and UnitInVehicle("player") then root:Hide(); return end
  if not self.db.showOutOfCombat and not UnitAffectingCombat("player") then root:Hide(); return end
  if not self.db.showWithoutTarget and not UnitExists("target") then root:Hide(); return end
  root:Show()
end

function FRCP:Update()
  if not self.db then return end
  self:UpdateVisibility()
  local n = getMax(); if n < 1 or n > 10 then n = 5 end
  if #self.points < n then self:Layout() end
  local value = getValue()
  local interp = interpolation()
  for i = 1, n do
    local p = self.points[i]
    p.bar:SetMinMaxValues(i - 1, i)
    if value ~= nil then p.bar:SetValue(value, interp) else p.bar:SetValue(0) end
    p.shell:SetAlpha(self.db.alpha)
  end
  if value ~= nil and not secret(value) and self.db.pulse and value >= n then
    root:SetAlpha(.90 + .10 * math.abs(math.sin(GetTime() * self.db.pulseSpeed)))
  else
    root:SetAlpha(1)
  end
end

local function onDragStart()
  if FRCP.db and not FRCP.db.locked then root._moving = true; root:StartMoving() end
end
local function onDragStop()
  if not root._moving then return end
  root:StopMovingOrSizing(); root._moving = false
  local cx, cy = root:GetCenter(); local ux, uy = UIParent:GetCenter()
  if cx and cy and ux and uy and not secret(cx) and not secret(cy) then
    local s = root:GetScale() or 1
    FRCP.db.x = (cx - ux) / s
    FRCP.db.y = (cy - uy) / s
  end
  FRCP:Layout()
end
root:SetScript("OnDragStart", onDragStart)
root:SetScript("OnDragStop", onDragStop)

function FRCP:SetLocked(v)
  self.db.locked = v
  root:EnableMouse(not v)
  hint:SetShown(not v)
end

function FRCP:Reset()
  ForeverRogueCPDB = {}
  self.db = mergeDefaults(defaults, ForeverRogueCPDB)
  self:SetLocked(true)
  self:Layout()
  self:Update()
  if self.SyncOptions then self:SyncOptions() end
end

SLASH_FOREVERROGUECP1 = "/frcp"
SLASH_FOREVERROGUECP2 = "/roguecp"
SlashCmdList.FOREVERROGUECP = function(msg)
  local cmd = (msg or ""):lower():match("^%s*(.-)%s*$")
  if cmd == "unlock" then FRCP:SetLocked(false); print("|cffffd86bForever Combat Points|r: unlocked — drag the HUD.")
  elseif cmd == "lock" then FRCP:SetLocked(true); print("|cffffd86bForever Combat Points|r: locked.")
  elseif cmd == "reset" then FRCP:Reset(); print("|cffffd86bForever Combat Points|r: defaults restored.")
  elseif cmd == "status" then
    local v = getValue()
    print("|cffffd86bForever Combat Points|r v"..FRCP.VERSION.." • combo="..((v~=nil and secret(v)) and "<secret>" or tostring(v)).." • max="..tostring(getMax()).." • style="..(FRCP.db and FRCP.db.styleMode or "?").." • orient="..(FRCP.db and FRCP.db.orientation or "?").." • theme="..(FRCP.db and FRCP.db.theme or "?"))
  else
    if FRCP.ToggleOptions then FRCP:ToggleOptions() else print("Forever Combat Points: /frcp unlock | lock | reset | status") end
  end
end

FRCP:RegisterEvent("ADDON_LOADED")
FRCP:RegisterEvent("PLAYER_ENTERING_WORLD")
FRCP:RegisterEvent("PLAYER_TARGET_CHANGED")
FRCP:RegisterEvent("PLAYER_REGEN_DISABLED")
FRCP:RegisterEvent("PLAYER_REGEN_ENABLED")
FRCP:RegisterEvent("UNIT_POWER_UPDATE")
FRCP:RegisterEvent("UNIT_MAXPOWER")
FRCP:SetScript("OnEvent", function(self, event, a1)
  if event == "ADDON_LOADED" and a1 == ADDON then
    local _, class = UnitClass("player")
    ForeverRogueCPDB = mergeDefaults(defaults, ForeverRogueCPDB or {})
    self.db = ForeverRogueCPDB
    if (self.db.migration or 0) < 191 then
      if self.db.glow == nil then self.db.glow = false end
      if not self.db.orientation then self.db.orientation = "HORIZONTAL" end
      self.db.migration = 191
    end
    self.unsupported = (class ~= "ROGUE")
    self:SetLocked(self.db.locked)
    self:Layout()
    self:Update()
    if self.BuildOptions then self:BuildOptions() end
  elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") then
    if a1 == "player" then self:Update() end
  elseif self.db then
    self:Update()
  end
end)

root:SetScript("OnUpdate", function(_, elapsed)
  root.t = (root.t or 0) + elapsed
  if root.t > .10 then
    root.t = 0
    if FRCP.db and FRCP.db.pulse then FRCP:Update() end
  end
end)
