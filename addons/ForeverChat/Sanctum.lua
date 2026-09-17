-- ForeverChat / Sanctum presentation. Original addon by 0xgle.
local FC = ForeverChat
local MEDIA = "Interface\\AddOns\\ForeverChat\\Media\\"
local C = {
    bg={0.025,0.035,0.038,1}, panel={0.040,0.060,0.061,1},
    edge={0.26,0.29,0.25,1}, gold={0.84,0.68,0.40,1},
    text={0.90,0.92,0.88,1}, muted={0.56,0.66,0.65,1}, teal={0.24,0.83,0.76,1},
}
local tabs = {"ALL","GROUP","GUILD","WHISPERS","LFG","TRADE","ALERTS"}
local labels = {ALL="All",GROUP="Group",GUILD="Guild",WHISPERS="Whispers",LFG="LFG Radar",TRADE="Trade",ALERTS="Alerts"}
local icons = {ALL="Chat",GROUP="Group",GUILD="Guild",WHISPERS="Whispers",LFG="Radar",TRADE="Trade",ALERTS="Alerts"}
local function fill(parent, color, layer)
    local t=parent:CreateTexture(nil,layer or "BACKGROUND")
    t:SetColorTexture(unpack(color)); t:SetAllPoints(); return t
end
local function art(parent, name, layer)
    local t=parent:CreateTexture(nil,layer or "ARTWORK")
    t:SetTexture(MEDIA..name); return t
end
local function txt(parent,size,color,value)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetFont(STANDARD_TEXT_FONT,size,""); t:SetTextColor(unpack(color or C.text))
    t:SetJustifyH("LEFT");t:SetJustifyV("MIDDLE");t:SetText(value or "")
    return t
end
local function line(parent, y)
    local t=fill(parent,C.edge,"BORDER"); t:ClearAllPoints()
    t:SetPoint("TOPLEFT",12,y);t:SetPoint("TOPRIGHT",-12,y);t:SetHeight(1)
    return t
end
local function tooltip(button,title,body)
    button:HookScript("OnEnter",function(self) FC:Tooltip(self,title,body) end)
    button:HookScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

function FC:FitScale()
    if not self.frame then return end
    local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
    local fit=math.min((sw-24)/1000,(sh-24)/650)
    self.frame:SetScale(math.max(0.4,math.min(self.db.scale or 1,fit)))
end

function FC:LayoutMessages()
    if not self.messages then return end
    self.messages:ClearAllPoints()
    self.messages:SetPoint("TOPLEFT",self.body,"TOPLEFT",18,-40)
    local right=(self.db.compact or self.db.showRail==false) and -18 or -282
    self.messages:SetPoint("BOTTOMRIGHT",self.body,"BOTTOMRIGHT",right,42)
    if self.railToggle then self.railToggle.label:SetText(right==-18 and "SHOW SIDEBAR" or "HIDE SIDEBAR") end
end

function FC:UpdateJump()
    if not self.jump then return end
    if self.paused then
        local n=self.pendingMessages or 0
        self.jump.label:SetText(n>0 and (n.." NEW  /  BACK TO LIVE") or "BACK TO LIVE")
        self.jump:Show()
        self.feedHint:SetText("Reading history - incoming messages are held")
    else
        self.jump:Hide()
        self.feedHint:SetText("Scroll to browse  /  click a name to reply")
    end
end

function FC:BuildRow(parent, offset)
    local row=CreateFrame("Button",nil,parent)
    row:SetPoint("TOPLEFT",12,offset);row:SetPoint("TOPRIGHT",-12,offset);row:SetHeight(44)
    local bg=fill(row,C.panel)
    local edge=fill(row,{0.20,0.34,0.31,1},"BORDER");edge:ClearAllPoints()
    edge:SetPoint("TOPLEFT");edge:SetPoint("BOTTOMLEFT");edge:SetWidth(2)
    row.title=txt(row,12,C.text);row.title:SetPoint("TOPLEFT",10,-7);row.title:SetPoint("TOPRIGHT",-9,-7);row.title:SetHeight(15);row.title:SetWordWrap(false)
    row.sub=txt(row,10,C.muted);row.sub:SetPoint("TOPLEFT",10,-25);row.sub:SetPoint("TOPRIGHT",-9,-25);row.sub:SetHeight(13);row.sub:SetWordWrap(false)
    row:SetScript("OnClick",function(self) if self.sender then FC:OpenChat("/w "..self.sender.." ") end end)
    row:SetScript("OnEnter",function(self)
        bg:SetColorTexture(0.07,0.12,0.115,1)
        if self.sender then FC:Tooltip(self,self.sender,(self.tooltipText or "").."\n\nClick to whisper") end
    end)
    row:SetScript("OnLeave",function() bg:SetColorTexture(unpack(C.panel));if GameTooltip then GameTooltip:Hide() end end)
    return row
end

function FC:CopyView()
    if not self.copyPanel then
        local p=CreateFrame("Frame","ForeverChatCopy",self.frame)
        self.copyPanel=p;p:SetFrameLevel(self.frame:GetFrameLevel()+30)
        p:SetPoint("TOPLEFT",34,-104);p:SetPoint("BOTTOMRIGHT",-34,46);p:EnableMouse(true)
        fill(p,C.bg)
        local title=txt(p,18,C.gold,"Copy this conversation");title:SetPoint("TOPLEFT",20,-18)
        local hint=txt(p,11,C.muted,"Ctrl+A, Ctrl+C to copy. Escape closes this window.");hint:SetPoint("TOPLEFT",20,-44)
        local close=self:MakeButton(p,"CLOSE",72,28,function() p:Hide() end);close:SetPoint("TOPRIGHT",-16,-14)
        local scroll=CreateFrame("ScrollFrame",nil,p,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",20,-74);scroll:SetPoint("BOTTOMRIGHT",-38,20)
        local edit=CreateFrame("EditBox",nil,scroll);edit:SetMultiLine(true);edit:SetAutoFocus(false)
        edit:SetFont(STANDARD_TEXT_FONT,12,"");edit:SetWidth(840);edit:SetHeight(320)
        edit:SetScript("OnEscapePressed",function() p:Hide() end)
        edit:SetScript("OnTextChanged",function() scroll:UpdateScrollChildRect() end)
        edit:SetScript("OnCursorChanged",function(_,_,y,_,h)
            local pos=-y;local current=scroll:GetVerticalScroll()
            if pos<current then scroll:SetVerticalScroll(math.max(0,pos))
            elseif pos+h>current+scroll:GetHeight() then scroll:SetVerticalScroll(pos+h-scroll:GetHeight()) end
        end)
        p:SetScript("OnHide",function() edit:ClearFocus() end)
        scroll:SetScrollChild(edit);p.edit=edit
    end
    local out={}
    for _,r in ipairs(self.db.history) do
        if self:MatchesTab(r,self.currentTab) and self:MatchesSearch(r,self:GetSearch()) then
            local s=self:FormatRecord(r):gsub("|H.-|h(.-)|h","%1"):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t","")
            out[#out+1]=s
        end
    end
    self.copyPanel:Show();self.copyPanel.edit:SetText(table.concat(out,"\n"))
    self.copyPanel.edit:SetFocus();self.copyPanel.edit:HighlightText()
end

function FC:RegisterWithCore()
    if ForeverCore and ForeverCore.apiVersion==1 and ForeverCore.RegisterModule then
        ForeverCore:RegisterModule("ForeverChat",{
            title="ForeverChat",description="Sanctum chat, whispers and LFG Radar.",icon=4,
            open=function() FC:Toggle() end,
            settings=function() FC:Show();FC:ToggleSettings(true) end,
        })
    end
end

function FC:BuildUI()
    self.accentTextures={};self.accentFonts={}
    local f=CreateFrame("Frame","ForeverChatFrame",UIParent);self.frame=f
    f:SetSize(1000,650);f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",self.db.x or 30,self.db.y or 80)
    f:SetFrameStrata("MEDIUM");f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true)
    self.backdrop=fill(f,C.bg)
    local rim=fill(f,C.edge,"BORDER");rim:ClearAllPoints();rim:SetPoint("TOPLEFT");rim:SetPoint("TOPRIGHT");rim:SetHeight(1)
    local bottomRim=fill(f,C.edge,"BORDER");bottomRim:ClearAllPoints();bottomRim:SetPoint("BOTTOMLEFT");bottomRim:SetPoint("BOTTOMRIGHT");bottomRim:SetHeight(1)
    f:SetScript("OnHide",function() if FC.search then FC.search:ClearFocus() end;if FC.copyPanel then FC.copyPanel:Hide() end end)
    f:SetScript("OnShow",function() if FC.initialized then FC:UpdateRail() end end)
    f:RegisterEvent("DISPLAY_SIZE_CHANGED");f:RegisterEvent("UI_SCALE_CHANGED")
    f:SetScript("OnEvent",function() FC:FitScale() end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=15 then elapsed=0;FC:UpdateRail();FC:UpdateStatus() end
    end)

    local header=CreateFrame("Frame",nil,f);self.header=header
    header:SetPoint("TOPLEFT",1,-1);header:SetPoint("TOPRIGHT",-1,-1);header:SetHeight(88);header:EnableMouse(true)
    local hbg=art(header,"Sanctum","BACKGROUND");hbg:SetAllPoints();hbg:SetTexCoord(0,1,0.37,0.63)
    -- Art is decorative. Title and all controls are native WoW regions.
    local shade=fill(header,{0.015,0.025,0.026,0.38},"ARTWORK")
    local mark=art(header,"Chat");mark:SetSize(56,56);mark:SetPoint("LEFT",18,0)
    local brand=self:RegisterAccentFont(txt(header,23,C.gold,"FOREVER"));brand:SetPoint("TOPLEFT",88,-19)
    local name=txt(header,13,C.text,"C H A T");name:SetPoint("TOPLEFT",89,-46)
    local sep=fill(header,C.edge,"ARTWORK");sep:ClearAllPoints();sep:SetPoint("LEFT",258,0);sep:SetSize(1,36)
    local subtitle=txt(header,12,C.text,"THE SANCTUM");subtitle:SetPoint("TOPLEFT",278,-27)
    local sub=txt(header,10,C.muted,"Your people. Your adventures.");sub:SetPoint("TOPLEFT",278,-46)
    local author=txt(header,10,C.gold,"by 0xgle");author:SetPoint("TOPRIGHT",-200,-32)
    local version=txt(header,10,C.muted,"0.3.0 beta");version:SetPoint("TOPRIGHT",-200,-48)
    local settings=self:MakeButton(header,"SETTINGS",124,32,function() FC:ToggleSettings() end);settings:SetPoint("RIGHT",-54,0)
    local gear=art(settings,"Settings");gear:SetSize(24,24);gear:SetPoint("LEFT",6,0)
    settings.label:ClearAllPoints();settings.label:SetPoint("LEFT",36,0)
    local close=self:MakeButton(header,"X",30,32,function() FC:Hide() end);close:SetPoint("RIGHT",-14,0)
    tooltip(settings,"Settings","Appearance, alerts and chat preferences.")
    header:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" and not FC.db.locked then f:StartMoving() end end)
    header:SetScript("OnMouseUp",function()
        f:StopMovingOrSizing()
        -- Save a single stable anchor, even after WoW changes the drag anchor.
        local x=f:GetLeft();local y=f:GetBottom()
        if x and y then
            f:ClearAllPoints();f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",x,y)
            FC.db.x,FC.db.y=x,y
        end
    end)

    local tabsBar=CreateFrame("Frame",nil,f);self.tabsBar=tabsBar
    tabsBar:SetPoint("TOPLEFT",1,-90);tabsBar:SetPoint("TOPRIGHT",-1,-90);tabsBar:SetHeight(54)
    fill(tabsBar,{0.032,0.049,0.049,1})
    self.tabButtons={}
    local widths={110,116,110,134,139,111,118};local x=12
    for i,tab in ipairs(tabs) do
        local b=CreateFrame("Button",nil,tabsBar);b:SetSize(widths[i],44);b:SetPoint("LEFT",x,0);x=x+widths[i]+4
        b.activeBg=fill(b,{0.10,0.15,0.14,1});b.activeBg:Hide()
        local icon=art(b,icons[tab]);icon:SetSize(28,28);icon:SetPoint("LEFT",7,0)
        b.label=txt(b,11,C.muted,labels[tab]);b.label:SetPoint("LEFT",40,0)
        b.badge=txt(b,10,C.teal);b.badge:SetPoint("TOPRIGHT",-3,-2)
        b.line=self:RegisterAccentTexture(fill(b,C.gold,"ARTWORK"));b.line:ClearAllPoints()
        b.line:SetPoint("BOTTOMLEFT",6,0);b.line:SetPoint("BOTTOMRIGHT",-6,0);b.line:SetHeight(2)
        b:SetScript("OnClick",function() FC:SetTab(tab) end)
        b:SetScript("OnEnter",function() b.activeBg:Show() end)
        b:SetScript("OnLeave",function() if FC.currentTab~=tab then b.activeBg:Hide() end end)
        self.tabButtons[tab]=b
    end

    local body=CreateFrame("Frame",nil,f);self.body=body
    body:SetPoint("TOPLEFT",1,-145);body:SetPoint("BOTTOMRIGHT",-1,81)
    local stone=art(body,"Obsidian","BACKGROUND");stone:SetAllPoints();stone:SetAlpha(0.09)
    local feed=self:RegisterAccentFont(txt(body,11,C.gold,"CONVERSATION"));feed:SetPoint("TOPLEFT",18,-15)
    self.feedHint=txt(body,10,C.muted);self.feedHint:SetPoint("LEFT",feed,"RIGHT",16,0)
    local messages=CreateFrame("ScrollingMessageFrame",nil,body);self.messages=messages
    messages:SetFading(false);messages:SetMaxLines(500);messages:SetFont(STANDARD_TEXT_FONT,self.db.fontSize,"")
    messages:SetJustifyH("LEFT");messages:SetSpacing(self.db.messageSpacing);messages:EnableMouseWheel(true)
    messages:SetScript("OnMouseWheel",function(s,delta)
        if IsShiftKeyDown and IsShiftKeyDown() then
            if delta>0 then s:ScrollToTop() else s:ScrollToBottom() end
        elseif delta>0 then s:ScrollUp() else s:ScrollDown() end
        local was=FC.paused
        FC.paused=s:GetScrollOffset()>0
        if was and not FC.paused then FC:Render(true) end
        FC:UpdateJump();FC:UpdateStatus()
    end)
    if messages.SetHyperlinksEnabled then messages:SetHyperlinksEnabled(true) end
    messages:SetScript("OnHyperlinkClick",function(_,link,display,button) if SetItemRef then SetItemRef(link,display,button,ChatFrame1) end end)
    messages:SetScript("OnHyperlinkEnter",function(s,link)
        if GameTooltip and link:match("^item:") then GameTooltip:SetOwner(s,"ANCHOR_CURSOR");GameTooltip:SetHyperlink(link);GameTooltip:Show() end
    end)
    messages:SetScript("OnHyperlinkLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    self.jump=self:MakeButton(body,"BACK TO LIVE",218,26,function() FC:Render(true) end)
    self.jump:SetPoint("BOTTOMLEFT",18,8);self.jump:Hide()

    local rail=CreateFrame("Frame",nil,body);self.rail=rail
    rail:SetPoint("TOPRIGHT");rail:SetPoint("BOTTOMRIGHT");rail:SetWidth(264)
    fill(rail,{0.030,0.047,0.048,1})
    local divider=fill(rail,C.edge,"BORDER");divider:ClearAllPoints();divider:SetPoint("TOPLEFT");divider:SetPoint("BOTTOMLEFT");divider:SetWidth(1)
    local function section(name,icon,y)
        local a=art(rail,icon);a:SetPoint("TOPLEFT",12,y);a:SetSize(20,20)
        local t=FC:RegisterAccentFont(txt(rail,11,C.gold,name));t:SetPoint("TOPLEFT",40,y-4)
    end
    section("RECENT WHISPERS","Whispers",-11)
    self.whisperRows={self:BuildRow(rail,-40),self:BuildRow(rail,-88)}
    line(rail,-144)
    section("LFG RADAR","Radar",-153)
    self.lfgRows={self:BuildRow(rail,-184),self:BuildRow(rail,-232),self:BuildRow(rail,-280)}
    local note=txt(rail,10,C.muted,"Last 15 min  /  click to whisper");note:SetPoint("TOPLEFT",14,-334)
    local danger=self:MakeButton(rail,"REPORT DANGER",238,30,function() FC:OpenChat("/fc danger ") end)
    danger:SetPoint("BOTTOM",0,12);danger.label:SetTextColor(0.96,0.61,0.48)
    tooltip(danger,"Report a danger","Write a warning and confirm it in the native chat box. Shared only with ForeverChat users in your group or guild.")

    local bottom=CreateFrame("Frame",nil,f);self.bottom=bottom
    bottom:SetPoint("BOTTOMLEFT",1,1);bottom:SetPoint("BOTTOMRIGHT",-1,1);bottom:SetHeight(79)
    fill(bottom,{0.038,0.057,0.058,1});line(bottom,0)
    self.status=txt(bottom,10,C.muted);self.status:SetPoint("TOPLEFT",18,-13)
    local credit=txt(bottom,10,C.muted,"Forever Collection  /  by 0xgle");credit:SetPoint("TOPRIGHT",-18,-13)
    local open=self:MakeButton(bottom,"WRITE MESSAGE",130,30,function() FC:OpenChat("") end);open:SetPoint("BOTTOMLEFT",18,12)
    local copy=self:MakeButton(bottom,"COPY",65,30,function() FC:CopyView() end);copy:SetPoint("LEFT",open,"RIGHT",8,0)
    tooltip(copy,"Copy view","Copy the messages matching your current tab and search.")
    self.railToggle=self:MakeButton(bottom,"HIDE SIDEBAR",120,30,function()
        FC.db.compact=not(FC.db.compact or FC.db.showRail==false);FC.db.showRail=true;FC:ApplyAppearance()
    end);self.railToggle:SetPoint("LEFT",copy,"RIGHT",8,0)
    local lock=self:MakeButton(bottom,self.db.locked and "UNLOCK" or "LOCK",70,30,function(b)
        FC.db.locked=not FC.db.locked;b.label:SetText(FC.db.locked and "UNLOCK" or "LOCK")
    end);lock:SetPoint("LEFT",self.railToggle,"RIGHT",8,0)
    tooltip(lock,"Position lock","Lock or unlock dragging the title bar.")
    local search=CreateFrame("EditBox",nil,bottom);self.search=search
    search:SetPoint("BOTTOMRIGHT",-50,12);search:SetSize(245,30);search:SetAutoFocus(false)
    search:SetFont(STANDARD_TEXT_FONT,12,"");search:SetTextInsets(10,10,0,0);fill(search,C.bg)
    search:SetMaxLetters(100)
    local hint=txt(search,11,C.muted,"Search this conversation...");hint:SetPoint("LEFT",10,0)
    search:SetScript("OnTextChanged",function(s)
        hint:SetShown(s:GetText()=="");FC:Render(true)
    end)
    search:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)
    search:SetScript("OnEnterPressed",function(s) s:ClearFocus() end)
    local clear=self:MakeButton(bottom,"X",26,30,function() search:SetText("");search:ClearFocus() end)
    clear:SetPoint("LEFT",search,"RIGHT",6,0)

    local toast=CreateFrame("Button","ForeverChatToast",UIParent);self.toast=toast
    toast:SetSize(470,76);toast:SetPoint("TOP",UIParent,"TOP",0,-90);toast:SetFrameStrata("DIALOG")
    fill(toast,C.bg);local toastArt=art(toast,"Alerts");toastArt:SetSize(44,44);toastArt:SetPoint("LEFT",12,0)
    self.toastTitle=self:RegisterAccentFont(txt(toast,11,C.gold));self.toastTitle:SetPoint("TOPLEFT",70,-14)
    self.toastBody=txt(toast,12,C.text);self.toastBody:SetPoint("TOPLEFT",70,-33);self.toastBody:SetPoint("BOTTOMRIGHT",-14,12)
    toast:SetScript("OnClick",function() FC:SetTab("ALERTS");FC:Show();FC:ToggleSettings(false);toast:Hide() end);toast:Hide()
    self:BuildSettings(f);self:ApplyAppearance();self:UpdateRail();self:UpdateStatus();self:UpdateJump()
end

BINDING_HEADER_FOREVERCHAT="ForeverChat"
BINDING_NAME_FOREVERCHAT_TOGGLE="Toggle ForeverChat"
BINDING_NAME_FOREVERCHAT_SETTINGS="ForeverChat settings"
