local addonName = ...
local FC = {}
_G.ForeverChat = FC

FC.name = addonName or "ForeverChat"
FC.version = "0.3.0-beta1"
FC.prefix = "ForeverChat"
FC.initialized = false
FC.initError = nil
FC.historyLimit = 500
FC.pendingMessages = 0
FC.unread = {}
FC.currentTab = "ALL"
FC.peerSeen = {}
FC.duplicateCache = {}

local defaults = {
    schemaVersion = 3,
    shown = true,
    x = 30,
    y = 160,
    width = 1000,
    height = 650,
    scale = 1.0,
    fontSize = 13,
    messageSpacing = 3,
    opacity = 1.0,
    timestamps = true,
    history = {},
    blockedWords = {},
    compact = false,
    showRail = true,
    mentionAlerts = true,
    dangerAlerts = true,
    duplicateFilter = true,
    autoDanger = true,
    theme = "GOLD",
}

local tabs = { "ALL", "GROUP", "GUILD", "WHISPERS", "LFG", "TRADE", "ALERTS" }
local tabLabels = {
    ALL = "ALL",
    GROUP = "GROUP",
    GUILD = "GUILD",
    WHISPERS = "WHISPERS",
    LFG = "LFG RADAR",
    TRADE = "TRADE",
    ALERTS = "ALERTS",
}

local colors = {
    bg = {0.025, 0.035, 0.038, 1},
    panel = {0.035, 0.055, 0.056, 1},
    panel2 = {0.055, 0.080, 0.080, 1},
    border = {0.26, 0.29, 0.25, 1},
    gold = {0.84, 0.68, 0.40, 1},
    teal = {0.22, 0.80, 0.72, 1},
    text = {0.92, 0.94, 0.96, 1},
    muted = {0.56, 0.61, 0.67, 1},
    red = {0.96, 0.30, 0.29, 1},
}

local themeAccents = {
    GOLD = {0.84, 0.68, 0.40, 1},
    AZERITE = {0.24, 0.62, 0.96, 1},
    TEAL = {0.22, 0.80, 0.72, 1},
    BLOOD = {0.92, 0.28, 0.25, 1},
}
local themeOrder = {"GOLD", "AZERITE", "TEAL", "BLOOD"}

local function copyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            copyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function plain(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("|T.-|t", "")
    return text
end

local function lower(text)
    return plain(text):lower()
end

local function solid(parent, layer, color)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return t
end

local function text(parent, size, color, flags)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont(STANDARD_TEXT_FONT, math.max(10, size or 12), "")
    f:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    f:SetJustifyH("LEFT")
    f:SetJustifyV("MIDDLE")
    return f
end

local function border(frame)
    local top = solid(frame, "BORDER", colors.border)
    top:SetPoint("TOPLEFT") top:SetPoint("TOPRIGHT") top:SetHeight(1)
    local bottom = solid(frame, "BORDER", colors.border)
    bottom:SetPoint("BOTTOMLEFT") bottom:SetPoint("BOTTOMRIGHT") bottom:SetHeight(1)
    local left = solid(frame, "BORDER", colors.border)
    left:SetPoint("TOPLEFT") left:SetPoint("BOTTOMLEFT") left:SetWidth(1)
    local right = solid(frame, "BORDER", colors.border)
    right:SetPoint("TOPRIGHT") right:SetPoint("BOTTOMRIGHT") right:SetWidth(1)
end

function FC:Print(msg)
    local frame = DEFAULT_CHAT_FRAME or ChatFrame1
    if frame and frame.AddMessage then
        frame:AddMessage("|cffd9a441ForeverChat|r  " .. tostring(msg))
    end
end

function FC:SafeCall(label, fn)
    local ok, err = xpcall(fn, function(e)
        return tostring(e)
    end)
    if not ok then
        self.initError = label .. ": " .. tostring(err)
        self:Print("|cffff5555ERROR|r " .. self.initError)
        return false
    end
    return true
end

function FC:SafeRegister(event)
    local ok = pcall(self.eventFrame.RegisterEvent, self.eventFrame, event)
    if not ok then
        self:Print("Skipped unsupported event: " .. tostring(event))
    end
end

function FC:ShortName(name)
    name = tostring(name or "")
    return name:match("^([^%-]+)") or name
end

function FC:IsMine(name)
    if not name or name == "" then return false end
    local me = UnitName and UnitName("player") or ""
    return self:ShortName(name) == self:ShortName(me)
end

function FC:FormatTime(ts)
    if date then return date("%H:%M", ts or time()) end
    return "--:--"
end

function FC:FindDungeon(msg)
    local s = lower(msg)
    local patterns = {
        {"deadmines", "DM"}, {" dm ", "DM"}, {" vc ", "DM"},
        {"wailing caverns", "WC"}, {" wc ", "WC"},
        {"shadowfang", "SFK"}, {" sfk ", "SFK"},
        {"blackfathom", "BFD"}, {" bfd ", "BFD"},
        {"stockade", "STOCKS"}, {" stocks ", "STOCKS"},
        {"gnomeregan", "GNOMER"}, {" gnomer ", "GNOMER"},
        {"scarlet monastery", "SM"}, {" sm ", "SM"},
        {"razorfen kraul", "RFK"}, {" rfk ", "RFK"},
        {"razorfen downs", "RFD"}, {" rfd ", "RFD"},
        {"uldaman", "ULDA"}, {" ulda ", "ULDA"},
        {"zul'farrak", "ZF"}, {" zf ", "ZF"},
        {"maraudon", "MARA"}, {" mara ", "MARA"},
        {"sunken temple", "ST"}, {" st ", "ST"},
        {"blackrock depths", "BRD"}, {" brd ", "BRD"},
        {"lower blackrock", "LBRS"}, {" lbrs ", "LBRS"},
        {"upper blackrock", "UBRS"}, {" ubrs ", "UBRS"},
        {"stratholme", "STRAT"}, {" strat ", "STRAT"},
        {"scholomance", "SCHOLO"}, {" scholo ", "SCHOLO"},
        {"dire maul", "DM"}, {" dire maul ", "DM"},
    }
    local padded = " " .. s .. " "
    for _, p in ipairs(patterns) do
        if padded:find(p[1], 1, true) then return p[2] end
    end
    return nil
end

function FC:ParseLFG(msg, channel)
    local s = " " .. lower(msg) .. " "
    local c = lower(channel)
    local action
    if s:find(" lfm ", 1, true) or s:find(" need ", 1, true) then action = "LFM" end
    if s:find(" lfg ", 1, true) or s:find(" looking for group ", 1, true) then action = action or "LFG" end
    if not action and (c:find("lookingforgroup", 1, true) or c:find("looking for group", 1, true)) then action = "LFG" end
    if not action then return false, nil end

    local role
    if s:find(" tank ", 1, true) then role = "TANK" end
    if s:find(" heal", 1, true) or s:find(" healer", 1, true) then role = role and (role .. "+HEAL") or "HEAL" end
    if s:find(" dps ", 1, true) then role = role and (role .. "+DPS") or "DPS" end

    return true, { action = action, role = role, dungeon = self:FindDungeon(msg) }
end

function FC:IsTrade(msg, channel)
    local s = " " .. lower(msg) .. " "
    local c = lower(channel)
    return c:find("trade", 1, true) ~= nil
        or s:find(" wts ", 1, true) ~= nil
        or s:find(" wtb ", 1, true) ~= nil
        or s:find(" selling ", 1, true) ~= nil
        or s:find(" buying ", 1, true) ~= nil
end

function FC:IsDanger(msg)
    local s = " " .. lower(msg) .. " "
    local words = { " danger ", " elite ", " patrol ", " grief", " careful ", " beware ", " son of arugal", " stitches " }
    for _, w in ipairs(words) do
        if s:find(w, 1, true) then return true end
    end
    return false
end

function FC:IsBlocked(sender, msg)
    local hay = lower((sender or "") .. " " .. (msg or ""))
    for _, word in ipairs(self.db.blockedWords or {}) do
        if word ~= "" and hay:find(tostring(word):lower(), 1, true) then return true end
    end
    return false
end

function FC:IsDuplicate(sender, msg)
    if self.db and self.db.duplicateFilter == false then return false end
    if not sender or sender == "" or not msg then return false end
    local key = tostring(sender) .. "\031" .. plain(msg)
    local now = GetTime and GetTime() or 0
    local last = self.duplicateCache[key]
    self.duplicateCache[key] = now
    if not self.cacheCleaned or now - self.cacheCleaned > 30 then
        for k, t in pairs(self.duplicateCache) do if now - t > 10 then self.duplicateCache[k] = nil end end
        self.cacheCleaned = now
    end
    return last and (now - last) < 4
end

function FC:AddRecord(r)
    if not self.db then return end
    if self:IsBlocked(r.sender, r.msg) or self:IsDuplicate(r.sender, r.msg) then return end
    r.t = r.t or time()
    table.insert(self.db.history, r)
    while #self.db.history > self.historyLimit do table.remove(self.db.history, 1) end

    for _, tab in ipairs(tabs) do
        if (tab ~= self.currentTab or not self.frame or not self.frame:IsShown()) and self:MatchesTab(r, tab) then
            self.unread[tab] = (self.unread[tab] or 0) + 1
        end
    end

    if self.initialized then
        if self.paused and self:MatchesTab(r, self.currentTab) and self:MatchesSearch(r, self:GetSearch()) then
            self.pendingMessages = (self.pendingMessages or 0) + 1
        end
        self:Render(false)
        self:UpdateRail()
        local showMention = r.isMention and self.db.mentionAlerts ~= false
        local showDanger = r.isNetwork and not r.isLocal and self.db.dangerAlerts ~= false
        if showMention or showDanger then self:ShowToast(r) end
    end
end

function FC:MatchesTab(r, tab)
    if tab == "ALL" then return true end
    if tab == "GROUP" then return r.isGroup end
    if tab == "GUILD" then return r.isGuild end
    if tab == "WHISPERS" then return r.isWhisper end
    if tab == "LFG" then return r.isLFG end
    if tab == "TRADE" then return r.isTrade end
    if tab == "ALERTS" then return r.isDanger or r.isMention or r.isNetwork end
    return false
end

function FC:GetSearch()
    if not self.search then return "" end
    return lower(self.search:GetText() or "")
end

function FC:MatchesSearch(r, query)
    if query == "" then return true end
    local hay = lower((r.sender or "") .. " " .. (r.channel or "") .. " " .. (r.msg or "") .. " " .. (r.zone or ""))
    return hay:find(query, 1, true) ~= nil
end

function FC:FormatRecord(r)
    local parts = {}
    if self.db.timestamps then table.insert(parts, "|cff6f7b87[" .. self:FormatTime(r.t) .. "]|r") end

    local label = r.label or "CHAT"
    if r.isLFG and r.lfg then
        label = r.lfg.action or "LFG"
        if r.lfg.dungeon then label = label .. " " .. r.lfg.dungeon end
        if r.lfg.role then label = label .. " " .. r.lfg.role end
    elseif r.isNetwork then
        label = "DANGER " .. (r.zone or "WORLD")
    elseif r.event == "CHAT_MSG_CHANNEL" and r.channel and r.channel ~= "" then
        label = r.channel
    end

    local labelColor = r.isDanger and "f34d4b" or (r.isLFG and "39cdb9" or "8f9ba8")
    table.insert(parts, "|cff" .. labelColor .. "[" .. plain(label) .. "]|r")

    if r.sender and r.sender ~= "" then
        local who = self:ShortName(r.sender)
        table.insert(parts, "|Hplayer:" .. r.sender .. "|h|cffd9a441[" .. who .. "]|r|h:")
    end

    local body = tostring(r.msg or "")
    if r.isDanger then body = "|cffff7775" .. body .. "|r" end
    if r.isMention then body = "|cffffd36a" .. body .. "|r" end
    table.insert(parts, body)
    return table.concat(parts, " ")
end

function FC:SetTab(tab)
    self.currentTab = tab
    self.unread[tab] = 0
    self:Render(true)
end

function FC:UpdateTabs()
    if not self.tabButtons then return end
    for _, tab in ipairs(tabs) do
        local b = self.tabButtons[tab]
        if b then
            local n = self.unread[tab] or 0
            local caption = tabLabels[tab]
            if b.badge then b.badge:SetText(n > 0 and tostring(math.min(n, 99)) or "") end
            b.label:SetText(caption)
            if tab == self.currentTab then
                local c = self:GetAccent()
                b.label:SetTextColor(colors.text[1], colors.text[2], colors.text[3])
                b.line:Show()
                if b.activeBg then b.activeBg:Show() end
            else
                b.label:SetTextColor(colors.muted[1], colors.muted[2], colors.muted[3])
                b.line:Hide()
                if b.activeBg then b.activeBg:Hide() end
            end
        end
    end
end

function FC:Render(force)
    if not self.messages or not self.db then return end
    if not force and self.frame and not self.frame:IsShown() then return end
    if self.paused and not force then
        self:UpdateTabs()
        self:UpdateStatus()
        self:UpdateJump()
        return
    end
    self.paused = false
    self.pendingMessages = 0
    self.messages:Clear()
    local query = self:GetSearch()
    local shown = 0
    local history = self.db.history
    local first = 1
    for i = first, #history do
        local r = history[i]
        if self:MatchesTab(r, self.currentTab) and self:MatchesSearch(r, query) then
            self.messages:AddMessage(self:FormatRecord(r), colors.text[1], colors.text[2], colors.text[3])
            shown = shown + 1
        end
    end
    if shown == 0 then self.messages:AddMessage("|cff8f9ba8No messages in this view yet.|r") end
    if self.messages.ScrollToBottom then self.messages:ScrollToBottom() end
    self:UpdateTabs()
    self:UpdateStatus()
    self:UpdateJump()
end

function FC:UpdateStatus()
    if not self.status or not self.db then return end
    local peers = 0
    local now = time()
    for _, t in pairs(self.peerSeen) do if now - t < 300 then peers = peers + 1 end end
    self.status:SetText((self.paused and "HISTORY" or "LIVE") .. "  /  " .. #self.db.history .. " messages  /  " .. peers .. " peers")
end

function FC:UpdateRail()
    if not self.whisperRows or not self.db then return end
    local seen, list = {}, {}
    for i = #self.db.history, 1, -1 do
        local r = self.db.history[i]
        if r.isWhisper and r.sender and r.sender ~= "" then
            local key = r.sender
            if not seen[key] then
                seen[key] = true
                table.insert(list, r)
                if #list >= 2 then break end
            end
        end
    end
    for i, row in ipairs(self.whisperRows) do
        local r = list[i]
        if r then
            row.sender = r.sender
            row.title:SetText(self:ShortName(r.sender))
            local snip = plain(r.msg or "")
            
            row.sub:SetText(snip)
            row.tooltipText = plain(r.msg or "")
        else
            row.sender = nil
            row.tooltipText = nil
            row.title:SetText(i == 1 and "No whispers yet" or "")
            row.sub:SetText(i == 1 and "Recent conversations appear here" or "")
        end
    end

    local lfg, lfgSeen = {}, {}
    for i = #self.db.history, 1, -1 do
        local r = self.db.history[i]
        if r.isLFG and r.sender and not lfgSeen[r.sender] and time() - (r.t or 0) < 900 then
            lfgSeen[r.sender] = true
            table.insert(lfg, r)
            if #lfg >= 3 then break end
        end
    end
    for i, row in ipairs(self.lfgRows) do
        local r = lfg[i]
        if r then
            row.sender = r.sender
            local meta = r.lfg and (r.lfg.action or "LFG") or "LFG"
            if r.lfg and r.lfg.dungeon then meta = meta .. "  " .. r.lfg.dungeon end
            if r.lfg and r.lfg.role then meta = meta .. "  " .. r.lfg.role end
            row.title:SetText(meta)
            local snip = self:ShortName(r.sender) .. " - " .. plain(r.msg or "")
            
            row.sub:SetText(snip)
            row.tooltipText = plain(r.msg or "")
        else
            row.sender = nil
            row.tooltipText = nil
            row.title:SetText(i == 1 and "LISTENING..." or "")
            row.sub:SetText(i == 1 and "LFG/LFM posts appear here" or "")
        end
    end
end

function FC:OpenChat(prefix)
    prefix = prefix or ""
    if ChatFrame_OpenChat then
        ChatFrame_OpenChat(prefix, DEFAULT_CHAT_FRAME or ChatFrame1)
    elseif ChatFrame1EditBox then
        ChatFrame1EditBox:Show()
        ChatFrame1EditBox:SetText(prefix)
        ChatFrame1EditBox:SetFocus()
    end
end

function FC:ShowToast(r)
    if not self.toast then return end
    self.toastTitle:SetText(r.isNetwork and "HARDCORE DANGER" or "MENTION")
    local body = plain(r.msg or "")
    if #body > 70 then body = body:sub(1, 67) .. "..." end
    self.toastBody:SetText(body)
    self.toast:Show()
    self.toastSerial = (self.toastSerial or 0) + 1
    local serial = self.toastSerial
    if C_Timer and C_Timer.After then
        C_Timer.After(6, function()
            if FC.toastSerial == serial and FC.toast then FC.toast:Hide() end
        end)
    end
end

function FC:GetAccent()
    return themeAccents[(self.db and self.db.theme) or "GOLD"] or themeAccents.GOLD
end

function FC:RegisterAccentTexture(texture)
    self.accentTextures = self.accentTextures or {}
    table.insert(self.accentTextures, texture)
    local c = self:GetAccent()
    texture:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    return texture
end

function FC:RegisterAccentFont(fontString)
    self.accentFonts = self.accentFonts or {}
    table.insert(self.accentFonts, fontString)
    local c = self:GetAccent()
    fontString:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    return fontString
end

function FC:ApplyTheme()
    local c = self:GetAccent()
    for _, t in ipairs(self.accentTextures or {}) do
        if t and t.SetColorTexture then t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end
    end
    for _, f in ipairs(self.accentFonts or {}) do
        if f and f.SetTextColor then f:SetTextColor(c[1], c[2], c[3], c[4] or 1) end
    end
    self:UpdateTabs()
end

function FC:ApplyAppearance()
    if not self.db then return end
    if self.frame then
        self:FitScale()
        if self.backdrop then self.backdrop:SetAlpha(self.db.opacity or 1) end
    end
    if self.messages then
        self.messages:SetFont(STANDARD_TEXT_FONT, self.db.fontSize or 13, "")
        self.messages:SetSpacing(self.db.messageSpacing or 3)
    end
    if self.rail then
        if self.db.compact or self.db.showRail == false then self.rail:Hide() else self.rail:Show() end
    end
    self:LayoutMessages()
    self:ApplyTheme()
    self:Render(true)
end

function FC:Tooltip(owner, title, body)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(title or "ForeverChat", 1, 1, 1)
    if body and body ~= "" then GameTooltip:AddLine(body, 0.72, 0.76, 0.82, true) end
    GameTooltip:Show()
end

function FC:MakeButton(parent, label, width, height, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 90, height or 26)
    b.bg = solid(b, "BACKGROUND", colors.panel2)
    b.bg:SetAllPoints()
    border(b)
    b.label = text(b, 9, colors.text, "OUTLINE")
    b.label:SetPoint("CENTER")
    b.label:SetText(label or "BUTTON")
    b:SetScript("OnEnter", function(self)
        local c = FC:GetAccent()
        self.bg:SetColorTexture(c[1] * 0.20, c[2] * 0.20, c[3] * 0.20, 1)
    end)
    b:SetScript("OnLeave", function(self) self.bg:SetColorTexture(colors.panel2[1], colors.panel2[2], colors.panel2[3], colors.panel2[4]) end)
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

function FC:BuildSettingToggle(parent, y, label, description, key, callback)
    local row = CreateFrame("Button", nil, parent)
    row:SetPoint("TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", 0, y)
    row:SetHeight(52)
    local rbg = solid(row, "BACKGROUND", {0.055,0.066,0.078,0.72})
    rbg:SetAllPoints()
    local title = text(row, 11, colors.text)
    title:SetPoint("TOPLEFT", 12, -9)
    title:SetText(label)
    local desc = text(row, 8, colors.muted)
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetWidth(326)
    desc:SetHeight(24)
    desc:SetJustifyV("TOP")
    desc:SetText(description or "")
    local state = text(row, 9, colors.muted, "OUTLINE")
    state:SetPoint("RIGHT", -13, 0)
    local pill = solid(row, "ARTWORK", colors.border)
    pill:SetSize(42, 20)
    pill:SetPoint("RIGHT", -9, 0)
    state:SetParent(row)
    state:ClearAllPoints()
    state:SetPoint("CENTER", pill, "CENTER", 0, 0)
    local function refresh()
        local on = FC.db[key] ~= false
        local c = FC:GetAccent()
        if on then
            pill:SetColorTexture(c[1] * 0.45, c[2] * 0.45, c[3] * 0.45, 1)
            state:SetText("ON")
            state:SetTextColor(1,1,1,1)
        else
            pill:SetColorTexture(0.12,0.13,0.15,1)
            state:SetText("OFF")
            state:SetTextColor(colors.muted[1],colors.muted[2],colors.muted[3],1)
        end
    end
    row:SetScript("OnShow", refresh)
    row:SetScript("OnClick", function()
        FC.db[key] = not (FC.db[key] ~= false)
        refresh()
        if callback then callback() end
    end)
    row:SetScript("OnEnter", function() rbg:SetColorTexture(0.075,0.087,0.10,0.95) end)
    row:SetScript("OnLeave", function() rbg:SetColorTexture(0.055,0.066,0.078,0.72) end)
    refresh()
    return row
end

function FC:BuildSettingStepper(parent, y, label, description, key, minValue, maxValue, step, formatter, callback)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", 0, y)
    row:SetHeight(58)
    local rbg = solid(row, "BACKGROUND", {0.055,0.066,0.078,0.72})
    rbg:SetAllPoints()
    local title = text(row, 11, colors.text)
    title:SetPoint("TOPLEFT", 12, -9)
    title:SetText(label)
    local desc = text(row, 8, colors.muted)
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetWidth(286)
    desc:SetHeight(24)
    desc:SetJustifyV("TOP")
    desc:SetText(description or "")
    local value = text(row, 10, colors.text, "OUTLINE")
    value:SetWidth(54)
    value:SetJustifyH("CENTER")
    value:SetPoint("RIGHT", -42, 0)
    local minus = FC:MakeButton(row, "-", 28, 26)
    minus:SetPoint("RIGHT", value, "LEFT", -3, 0)
    local plus = FC:MakeButton(row, "+", 28, 26)
    plus:SetPoint("LEFT", value, "RIGHT", 3, 0)
    local function refresh()
        local v = tonumber(FC.db[key]) or minValue
        value:SetText(formatter and formatter(v) or tostring(v))
    end
    row:SetScript("OnShow", refresh)
    minus:SetScript("OnClick", function()
        local v = math.max(minValue, (tonumber(FC.db[key]) or minValue) - step)
        FC.db[key] = math.floor(v * 100 + 0.5) / 100
        refresh()
        if callback then callback() end
    end)
    plus:SetScript("OnClick", function()
        local v = math.min(maxValue, (tonumber(FC.db[key]) or minValue) + step)
        FC.db[key] = math.floor(v * 100 + 0.5) / 100
        refresh()
        if callback then callback() end
    end)
    refresh()
    return row
end

function FC:BuildSettings(parent)
    local panel = CreateFrame("Frame", nil, parent)
    self.settingsPanel = panel
    panel:SetPoint("TOPLEFT", 1, -90)
    panel:SetPoint("BOTTOMRIGHT", -1, 1)
    local pbg = solid(panel, "BACKGROUND", colors.bg)
    pbg:SetAllPoints()

    local title = text(panel, 18, colors.text, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("SETTINGS")
    local subtitle = text(panel, 9, colors.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Tune ForeverChat without slash commands. Changes apply instantly.")

    local close = self:MakeButton(panel, "BACK TO CHAT", 112, 28, function() FC:ToggleSettings(false) end)
    close:SetPoint("TOPRIGHT", -18, -16)

    local left = CreateFrame("Frame", nil, panel)
    left:SetPoint("TOPLEFT", 20, -72)
    left:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 18)
    left:SetWidth(440)
    local right = CreateFrame("Frame", nil, panel)
    right:SetPoint("TOPRIGHT", -20, -72)
    right:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 18)
    right:SetWidth(440)

    local a = self:RegisterAccentFont(text(left, 10, colors.gold, "OUTLINE"))
    a:SetPoint("TOPLEFT", 0, 0)
    a:SetText("APPEARANCE")
    self:BuildSettingStepper(left, -24, "UI scale", "Scale the complete ForeverChat interface.", "scale", 0.75, 1.35, 0.05, function(v) return string.format("%.2fx", v) end, function() FC:ApplyAppearance() end)
    self:BuildSettingStepper(left, -86, "Message font", "Adjust chat readability without scaling the HUD.", "fontSize", 10, 18, 1, function(v) return tostring(v) .. " px" end, function() FC:ApplyAppearance() end)
    self:BuildSettingStepper(left, -148, "Line spacing", "More air between messages or a denser chat log.", "messageSpacing", 0, 8, 1, function(v) return tostring(v) .. " px" end, function() FC:ApplyAppearance() end)
    self:BuildSettingStepper(left, -210, "Opacity", "Change background opacity; text remains fully readable.", "opacity", 0.65, 1.0, 0.05, function(v) return tostring(math.floor(v * 100 + 0.5)) .. "%" end, function() FC:ApplyAppearance() end)

    local themeLabel = text(left, 11, colors.text)
    themeLabel:SetPoint("TOPLEFT", 12, -286)
    themeLabel:SetText("Accent theme")
    local themeDesc = text(left, 8, colors.muted)
    themeDesc:SetPoint("TOPLEFT", themeLabel, "BOTTOMLEFT", 0, -4)
    themeDesc:SetText("Choose the visual signature of your Forever HUD.")
    self.themeButtons = {}
    local bx = 12
    for _, theme in ipairs(themeOrder) do
        local b = self:MakeButton(left, theme, 86, 28, function()
            FC.db.theme = theme
            FC:ApplyAppearance()
            FC:RefreshThemeButtons()
        end)
        b:SetPoint("TOPLEFT", bx, -330)
        bx = bx + 98
        self.themeButtons[theme] = b
    end

    local c = self:RegisterAccentFont(text(right, 10, colors.gold, "OUTLINE"))
    c:SetPoint("TOPLEFT", 0, 0)
    c:SetText("CHAT & HARDCORE")
    self:BuildSettingToggle(right, -24, "Timestamps", "Show a compact HH:MM time before each message.", "timestamps", function() FC:Render(true) end)
    self:BuildSettingToggle(right, -80, "Right-side intelligence rail", "Inbox, LFG Radar and quick danger reporting.", "showRail", function() FC:ApplyAppearance() end)
    self:BuildSettingToggle(right, -136, "Mention alerts", "Show a top-screen toast when someone writes your character name.", "mentionAlerts")
    self:BuildSettingToggle(right, -192, "Hardcore danger alerts", "Show Forever Network danger reports as prominent toasts.", "dangerAlerts")
    self:BuildSettingToggle(right, -248, "Automatic danger detection", "Flag chat containing danger, elite, patrol and Hardcore warning terms.", "autoDanger")
    self:BuildSettingToggle(right, -304, "Duplicate spam filter", "Suppress repeated identical posts from the same player for a few seconds.", "duplicateFilter")

    local reset = self:MakeButton(right, "RESET VISUALS", 132, 30, function()
        FC.db.scale = 1.0
        FC.db.fontSize = 13
        FC.db.messageSpacing = 3
        FC.db.opacity = 1.0
        FC.db.theme = "GOLD"
        FC.db.showRail = true
        FC.db.compact = false
        FC:ApplyAppearance()
        FC:ToggleSettings(false)
        FC:Print("Visual settings reset.")
    end)
    reset:SetPoint("BOTTOMRIGHT", -2, 4)

    local foot = text(right, 8, colors.muted)
    foot:SetPoint("BOTTOMLEFT", 0, 10)
    foot:SetText("ForeverChat 0.3  /  by 0xgle")
    panel:Hide()
end

function FC:RefreshThemeButtons()
    if not self.themeButtons then return end
    for theme, b in pairs(self.themeButtons) do
        if b and b.label then
            if theme == self.db.theme then
                local c = self:GetAccent()
                b.label:SetTextColor(c[1], c[2], c[3], 1)
            else
                b.label:SetTextColor(colors.muted[1], colors.muted[2], colors.muted[3], 1)
            end
        end
    end
end

function FC:ToggleSettings(force)
    if not self.settingsPanel then return end
    if self.copyPanel then self.copyPanel:Hide() end
    if self.search then self.search:ClearFocus() end
    local show = force
    if show == nil then show = not self.settingsPanel:IsShown() end
    if show then
        self.body:Hide()
        self.bottom:Hide()
        self.tabsBar:Hide()
        self.settingsPanel:Show()
        self:RefreshThemeButtons()
    else
        self.settingsPanel:Hide()
        self.tabsBar:Show()
        self.body:Show()
        self.bottom:Show()
        self:Render(true)
    end
end

function FC:Show()
    if self.frame then self.frame:Show() self.db.shown = true self.unread[self.currentTab] = 0 self:Render(true) self:UpdateRail() end
end

function FC:Hide()
    if self.frame then self.frame:Hide() self.db.shown = false end
end

function FC:Toggle()
    if not self.initialized then
        self:Print("UI is not initialized. " .. tostring(self.initError or "Use /reload once."))
        return
    end
    if self.frame:IsShown() then self:Hide() else self:Show() end
end

function FC:HandleChat(event, ...)
    local msg, sender, _, channelName, _, flags, _, channelNumber, channelBaseName, _, lineID, guid = ...
    if not msg or msg == "" then return end
    local channel = channelBaseName or channelName or ""
    local isLFG, lfg = self:ParseLFG(msg, channel)
    local isWhisper = event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM"
    local isGroup = event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_INSTANCE_CHAT" or event == "CHAT_MSG_INSTANCE_CHAT_LEADER"
    local isGuild = event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER"
    local me = UnitName and UnitName("player") or ""
    local isMention = false
    if me ~= "" and sender and not self:IsMine(sender) then
        isMention = lower(msg):find(self:ShortName(me):lower(), 1, true) ~= nil
    end
    local labels = {
        CHAT_MSG_SAY="SAY", CHAT_MSG_YELL="YELL", CHAT_MSG_GUILD="GUILD", CHAT_MSG_OFFICER="OFFICER",
        CHAT_MSG_PARTY="PARTY", CHAT_MSG_PARTY_LEADER="PARTY", CHAT_MSG_RAID="RAID", CHAT_MSG_RAID_LEADER="RAID",
        CHAT_MSG_RAID_WARNING="WARNING", CHAT_MSG_INSTANCE_CHAT="INSTANCE", CHAT_MSG_INSTANCE_CHAT_LEADER="INSTANCE",
        CHAT_MSG_WHISPER="WHISPER", CHAT_MSG_WHISPER_INFORM="TO", CHAT_MSG_CHANNEL="CHANNEL", CHAT_MSG_SYSTEM="SYSTEM",
        CHAT_MSG_EMOTE="EMOTE", CHAT_MSG_TEXT_EMOTE="EMOTE",
    }
    self:AddRecord({
        event = event, label = labels[event] or "CHAT", msg = msg, sender = sender, channel = channel,
        channelNumber = channelNumber, flags = flags, lineID = lineID, guid = guid,
        isLFG = isLFG, lfg = lfg, isTrade = self:IsTrade(msg, channel), isDanger = (self.db.autoDanger ~= false and self:IsDanger(msg)) or false,
        isWhisper = isWhisper, isGroup = isGroup, isGuild = isGuild, isMention = isMention,
    })
end

function FC:RegisterNetwork()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, self.prefix)
    elseif RegisterAddonMessagePrefix then
        pcall(RegisterAddonMessagePrefix, self.prefix)
    end
end

function FC:NetworkSend(payload, channel)
    if not payload or not channel then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        pcall(C_ChatInfo.SendAddonMessage, self.prefix, payload, channel)
    elseif SendAddonMessage then
        pcall(SendAddonMessage, self.prefix, payload, channel)
    end
end

function FC:BroadcastHello()
    local now = GetTime()
    if self.lastHello and now - self.lastHello < 30 then return end
    self.lastHello = now
    local payload = "HELLO:" .. self.version
    if IsInGuild and IsInGuild() then self:NetworkSend(payload, "GUILD") end
    if IsInRaid and IsInRaid() then
        self:NetworkSend(payload, "RAID")
    elseif IsInGroup and IsInGroup() then
        self:NetworkSend(payload, "PARTY")
    end
end

function FC:SendDanger(message)
    message = plain(message or ""):gsub("[\r\n]", " ")
    if message == "" then
        self:Print("Use: /fc danger <description>")
        return
    end
    if #message > 150 then message = message:sub(1, 150) end
    local zone = GetZoneText and GetZoneText() or "World"
    zone = plain(zone):gsub(":", "-")
    local me = UnitName and UnitName("player") or "Player"
    self:AddRecord({ label="DANGER", msg=message, sender=me, zone=zone, isDanger=true, isNetwork=true, isLocal=true })
    local payload = "DANGER:" .. zone .. ":" .. message
    local sent = false
    if IsInRaid and IsInRaid() then self:NetworkSend(payload, "RAID") sent = true
    elseif IsInGroup and IsInGroup() then self:NetworkSend(payload, "PARTY") sent = true end
    if IsInGuild and IsInGuild() then self:NetworkSend(payload, "GUILD") sent = true end
    if sent then self:Print("Danger report shared with ForeverChat peers.") else self:Print("Danger saved locally; group/guild required to share.") end
end

function FC:HandleAddonMessage(prefix, payload, channel, sender)
    if prefix ~= self.prefix or not payload then return end
    if payload:find("^HELLO:") then
        self.peerSeen[sender or "?"] = time()
        self:UpdateStatus()
        return
    end
    local zone, msg = payload:match("^DANGER:([^:]-):(.+)$")
    if zone and msg and sender and not self:IsMine(sender) then
        self.peerSeen[sender] = time()
        self:AddRecord({ label="DANGER", msg=msg, sender=sender, zone=zone, isDanger=true, isNetwork=true })
    end
end

function FC:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        self:HandleAddonMessage(...)
        return
    end
    if event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        self:BroadcastHello()
        return
    end
    if event:find("^CHAT_MSG_") then self:HandleChat(event, ...) end
end

function FC:Initialize()
    if self.initialized then return true end
    ForeverChatDB = ForeverChatDB or {}
    local oldSchema = tonumber(ForeverChatDB.schemaVersion or 1) or 1
    copyDefaults(defaults, ForeverChatDB)
    self.db = ForeverChatDB
    if oldSchema < 2 then
        if tonumber(self.db.width) == 900 then self.db.width = 1000 end
        if tonumber(self.db.height) == 470 then self.db.height = 650 end
        self.db.schemaVersion = 3
    end
    if oldSchema < 3 then
        self.db.width, self.db.height = 1000, 650
        self.db.schemaVersion = 3
    end
    self.db.width, self.db.height = 1000, 650
    self.db.scale = math.max(0.75, math.min(1.35, tonumber(self.db.scale) or 1))
    self.db.fontSize = math.max(10, math.min(18, tonumber(self.db.fontSize) or 13))
    self.db.opacity = math.max(0.65, math.min(1, tonumber(self.db.opacity) or 1))
    self.db.messageSpacing = math.max(0, math.min(8, tonumber(self.db.messageSpacing) or 3))
    if type(self.db.history) ~= "table" then self.db.history = {} end
    if type(self.db.blockedWords) ~= "table" then self.db.blockedWords = {} end
    while #self.db.history > self.historyLimit do table.remove(self.db.history, 1) end
    for _, tab in ipairs(tabs) do self.unread[tab] = 0 end

    self:RegisterNetwork()
    if not self:SafeCall("BuildUI", function() self:BuildUI() end) then return false end

    local events = {
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
        "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL", "CHAT_MSG_SYSTEM",
        "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE",
    }
    for _, event in ipairs(events) do self:SafeRegister(event) end

    self.initialized = true
    if self.db.shown then self.frame:Show() else self.frame:Hide() end
    self:AddRecord({ label="FOREVER", msg="ForeverChat 0.3 loaded. Welcome to the Sanctum. /fc settings for appearance.", isSystem=true })
    self:Print("0.3 loaded. Type |cffffffff/fc|r to toggle or |cffffffff/fc settings|r.")
    self:RegisterWithCore()
    self:BroadcastHello()
    return true
end

function FC:HandleSlash(input)
    input = tostring(input or "")
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" then
        self:Toggle()
    elseif cmd == "help" then
        self:Print("/fc - toggle | /fc settings | /fc status | /fc danger <text> | /fc clear | /fc reset | /fc compact")
        self:Print("/fc block <word> | /fc unblock <word>")
    elseif cmd == "settings" then
        if self.initialized then self:Show() self:ToggleSettings(true) end
    elseif cmd == "status" then
        local build = GetBuildInfo and select(4, GetBuildInfo()) or "?"
        self:Print("version=" .. self.version .. " interface=" .. tostring(build) .. " initialized=" .. tostring(self.initialized))
        if self.initError then self:Print("last error: " .. self.initError) end
    elseif cmd == "danger" then
        self:SendDanger(rest)
    elseif cmd == "clear" then
        if self.db then
            for i = #self.db.history, 1, -1 do table.remove(self.db.history, i) end
            self:Render(true)
            self:UpdateRail()
            self:Print("History cleared.")
        end
    elseif cmd == "reset" then
        if self.db and self.frame then
            self.db.x, self.db.y, self.db.width, self.db.height, self.db.scale = 30, 80, 1000, 650, 1
            self.frame:ClearAllPoints()
            self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 80)
            self.frame:SetSize(1000, 650)
            self:FitScale()
            self:Show()
            self:Print("Layout reset.")
        end
    elseif cmd == "compact" then
        if self.rail then
            self.db.compact = not self.db.compact
            self:ApplyAppearance()
            self:Print("Compact mode: " .. tostring(self.db.compact))
        end
    elseif cmd == "block" and rest ~= "" then
        table.insert(self.db.blockedWords, rest:lower())
        self:Print("Blocked: " .. rest)
    elseif cmd == "unblock" and rest ~= "" then
        local target = rest:lower()
        for i = #self.db.blockedWords, 1, -1 do
            if tostring(self.db.blockedWords[i]):lower() == target then table.remove(self.db.blockedWords, i) end
        end
        self:Print("Unblocked: " .. rest)
    else
        self:Print("Unknown command. Use /fc help")
    end
end

SLASH_FOREVERCHAT1 = "/fc"
SLASH_FOREVERCHAT2 = "/foreverchat"
SlashCmdList.FOREVERCHAT = function(msg)
    FC:HandleSlash(msg)
end

FC.eventFrame = CreateFrame("Frame")
FC.eventFrame:RegisterEvent("PLAYER_LOGIN")
FC.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        FC.eventFrame:UnregisterEvent("PLAYER_LOGIN")
        FC:SafeCall("Initialize", function() FC:Initialize() end)
    elseif FC.initialized then
        local args, count = {...}, select("#", ...)
        FC:SafeCall(event, function() FC:OnEvent(event, unpack(args, 1, count)) end)
    end
end)
