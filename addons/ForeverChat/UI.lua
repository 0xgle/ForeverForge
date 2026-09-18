local FC=ForeverChat
local M="Interface\\AddOns\\ForeverChat\\Media\\"
FC.media=M
local U={}; FC.UI=U
local C={gold={.94,.76,.42}, teal={.30,.76,.80}, text={.90,.92,.93}, muted={.55,.64,.69}}
function U:Text(p,size,color,value)
    local f=p:CreateFontString(nil,"OVERLAY"); f:SetFont(STANDARD_TEXT_FONT,size or 12,"")
    f:SetTextColor(unpack(color or C.text)); f:SetJustifyH("LEFT"); f:SetText(value or ""); return f
end
function U:Fill(p,color)
    local t=p:CreateTexture(nil,"BACKGROUND"); t:SetAllPoints(); t:SetColorTexture(unpack(color)); return t
end
function U:Panel(p,alpha)
    local f=CreateFrame("Frame",nil,p,BackdropTemplateMixin and "BackdropTemplate" or nil)
    if f.SetBackdrop then
        f:SetBackdrop({bgFile=M.."obsidian.tga",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        f:SetBackdropColor(.06,.08,.10,alpha or .98); f:SetBackdropBorderColor(.38,.31,.19,1)
    else U:Fill(f,{.025,.04,.055,alpha or .98}) end
    return f
end
function U:Icon(p,name,size)
    local t=p:CreateTexture(nil,"ARTWORK"); t:SetTexture(M..name..".tga"); t:SetSize(size or 28,size or 28); return t
end
function U:Tip(b,title,body)
    b:HookScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(title,1,.84,.5)
        if body then GameTooltip:AddLine(body,.8,.86,.89,true) end; GameTooltip:Show()
    end)
    b:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
function U:Button(p,w,h,label,icon,click)
    local b=CreateFrame("Button",nil,p); b:SetSize(w,h)
    b.bg=U:Fill(b,{.025,.04,.055,.94})
    if icon then b.icon=U:Icon(b,icon,h-6); b.icon:SetPoint("LEFT",3,0) end
    b.label=U:Text(b,11,C.text,label); b.label:SetPoint("LEFT",icon and h+1 or 9,0); b.label:SetPoint("RIGHT",-7,0)
    b.label:SetWordWrap(false)
    b:SetScript("OnEnter",function(self) self.bg:SetColorTexture(.09,.19,.22,1) end)
    b:SetScript("OnLeave",function(self)
        self.bg:SetColorTexture(self.active and .06 or .025,self.active and .16 or .04,self.active and .19 or .055,.94)
    end)
    b:SetScript("OnClick",click); return b
end
function U:Edit(p,w,h,placeholder)
    local e=CreateFrame("EditBox",nil,p); e:SetSize(w,h); e:SetAutoFocus(false)
    e:SetFont(STANDARD_TEXT_FONT,12,""); e:SetTextInsets(9,9,0,0); e:SetMaxLetters(200)
    U:Fill(e,{.015,.026,.034,1})
    e.placeholder=U:Text(e,11,C.muted,placeholder); e.placeholder:SetPoint("LEFT",9,0)
    e:SetScript("OnTextChanged",function(self) self.placeholder:SetShown(self:GetText()=="") end)
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    return e
end
function FC:BuildRow(parent,y)
    local b=U:Button(parent,210,38,"",nil,function(self) if self.sender then FC:OpenChat("/w "..self.sender.." ") end end)
    b:SetPoint("TOPLEFT",10,y); b:SetPoint("TOPRIGHT",-10,y)
    b.label:Hide(); b.title=U:Text(b,11,C.teal); b.title:SetPoint("TOPLEFT",8,-5); b.title:SetPoint("TOPRIGHT",-8,-5); b.title:SetHeight(14); b.title:SetWordWrap(false)
    b.sub=U:Text(b,10,C.muted); b.sub:SetPoint("BOTTOMLEFT",8,4); b.sub:SetPoint("BOTTOMRIGHT",-8,4); b.sub:SetHeight(12); b.sub:SetWordWrap(false)
    b:HookScript("OnEnter",function(self)
        if self.record and GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.sender)
            GameTooltip:AddLine(FC:Plain(self.record.msg),.86,.91,.94,true)
            GameTooltip:AddLine("Click to whisper",.4,.8,.8); GameTooltip:Show()
        end
    end)
    b:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    return b
end
function FC:BuildUI()
    local f=U:Panel(UIParent); self.frame=f; _G.ForeverChatFrame=f
    f:SetSize(self.db.width,self.db.height); f:SetScale(self.db.scale); f:SetFrameStrata("MEDIUM")
    f:SetPoint(self.db.point or "BOTTOMLEFT",UIParent,self.db.relPoint or "BOTTOMLEFT",self.db.x,self.db.y)
    f:SetClampedToScreen(true); f:SetMovable(true); f:SetResizable(true); f:EnableMouse(true)
    if f.SetResizeBounds then f:SetResizeBounds(840,520,1400,900) elseif f.SetMinResize then f:SetMinResize(840,520); f:SetMaxResize(1400,900) end
    local line=f:CreateTexture(nil,"BORDER"); line:SetColorTexture(.63,.48,.24,1); line:SetHeight(2); line:SetPoint("TOPLEFT",1,-1); line:SetPoint("TOPRIGHT",-1,-1)
    local head=CreateFrame("Frame",nil,f); head:SetPoint("TOPLEFT",2,-3); head:SetPoint("TOPRIGHT",-2,-3); head:SetHeight(69)
    head:EnableMouse(true); head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart",function() if not FC.db.locked then f:StartMoving() end end)
    head:SetScript("OnDragStop",function()
        f:StopMovingOrSizing(); local p,_,rp,x,y=f:GetPoint(); FC.db.point=p; FC.db.relPoint=rp; FC.db.x=x; FC.db.y=y
    end)
    local emblem=U:Icon(head,"chat",58); emblem:SetPoint("LEFT",10,0)
    local title=U:Text(head,23,C.gold,"ForeverChat"); title:SetPoint("LEFT",emblem,"RIGHT",8,9)
    local subtitle=U:Text(head,10,C.teal,"CONVERSATIONS  /  COMPANIONS  /  ADVENTURE"); subtitle:SetPoint("LEFT",emblem,"RIGHT",9,-13)
    local close=U:Button(head,32,32,"","close",function() FC:Hide() end); close:SetPoint("RIGHT",-10,0); U:Tip(close,"Close","Use /fc to reopen.")
    local settings=U:Button(head,32,32,"","settings",function() FC:ToggleSettings() end); settings:SetPoint("RIGHT",close,"LEFT",-5,0); U:Tip(settings,"Settings")
    self.lockButton=U:Button(head,32,32,"","unlock",function() FC.db.locked=not FC.db.locked; FC:ApplySettings() end)
    self.lockButton:SetPoint("RIGHT",settings,"LEFT",-5,0); U:Tip(self.lockButton,"Lock position","Lock or unlock moving and resizing.")
    self.search=U:Edit(head,235,30,"Search messages, players, items..."); self.search:SetPoint("RIGHT",self.lockButton,"LEFT",-14,0)
    self.search:SetTextInsets(31,8,0,0); self.search.placeholder:ClearAllPoints(); self.search.placeholder:SetPoint("LEFT",31,0); self.search.placeholder:SetPoint("RIGHT",-8,0); self.search.placeholder:SetWordWrap(false)
    local searchIcon=U:Icon(self.search,"search",25); searchIcon:SetPoint("LEFT",3,0)
    self.search:HookScript("OnTextChanged",function() FC:Resume() end)
    self.tabBar=CreateFrame("Frame",nil,f); self.tabBar:SetPoint("TOPLEFT",12,-76); self.tabBar:SetPoint("TOPRIGHT",-12,-76); self.tabBar:SetHeight(38)
    self.tabButtons={}
    for _,tab in ipairs(self.tabs) do
        local id=tab
        local b=U:Button(self.tabBar,110,38,self.tabNames[tab],self.tabIcons[tab],function() FC:SetTab(id) end)
        b.label:SetFont(STANDARD_TEXT_FONT,10,""); b.label:SetPoint("RIGHT",-20,0)
        b.count=U:Text(b,9,C.teal); b.count:SetPoint("RIGHT",-4,0)
        b.line=b:CreateTexture(nil,"ARTWORK"); b.line:SetColorTexture(.28,.74,.8,1); b.line:SetHeight(2); b.line:SetPoint("BOTTOMLEFT",3,0); b.line:SetPoint("BOTTOMRIGHT",-3,0)
        self.tabButtons[tab]=b
    end
    self.body=CreateFrame("Frame",nil,f); self.body:SetPoint("TOPLEFT",12,-124); self.body:SetPoint("BOTTOMRIGHT",-12,84)
    self.chatPanel=U:Panel(self.body,.98); self.chatPanel:SetPoint("TOPLEFT"); self.chatPanel:SetPoint("BOTTOMLEFT")
    self.rail=U:Panel(self.body,.95); self.rail:SetWidth(230); self.rail:SetPoint("TOPRIGHT"); self.rail:SetPoint("BOTTOMRIGHT")
    local inbox=U:Text(self.rail,10,C.gold,"RECENT WHISPERS"); inbox:SetPoint("TOPLEFT",12,-10)
    self.whisperRows={self:BuildRow(self.rail,-29),self:BuildRow(self.rail,-71)}
    local radar=U:Text(self.rail,10,C.gold,"LFG RADAR"); radar:SetPoint("TOPLEFT",12,-122)
    self.lfgRows={self:BuildRow(self.rail,-140),self:BuildRow(self.rail,-182),self:BuildRow(self.rail,-224)}
    local danger=U:Button(self.rail,210,30,"Report danger","alert",function() FC:OpenChat("/fc danger ") end)
    danger:SetPoint("BOTTOMLEFT",10,10); danger:SetPoint("BOTTOMRIGHT",-10,10)
    U:Tip(danger,"Share a danger report","Opens a message draft. Reports reach ForeverChat users in your group or guild.")
    self.filters=CreateFrame("Frame",nil,self.chatPanel); self.filters:SetPoint("TOPLEFT",8,-8); self.filters:SetPoint("TOPRIGHT",-8,-8); self.filters:SetHeight(28)
    self.roleButton=U:Button(self.filters,126,28,"Role: "..self.db.lfgRole,"group",function()
        local roles={"ANY","TANK","HEAL","DPS"}; local n=1
        for i,v in ipairs(roles) do if v==FC.db.lfgRole then n=i%#roles+1 end end
        FC.db.lfgRole=roles[n]; FC.roleButton.label:SetText("Role: "..roles[n]); FC:Resume(); FC:UpdateRail()
    end); self.roleButton:SetPoint("LEFT")
    local dungeon=U:Edit(self.filters,180,28,"Dungeon: BRD, SM, Deadmines..."); dungeon:SetPoint("LEFT",self.roleButton,"RIGHT",8,0); dungeon:SetText(self.db.dungeon)
    dungeon:HookScript("OnTextChanged",function(self) FC.db.dungeon=self:GetText(); FC:Resume(); FC:UpdateRail() end)
    local messages=CreateFrame("ScrollingMessageFrame",nil,self.chatPanel); self.messages=messages
    messages:SetFading(false); messages:SetMaxLines(2100); messages:SetFont(STANDARD_TEXT_FONT,self.db.fontSize,""); messages:SetJustifyH("LEFT"); messages:SetSpacing(5)
    messages:EnableMouseWheel(true); messages:SetHyperlinksEnabled(true)
    messages:SetScript("OnMouseWheel",function(self,delta)
        if delta>0 then FC.paused=true; self:ScrollUp() else self:ScrollDown(); if self:AtBottom() then FC:Resume() end end
        FC:UpdateStatus()
    end)
    messages:SetScript("OnHyperlinkClick",function(_,link,display,button)
        local id=link:match("^foreverchat:(%d+)$")
        if id then FC:ToggleFavorite(tonumber(id)) elseif SetItemRef then SetItemRef(link,display,button,ChatFrame1) end
    end)
    messages:SetScript("OnHyperlinkEnter",function(self,link)
        if GameTooltip and link:match("^item:") then GameTooltip:SetOwner(self,"ANCHOR_CURSOR"); GameTooltip:SetHyperlink(link); GameTooltip:Show() end
    end)
    messages:SetScript("OnHyperlinkLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    self.empty=CreateFrame("Frame",nil,self.chatPanel); self.empty:SetAllPoints()
    local emptyIcon=U:Icon(self.empty,"chat",72); emptyIcon:SetPoint("CENTER",0,29)
    self.emptyLabel=U:Text(self.empty,12,C.muted); self.emptyLabel:SetPoint("TOP",emptyIcon,"BOTTOM",0,-14); self.emptyLabel:SetJustifyH("CENTER"); self.emptyLabel:SetWidth(410); self.emptyLabel:SetHeight(58)
    self.jump=U:Button(self.chatPanel,180,25,"Return to live","down",function() FC:Resume() end); self.jump:SetPoint("BOTTOM",0,7); self.jump:SetFrameLevel(messages:GetFrameLevel()+3); self.jump:Hide()
    self.actions=CreateFrame("Frame",nil,f); self.actions:SetPoint("BOTTOMLEFT",12,40); self.actions:SetPoint("BOTTOMRIGHT",-12,40); self.actions:SetHeight(32)
    local defs={{"Say","quill",function() FC:OpenChat("/s ") end},{"Group","group",function() FC:OpenChat(IsInRaid() and "/raid " or "/p ") end},{"Guild","guild",function() FC:OpenChat("/g ") end},{"Reply","whisper",function() FC:OpenChat(FC.lastWhisper and "/w "..FC.lastWhisper.." " or "/r ") end},{"Copy","book",function() FC:CopyView() end},{"Compact","chat",function() FC.db.compact=not FC.db.compact; FC:Layout() end}}
    for i,d in ipairs(defs) do local b=U:Button(self.actions,98,32,d[1],d[2],d[3]); b:SetPoint("LEFT",(i-1)*104,0) end
    self.status=U:Text(f,10,C.muted); self.status:SetPoint("BOTTOMLEFT",16,17)
    local credit=U:Text(f,9,C.muted,"by 0xgle  |  © 2026  |  All rights reserved"); credit:SetPoint("BOTTOMRIGHT",-25,17)
    self.resize=U:Button(f,18,18,"/",nil,nil); self.resize:SetPoint("BOTTOMRIGHT",-2,2)
    self.resize:SetScript("OnMouseDown",function() if not FC.db.locked then f:StartSizing("BOTTOMRIGHT") end end)
    self.resize:SetScript("OnMouseUp",function() f:StopMovingOrSizing(); FC.db.width=f:GetWidth(); FC.db.height=f:GetHeight() end)
    f:SetScript("OnSizeChanged",function() if FC.messages then FC:Layout() end end)
    f:SetScript("OnHide",function() FC.db.shown=false end)
    self.toast=U:Panel(UIParent); self.toast:SetSize(430,82); self.toast:SetPoint("TOP",0,-95); self.toast:SetFrameStrata("DIALOG")
    local ti=U:Icon(self.toast,"whisper",46); ti:SetPoint("LEFT",10,0)
    self.toastTitle=U:Text(self.toast,11,C.gold); self.toastTitle:SetPoint("TOPLEFT",68,-13)
    self.toastBody=U:Text(self.toast,12,C.text); self.toastBody:SetPoint("TOPLEFT",68,-32); self.toastBody:SetPoint("BOTTOMRIGHT",-15,10)
    self.toast:EnableMouse(true); self.toast:SetScript("OnMouseDown",function()
        FC:SetTab(FC.toastRecord and FC.toastRecord.isWhisper and "WHISPERS" or "ALERTS"); FC:Show(); FC.toast:Hide()
    end); self.toast:Hide()
    self:BuildMinimap(); self:ApplySettings(); self:UpdateRail(); self:Render(true)
end
function FC:Layout()
    if not self.messages then return end
    local w=(self.frame:GetWidth()-24-7*4)/8
    for i,tab in ipairs(self.tabs) do local b=self.tabButtons[tab]; b:ClearAllPoints(); b:SetPoint("LEFT",(i-1)*(w+4),0); b:SetWidth(w) end
    self.rail:SetShown(not self.db.compact)
    self.chatPanel:ClearAllPoints(); self.chatPanel:SetPoint("TOPLEFT"); self.chatPanel:SetPoint("BOTTOMLEFT")
    if self.db.compact then self.chatPanel:SetPoint("RIGHT",self.body,"RIGHT") else self.chatPanel:SetPoint("RIGHT",self.rail,"LEFT",-10,0) end
    self.filters:SetShown(self.currentTab=="LFG")
    self.messages:ClearAllPoints(); self.messages:SetPoint("TOPLEFT",12,self.currentTab=="LFG" and -45 or -12); self.messages:SetPoint("BOTTOMRIGHT",-12,38)
end
function FC:ApplySettings()
    if not self.frame then return end
    self.frame:SetSize(self.db.width,self.db.height); self.frame:SetScale(self.db.scale)
    if self.frame.SetBackdropColor then self.frame:SetBackdropColor(.06,.08,.10,self.db.opacity) end
    if self.chatPanel.SetBackdropColor then self.chatPanel:SetBackdropColor(.025,.035,.045,self.db.opacity) end
    self.messages:SetFont(STANDARD_TEXT_FONT,self.db.fontSize,"")
    self.lockButton.icon:SetTexture(M..(self.db.locked and "lock" or "unlock")..".tga")
    self.resize:SetShown(not self.db.locked); if self.minimap then self.minimap:SetShown(self.db.showMinimap) end
    self.historyLimit=self.db.historySize
    while #self.db.history>self.historyLimit do table.remove(self.db.history,1) end
    self:Layout(); self:Resume()
end
function FC:BuildMinimap()
    if not Minimap then return end
    local b=CreateFrame("Button","ForeverChatMinimapButton",Minimap); self.minimap=b
    b:SetSize(31,31); b:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-10,-35); b:SetFrameStrata("MEDIUM")
    local icon=U:Icon(b,"chat",31); icon:SetAllPoints()
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:SetScript("OnClick",function(_,button) if button=="RightButton" then FC:ToggleSettings() else FC:Toggle() end end)
    U:Tip(b,"ForeverChat","Left-click: show/hide. Right-click: settings. Icon is optional; disabled by default.")
end
