local FC = ForeverChat
local tabs = {"ALL", "GROUP", "GUILD", "WHISPERS", "LFG", "TRADE", "ALERTS", "SAVED"}
FC.tabs = tabs
FC.tabNames = {ALL="All", GROUP="Group", GUILD="Guild", WHISPERS="Whispers", LFG="LFG radar", TRADE="Trade", ALERTS="Alerts", SAVED="Saved"}
FC.tabIcons = {ALL="chat", GROUP="group", GUILD="guild", WHISPERS="whisper", LFG="radar", TRADE="trade", ALERTS="alert", SAVED="star"}
function FC:Plain(s)
    return tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", "")
end
local function clamp(v, lo, hi, default)
    return math.max(lo, math.min(hi, tonumber(v) or default))
end
function FC:UpgradeDatabase()
    local d = self.db
    d.width = clamp(d.width, 840, 1400, 980)
    d.height = clamp(d.height, 520, 900, 560)
    d.scale = clamp(d.scale, .65, 1.4, 1)
    d.fontSize = clamp(d.fontSize, 11, 20, 13)
    d.opacity = clamp(d.opacity, .55, 1, .97)
    d.historySize = clamp(d.historySize, 200, 2000, 800)
    d.lfgMinutes = clamp(d.lfgMinutes, 2, 30, 10)
    self.historyLimit = d.historySize
    local realm = GetRealmName and GetRealmName() or "Realm"
    local owner = (UnitName("player") or "Player") .. "-" .. realm
    d.characters = type(d.characters)=="table" and d.characters or {}
    local saved = d.characters[owner]
    if saved then
        d.history = saved.history or {}
        d.favorites = saved.favorites or {}
    elseif d.owner and d.owner ~= owner then
        d.history, d.favorites = {}, {}
    end
    d.owner = owner
    d.characters[owner] = {history=d.history, favorites=d.favorites}
    local nextID = 0
    for _, r in ipairs(d.history) do nextID = math.max(nextID, tonumber(r.id) or 0) end
    for _, r in pairs(d.favorites) do if type(r)=="table" then nextID=math.max(nextID,tonumber(r.id) or 0) end end
    for _, r in ipairs(d.history) do
        if not r.id then nextID=nextID+1; r.id=nextID end
    end
    self.nextID = nextID
    self.pending = 0
    self.currentTab = "ALL"
    for _, tab in ipairs(tabs) do self.unread[tab]=0 end
end
function FC:Token(s, token)
    return (" "..s.." "):find("%f[%w]"..token.."%f[%W]") ~= nil
end
local oldDungeon = FC.FindDungeon
function FC:FindDungeon(msg)
    local s=self:Plain(msg):lower()
    if s:find("dire maul",1,true) or self:Token(s,"dme") or self:Token(s,"dmw") or self:Token(s,"dmn") then return "DIRE MAUL" end
    -- Punctuation should not hide common abbreviations.
    return oldDungeon(self, s:gsub("[%p]", " "))
end
local oldParse = FC.ParseLFG
function FC:ParseLFG(msg, channel)
    local s=self:Plain(msg):lower():gsub("[%p]", " ")
    local found, meta=oldParse(self,s,channel)
    local action=s:match("%f[%w]lf%d+m%f[%W]")
    if action then found=true; meta=meta or {}; meta.action="LFM"; meta.dungeon=self:FindDungeon(msg) end
    if found then
        meta=meta or {action="LFG"}; local roles={}
        if self:Token(s,"tank") or self:Token(s,"tanks") then roles[#roles+1]="TANK" end
        if self:Token(s,"heal") or self:Token(s,"healer") or self:Token(s,"heals") then roles[#roles+1]="HEAL" end
        if self:Token(s,"dps") or self:Token(s,"dd") then roles[#roles+1]="DPS" end
        meta.role=#roles>0 and table.concat(roles,"+") or nil
        return true,meta
    end
    return false,nil
end
function FC:IsDuplicate(sender,msg,event)
    local key=(event or "").."\031"..(sender or "").."\031"..self:Plain(msg)
    local now=GetTime(); local last=self.duplicateCache[key]
    self.duplicateCache[key]=now
    return last and now-last < self.db.duplicateSeconds
end
local oldMatch = FC.MatchesTab
function FC:MatchesTab(r,tab)
    if tab=="SAVED" then return self.db.favorites[tostring(r.id)] ~= nil end
    return oldMatch(self,r,tab)
end
function FC:MatchesLFG(r)
    if not r.isLFG then return false end
    if time()-(r.t or 0)>self.db.lfgMinutes*60 then return false end
    if self.db.lfgRole~="ANY" and not ((r.lfg and r.lfg.role or ""):find(self.db.lfgRole,1,true)) then return false end
    local dungeon=self.db.dungeon:lower()
    return dungeon=="" or ((r.lfg and r.lfg.dungeon or "").." "..self:Plain(r.msg)):lower():find(dungeon,1,true)~=nil
end
function FC:VisibleRecord(r)
    return self:MatchesTab(r,self.currentTab) and self:MatchesSearch(r,self:GetSearch()) and (self.currentTab~="LFG" or self:MatchesLFG(r))
end
function FC:AddRecord(r)
    if not self.db or type(r.msg)~="string" then return end
    if self:IsBlocked(r.sender,r.msg) or self:IsDuplicate(r.sender,r.msg,r.event or r.label) then return end
    r.t=r.t or time(); self.nextID=(self.nextID or 0)+1; r.id=self.nextID
    table.insert(self.db.history,r)
    while #self.db.history>self.historyLimit do table.remove(self.db.history,1) end
    for _,tab in ipairs(tabs) do
        if self:MatchesTab(r,tab) and (tab~=self.currentTab or not self.frame or not self.frame:IsShown() or self.paused) then
            self.unread[tab]=math.min(999,(self.unread[tab] or 0)+1)
        end
    end
    if self.initialized then
        self.dirty=true
        if self.paused and self:VisibleRecord(r) then self.pending=(self.pending or 0)+1 end
        if r.event=="CHAT_MSG_WHISPER" then self.lastWhisper=r.sender end
        if not self:IsMine(r.sender) and (r.isMention or r.event=="CHAT_MSG_WHISPER" or (r.isNetwork and not r.isLocal)) then self:ShowToast(r) end
    end
end
local oldFormat=FC.FormatRecord
function FC:FormatRecord(r)
    local formatted=oldFormat(self,r)
    if self.db.classColors and r.guid and GetPlayerInfoByGUID then
        local ok,_,class=pcall(GetPlayerInfoByGUID,r.guid)
        local c=ok and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c then formatted=formatted:gsub("|cffd9a441",string.format("|cff%02x%02x%02x",c.r*255,c.g*255,c.b*255)) end
    end
    local star=self.db.favorites[tostring(r.id)] and "|cffffd078*|r" or "|cff71838c+|r"
    return "|Hforeverchat:"..r.id.."|h["..star.."]|h "..formatted
end
function FC:ViewRecords()
    if self.currentTab=="SAVED" then
        local list={}
        for _,r in pairs(self.db.favorites) do if type(r)=="table" then list[#list+1]=r end end
        table.sort(list,function(a,b) return a.t==b.t and a.id<b.id or a.t<b.t end)
        return list
    end
    return self.db.history
end
function FC:Render(force)
    if not self.messages then return end
    self:UpdateTabs(); self:UpdateStatus()
    if self.paused and not force then return end
    if not self.frame:IsShown() and not force then return end
    self.messages:Clear()
    local count=0
    for _,r in ipairs(self:ViewRecords()) do
        if self:VisibleRecord(r) then self.messages:AddMessage(self:FormatRecord(r),.88,.91,.92); count=count+1 end
    end
    self.empty:SetShown(count==0)
    self.emptyLabel:SetText(self.currentTab=="LFG" and "Listening for groups\nOnly messages from channels you have joined appear here." or self.currentTab=="SAVED" and "Your saved messages\nClick [+] beside a message to keep it here." or "Your conversation starts here\nMessages will appear as they arrive.")
    self.messages:ScrollToBottom()
    self.visibleCount=count
    self:UpdateStatus()
end
function FC:Resume()
    self.paused=false; self.pending=0; self.unread[self.currentTab]=0; self:Render(true)
end
function FC:SetTab(tab)
    self.currentTab=tab; self.conversation=nil; self.unread[tab]=0
    self:Resume(); self:Layout()
end
function FC:UpdateTabs()
    if not self.tabButtons then return end
    for _,tab in ipairs(tabs) do
        local b=self.tabButtons[tab]; local active=tab==self.currentTab
        b.active=active; b.line:SetShown(active)
        b.label:SetTextColor(active and .98 or .65,active and .85 or .72,active and .58 or .75)
        b.count:SetText((self.unread[tab] or 0)>0 and tostring(self.unread[tab]) or "")
        b.bg:SetColorTexture(active and .06 or .025,active and .16 or .04,active and .19 or .055,.95)
    end
end
function FC:UpdateStatus()
    if not self.status then return end
    local peers=0
    for _,t in pairs(self.peerSeen) do if time()-t<300 then peers=peers+1 end end
    self.status:SetText((self.paused and "READING" or "LIVE").."  |  "..(self.visibleCount or 0).." messages  |  "..peers.." peers")
    self.jump:SetShown(self.paused or (self.pending or 0)>0)
    self.jump.label:SetText((self.pending or 0)>0 and (self.pending.." new - resume") or "Return to live")
end
function FC:UpdateRail()
    if not self.whisperRows then return end
    local wh,lfg,seenW,seenL={},{},{},{}
    for i=#self.db.history,1,-1 do
        local r=self.db.history[i]
        if r.isWhisper and r.sender and not seenW[r.sender] and #wh<2 then
            seenW[r.sender]=true; wh[#wh+1]=r
        end
        if self:MatchesLFG(r) and r.sender and not seenL[r.sender] and #lfg<3 then
            seenL[r.sender]=true; lfg[#lfg+1]=r
        end
    end
    for _,pair in ipairs({{self.whisperRows,wh},{self.lfgRows,lfg}}) do
        for i,row in ipairs(pair[1]) do
            local r=pair[2][i]; row.record=r; row.sender=r and r.sender
            if r then
                row.title:SetText(r.isLFG and ((r.lfg and r.lfg.dungeon or "WORLD").."  "..(r.lfg and r.lfg.role or "LFG")) or self:ShortName(r.sender))
                row.sub:SetText(self:Plain(r.msg))
            else row.title:SetText(i==1 and "Listening..." or ""); row.sub:SetText(i==1 and "New messages appear here" or "") end
        end
    end
end
function FC:ToggleFavorite(id)
    local key=tostring(id)
    if self.db.favorites[key] then self.db.favorites[key]=nil else
        local n=0; for _ in pairs(self.db.favorites) do n=n+1 end
        if n>=100 then self:Print("Saved messages limit: 100. Remove a saved message first."); return end
        for _,r in ipairs(self.db.history) do if tostring(r.id)==key then self.db.favorites[key]=r; break end end
    end
    self:Resume()
end
function FC:OpenChat(prefix)
    if ChatFrameUtil and ChatFrameUtil.OpenChat then ChatFrameUtil.OpenChat(prefix or "",DEFAULT_CHAT_FRAME)
    elseif ChatFrame_OpenChat then ChatFrame_OpenChat(prefix or "",DEFAULT_CHAT_FRAME or ChatFrame1) end
end
function FC:ShowToast(r)
    if not self.toast or not self.db.toasts then return end
    if self.db.combatQuiet and InCombatLockdown and InCombatLockdown() then return end
    self.toastTitle:SetText(r.isNetwork and "DANGER REPORT" or r.isWhisper and "NEW WHISPER" or "MENTION")
    self.toastBody:SetText(self:ShortName(r.sender)..": "..self:Plain(r.msg))
    self.toastRecord=r; self.toast:Show(); self.toastUntil=GetTime()+6
    if self.db.sound and (not self.lastSound or GetTime()-self.lastSound>3) and PlaySound then
        PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856); self.lastSound=GetTime()
    end
end
local oldHello=FC.BroadcastHello
function FC:BroadcastHello()
    if self.lastHello and GetTime()-self.lastHello<30 then return end
    self.lastHello=GetTime(); oldHello(self)
end
local oldDanger=FC.SendDanger
function FC:SendDanger(message)
    if self.lastDanger and GetTime()-self.lastDanger<10 then self:Print("Please wait before sending another report."); return end
    if self:Plain(message):match("%S") then self.lastDanger=GetTime() end
    oldDanger(self,message)
end
local oldNetwork=FC.HandleAddonMessage
function FC:HandleAddonMessage(prefix,payload,channel,sender)
    if type(payload)~="string" or #payload>255 or not sender then return end
    if channel~="PARTY" and channel~="RAID" and channel~="GUILD" and channel~="INSTANCE_CHAT" then return end
    if self:IsMine(sender) then return end
    oldNetwork(self,prefix,payload,channel,sender)
end
function FC:StartMaintenance()
    self.tick=0; self.maintenance=0
    self.frame:SetScript("OnUpdate",function(_,elapsed) FC:Tick(elapsed) end)
    -- Driver must keep running while the main window is hidden.
    self.frame:SetScript("OnUpdate",nil)
    self.eventFrame:SetScript("OnUpdate",function(_,elapsed) FC:Tick(elapsed) end)
end
function FC:Tick(elapsed)
    self.tick=self.tick+elapsed; self.maintenance=self.maintenance+elapsed
    if self.toast:IsShown() and GetTime()>(self.toastUntil or 0) then self.toast:Hide() end
    if self.tick>.12 then
        self.tick=0
        if self.dirty then self.dirty=false; self:Render(false); self:UpdateRail() end
    end
    if self.maintenance>30 then
        self.maintenance=0
        local now=GetTime()
        for k,t in pairs(self.duplicateCache) do if now-t>60 then self.duplicateCache[k]=nil end end
        for k,t in pairs(self.peerSeen) do if time()-t>300 then self.peerSeen[k]=nil end end
        self:UpdateRail(); self:UpdateStatus()
        if self.currentTab=="LFG" then self:Render(false) end
        if not self.lastHello or now-self.lastHello>120 then self:BroadcastHello() end
    end
end
local oldSlash=FC.HandleSlash
function FC:HandleSlash(input)
    local cmd,rest=tostring(input or ""):match("^(%S*)%s*(.-)$"); cmd=cmd:lower()
    if not self.db then self:Print("Please wait for player login."); return end
    if cmd=="settings" or cmd=="options" then self:ToggleSettings()
    elseif cmd=="compact" then self.db.compact=not self.db.compact; self:Layout()
    elseif cmd=="lock" then self.db.locked=not self.db.locked; self:ApplySettings()
    elseif cmd=="copy" then self:CopyView()
    elseif cmd=="reset" then
        self.db.x=30; self.db.y=160; self.db.point="BOTTOMLEFT"; self.db.relPoint="BOTTOMLEFT"
        self.db.width=980; self.db.height=560; self.db.scale=1; self.db.locked=false
        self.frame:ClearAllPoints(); self.frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",30,160)
        self:ApplySettings(); self:Show()
    elseif cmd=="clear" then
        for i=#self.db.history,1,-1 do table.remove(self.db.history,i) end
        for _,tab in ipairs(tabs) do self.unread[tab]=0 end
        self:Resume(); self:UpdateRail()
    elseif cmd=="help" then
        self:Print("/fc | /fc settings | /fc compact | /fc lock | /fc copy | /fc reset | /fc status")
        self:Print("/fc danger <text> | /fc block <word> | /fc unblock <word> | /fc clear")
    else oldSlash(self,input) end
end
local oldOnEvent=FC.OnEvent
function FC:OnEvent(event,...)
    if event=="PLAYER_LOGOUT" and not self.db.saveHistory then
        for _,c in pairs(self.db.characters) do c.history={} end
        self.db.history={}; return
    end
    oldOnEvent(self,event,...)
end

function FC:Show()
    if self.frame then self.frame:Show(); self.db.shown=true; self:Resume(); self:UpdateRail() end
end
