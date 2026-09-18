local FC=ForeverChat
local U=FC.UI
local gold={.94,.76,.42}; local muted={.57,.65,.69}
function FC:ToggleSettings()
    if not self.settingsFrame then self:BuildSettings() end
    if self.settingsFrame:IsShown() then self.settingsFrame:Hide() else self.settingsFrame:Show(); self:RefreshSettings() end
end
function FC:BuildSettings()
    local f=U:Panel(UIParent); self.settingsFrame=f; _G.ForeverChatSettings=f
    f:SetSize(680,520); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:SetClampedToScreen(true)
    table.insert(UISpecialFrames,"ForeverChatSettings")
    local emblem=U:Icon(f,"settings",48); emblem:SetPoint("TOPLEFT",17,-13)
    local title=U:Text(f,21,gold,"Make it yours"); title:SetPoint("TOPLEFT",76,-21)
    local sub=U:Text(f,11,muted,"ForeverChat settings  /  changes apply immediately"); sub:SetPoint("TOPLEFT",77,-47)
    local close=U:Button(f,30,30,"","close",function() f:Hide() end); close:SetPoint("TOPRIGHT",-14,-17)
    self.settingChecks={}; self.settingValues={}
    local function check(key,label,x,y)
        local b=U:Button(f,294,29,label,nil,function()
            FC.db[key]=not FC.db[key]; FC:ApplySettings(); FC:RefreshSettings()
        end); b:SetPoint("TOPLEFT",x,y); b.label:ClearAllPoints(); b.label:SetPoint("LEFT",32,0); b.label:SetPoint("RIGHT",-6,0)
        b.state=U:Text(b,13,gold); b.state:SetPoint("LEFT",8,0); FC.settingChecks[key]=b
    end
    local function step(key,label,x,y,values,format)
        local l=U:Text(f,11,muted,label); l:SetPoint("TOPLEFT",x,y)
        local b=U:Button(f,294,29,"",nil,function()
            local n=1
            for i,v in ipairs(values) do if math.abs((tonumber(FC.db[key]) or 0)-v)<.001 then n=i%#values+1; break end end
            FC.db[key]=values[n]; FC:ApplySettings(); FC:RefreshSettings()
        end); b:SetPoint("TOPLEFT",x,y-17); FC.settingValues[key]={button=b,format=format}
        U:Tip(b,label,"Click to cycle available values.")
    end
    check("timestamps","Show timestamps",26,-88)
    check("classColors","Class colors for player names",26,-120)
    check("compact","Compact view (hide sidebar)",26,-152)
    check("locked","Lock position and size",26,-184)
    check("toasts","Whisper and mention notifications",356,-88)
    check("sound","Notification sound",356,-120)
    check("combatQuiet","Silence notifications during combat",356,-152)
    check("showMinimap","Show ForeverChat minimap icon",356,-184)
    step("fontSize","MESSAGE TEXT",26,-233,{11,12,13,14,16,18,20},function(v) return v.." px" end)
    step("scale","WINDOW SCALE",356,-233,{.65,.75,.85,1,1.15,1.3,1.4},function(v) return math.floor(v*100+.5).."%" end)
    step("opacity","BACKGROUND OPACITY",26,-294,{.55,.7,.85,.97,1},function(v) return math.floor(v*100+.5).."%" end)
    step("historySize","HISTORY LIMIT",356,-294,{200,400,800,1200,2000},function(v) return v.." messages" end)
    step("lfgMinutes","LFG EXPIRY",26,-355,{2,5,10,15,30},function(v) return v.." minutes" end)
    step("duplicateSeconds","HIDE REPEATED MESSAGES",356,-355,{0,4,8,15,30},function(v) return v==0 and "Off" or (v.." seconds") end)
    check("saveHistory","Keep history after logout",26,-416)
    local filters=U:Button(f,142,29,"Word filters","search",function() FC:OpenFilters() end); filters:SetPoint("TOPLEFT",356,-416)
    local reset=U:Button(f,142,29,"Reset layout","unlock",function() FC:HandleSlash("reset"); FC:RefreshSettings() end); reset:SetPoint("TOPLEFT",508,-416)
    local foot=U:Text(f,10,muted,"by 0xgle  |  Forever family  |  0.2.0-beta1"); foot:SetPoint("BOTTOMLEFT",26,22)
    local note=U:Text(f,9,muted,"Messages stay on this computer."); note:SetPoint("BOTTOMRIGHT",-26,22)
    f:Hide()
end
function FC:RefreshSettings()
    for key,b in pairs(self.settingChecks) do b.state:SetText(self.db[key] and "[x]" or "[ ]") end
    for key,v in pairs(self.settingValues) do v.button.label:SetText(v.format(self.db[key]).."   >") end
end
function FC:TextDialog(title,body,save)
    if not self.textDialog then
        local f=U:Panel(UIParent); self.textDialog=f; _G.ForeverChatTextDialog=f
        f:SetSize(620,430); f:SetPoint("CENTER"); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:EnableMouse(true)
        table.insert(UISpecialFrames,"ForeverChatTextDialog")
        f.title=U:Text(f,19,gold); f.title:SetPoint("TOPLEFT",22,-22)
        local close=U:Button(f,30,30,"","close",function() f:Hide() end); close:SetPoint("TOPRIGHT",-14,-14)
        f.note=U:Text(f,11,muted); f.note:SetPoint("TOPLEFT",22,-53)
        local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",22,-80); scroll:SetPoint("BOTTOMRIGHT",-42,55)
        local edit=CreateFrame("EditBox",nil,scroll); f.edit=edit
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFont(STANDARD_TEXT_FONT,12,""); edit:SetWidth(550); edit:SetHeight(270); edit:SetTextInsets(5,5,5,5)
        scroll:SetScrollChild(edit); edit:SetScript("OnEscapePressed",function() f:Hide() end)
        f.save=U:Button(f,120,29,"Save filters","star",function() if f.callback then f.callback(f.edit:GetText()) end; f:Hide() end); f.save:SetPoint("BOTTOMRIGHT",-22,15)
        f:Hide()
    end
    local f=self.textDialog; f.title:SetText(title); f.callback=save
    f.note:SetText(save and "One word or phrase per line. Filtering affects ForeverChat only." or "Ctrl+A, Ctrl+C to copy. This is the current filtered view.")
    f.save:SetShown(save~=nil); f.edit:SetText(body); f:Show(); f.edit:SetFocus()
    if not save then f.edit:HighlightText() end
end
function FC:CopyView()
    local out={}
    for _,r in ipairs(self:ViewRecords()) do
        if self:VisibleRecord(r) then out[#out+1]="["..self:FormatTime(r.t).."] "..(r.sender or "")..": "..self:Plain(r.msg) end
    end
    self:TextDialog("Copy conversation",table.concat(out,"\n"),nil)
end
function FC:OpenFilters()
    self:TextDialog("Word filters",table.concat(self.db.blockedWords,"\n"),function(value)
        local words={}; local seen={}
        for line in value:gmatch("[^\r\n]+") do
            line=line:match("^%s*(.-)%s*$"):lower()
            if line~="" and not seen[line] and #words<50 then words[#words+1]=line:sub(1,100); seen[line]=true end
        end
        FC.db.blockedWords=words; FC:Print("Word filters updated for incoming messages.")
    end)
end
BINDING_HEADER_FOREVERCHAT="ForeverChat"
BINDING_NAME_FOREVERCHAT_TOGGLE="Show / hide ForeverChat"
