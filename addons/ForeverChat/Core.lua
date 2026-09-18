local addonName = ...
local FC = {}
_G.ForeverChat = FC

FC.name = addonName or "ForeverChat"
FC.version = "0.2.0-beta1"
FC.prefix = "ForeverChat"
FC.initialized = false
FC.initError = nil
FC.historyLimit = 400
FC.unread = {}
FC.currentTab = "ALL"
FC.peerSeen = {}
FC.duplicateCache = {}

local defaults = {
    shown = true,
    x = 30,
    y = 160,
    width = 980,
    height = 560,
    scale = 1.0,
    fontSize = 13,
    timestamps = true,
    history = {},
    blockedWords = {},
    compact = false,
    locked = false,
    opacity = 0.97,
    sound = false,
    toasts = true,
    combatQuiet = true,
    classColors = true,
    saveHistory = true,
    showMinimap = false,
    historySize = 800,
    duplicateSeconds = 8,
    lfgMinutes = 10,
    lfgRole = "ANY",
    dungeon = "",
    favorites = {},

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
    bg = {0.035, 0.043, 0.052, 0.98},
    panel = {0.055, 0.066, 0.078, 0.99},
    panel2 = {0.075, 0.087, 0.10, 1},
    border = {0.20, 0.23, 0.27, 1},
    gold = {0.86, 0.65, 0.25, 1},
    teal = {0.22, 0.80, 0.72, 1},
    text = {0.92, 0.94, 0.96, 1},
    muted = {0.56, 0.61, 0.67, 1},
    red = {0.96, 0.30, 0.29, 1},
}

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
    f:SetFont(STANDARD_TEXT_FONT, size or 12, flags or "")
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
    if not sender or sender == "" or not msg then return false end
    local key = tostring(sender) .. "\031" .. plain(msg)
    local now = GetTime and GetTime() or 0
    local last = self.duplicateCache[key]
    self.duplicateCache[key] = now
    return last and (now - last) < 4
end

function FC:AddRecord(r)
    if not self.db then return end
    if self:IsBlocked(r.sender, r.msg) or self:IsDuplicate(r.sender, r.msg) then return end
    r.t = r.t or time()
    table.insert(self.db.history, r)
    while #self.db.history > self.historyLimit do table.remove(self.db.history, 1) end

    for _, tab in ipairs(tabs) do
        if tab ~= self.currentTab and self:MatchesTab(r, tab) then
            self.unread[tab] = (self.unread[tab] or 0) + 1
        end
    end

    if self.initialized then
        self:Render(false)
        self:UpdateRail()
        if r.isMention or (r.isNetwork and not r.isLocal) then self:ShowToast(r) end
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
            if n > 0 then caption = caption .. " " .. math.min(n, 99) end
            b.label:SetText(caption)
            if tab == self.currentTab then
                b.label:SetTextColor(colors.text[1], colors.text[2], colors.text[3])
                b.line:Show()
            else
                b.label:SetTextColor(colors.muted[1], colors.muted[2], colors.muted[3])
                b.line:Hide()
            end
        end
    end
end

function FC:Render(force)
    if not self.messages or not self.db then return end
    if not force and self.frame and not self.frame:IsShown() then return end
    self.messages:Clear()
    local query = self:GetSearch()
    local shown = 0
    local history = self.db.history
    local first = math.max(1, #history - 399)
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
end

function FC:UpdateStatus()
    if not self.status or not self.db then return end
    local peers = 0
    local now = time()
    for _, t in pairs(self.peerSeen) do if now - t < 300 then peers = peers + 1 end end
    self.status:SetText("LIVE  /  " .. #self.db.history .. " stored  /  " .. peers .. " Forever peer(s)  /  /fc help")
end

function FC:UpdateRail()
    if not self.whisperRows or not self.db then return end
    local seen, list = {}, {}
    for i = #self.db.history, 1, -1 do
        local r = self.db.history[i]
        if r.isWhisper and r.sender and r.sender ~= "" then
            local key = self:ShortName(r.sender)
            if not seen[key] then
                seen[key] = true
                table.insert(list, r)
                if #list >= 3 then break end
            end
        end
    end
    for i, row in ipairs(self.whisperRows) do
        local r = list[i]
        if r then
            row.sender = r.sender
            row.title:SetText(self:ShortName(r.sender))
            local snip = plain(r.msg or "")
            if #snip > 30 then snip = snip:sub(1, 27) .. "..." end
            row.sub:SetText(snip)
        else
            row.sender = nil
            row.title:SetText(i == 1 and "No whispers yet" or "")
            row.sub:SetText(i == 1 and "Recent conversations appear here" or "")
        end
    end

    local lfg = {}
    for i = #self.db.history, 1, -1 do
        local r = self.db.history[i]
        if r.isLFG and r.sender then
            table.insert(lfg, r)
            if #lfg >= 4 then break end
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
            if #snip > 34 then snip = snip:sub(1, 31) .. "..." end
            row.sub:SetText(snip)
        else
            row.sender = nil
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

function FC:Show()
    if self.frame then self.frame:Show() self.db.shown = true self:Render(true) end
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
        isLFG = isLFG, lfg = lfg, isTrade = self:IsTrade(msg, channel), isDanger = self:IsDanger(msg),
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
    if event == "PLAYER_LOGOUT" then if not self.db.saveHistory then self.db.history = {} end return end
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
    copyDefaults(defaults, ForeverChatDB)
    self.db = ForeverChatDB
    if type(self.db.history) ~= "table" then self.db.history = {} end
    if type(self.db.blockedWords) ~= "table" then self.db.blockedWords = {} end
    for _, tab in ipairs(tabs) do self.unread[tab] = 0 end

    self:UpgradeDatabase()
    self:RegisterNetwork()
    if not self:SafeCall("BuildUI", function() self:BuildUI() end) then return false end

    local events = {
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
        "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL", "CHAT_MSG_SYSTEM",
        "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE", "PLAYER_LOGOUT",
    }
    for _, event in ipairs(events) do self:SafeRegister(event) end

    self.initialized = true
    self:StartMaintenance()
    if self.db.shown then self.frame:Show() else self.frame:Hide() end
    self:AddRecord({ label="FOREVER", msg="ForeverChat 0.2.0: communication, LFG radar and alerts ready.", isSystem=true })
    self:Print("0.2.0 loaded. Type |cffffffff/fc|r to toggle.")
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
        self:Print("/fc - toggle | /fc status | /fc danger <text> | /fc clear | /fc reset | /fc compact")
        self:Print("/fc block <word> | /fc unblock <word>")
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
            self.db.x, self.db.y, self.db.width, self.db.height, self.db.scale = 30, 160, 900, 470, 1
            self.frame:ClearAllPoints()
            self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 160)
            self.frame:SetSize(900, 470)
            self.frame:SetScale(1)
            self:Show()
            self:Print("Layout reset.")
        end
    elseif cmd == "compact" then
        if self.rail then
            self.db.compact = not self.db.compact
            if self.db.compact then self.rail:Hide() else self.rail:Show() end
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
        local args = {n=select("#", ...), ...}
        FC:SafeCall(event, function() FC:OnEvent(event, unpack(args, 1, args.n)) end)
    end
end)
