local _,F=...
local T=F.T
local W,H,CW=980,640,716
local pages={{"Sanctum",1},{"Addons",5},{"Profiles",7},{"Diagnostics",8},{"Appearance",6},{"About",12}}
function F:BuildUI()
    if self.frame then return end
    local f=T:Panel(UIParent,W,H,0,0,{.018,.035,.04,1})
    self.frame=f; _G.ForeverCoreWindow=f
    f:ClearAllPoints(); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:Hide()
    UISpecialFrames[#UISpecialFrames+1]="ForeverCoreWindow"
    self:ApplyScale()
    local pos=self.db.settings.position
    if type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number" then
        f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",pos.x,pos.y)
    end
    local top=CreateFrame("Frame",nil,f); top:SetPoint("TOPLEFT"); top:SetSize(W-48,68)
    top:EnableMouse(true); top:RegisterForDrag("LeftButton")
    top:SetScript("OnDragStart",function() f:StartMoving() end)
    top:SetScript("OnDragStop",function()
        f:StopMovingOrSizing(); local x,y=f:GetCenter(); local ux,uy=UIParent:GetCenter()
        local s=f:GetScale(); self.db.settings.position={x=x-ux/s,y=y-uy/s}
    end)
    T:Icon(f,1,44,20,12); T:Text(f,"FOREVER",18,78,16,150,T.gold)
    T:Text(f,"C O R E",10,79,40,130,T.muted)
    T:Text(f,"THE SANCTUM",11,244,27,280,T.muted)
    T:Button(f,"X",28,28,W-42,18,function() f:Hide() end)
    local side=T:Panel(f,202,510,14,76,{.027,.05,.055,1})
    T:Text(side,"YOUR COLLECTION",10,16,18,175,T.gold)
    self.nav={}
    for i,p in ipairs(pages) do
        local name=p[1]
        local b=T:Button(side,"",180,43,11,45+(i-1)*53,function() self.page=name; self:Render() end)
        T:Icon(b,p[2],28,8,7); T:Text(b,name,13,46,14,126)
        self.nav[name]=b
    end
    T:Text(side,"Built for your adventures.",11,16,431,172,T.muted)
    T:Text(side,"by 0xgle",13,16,458,170,T.gold)
    self.content=CreateFrame("Frame",nil,f); self.content:SetSize(CW,502); self.content:SetPoint("TOPLEFT",240,-82)
    self.footer=T:Text(f,"",11,24,609,570,T.muted)
    self.discard=T:Button(f,"Discard",82,30,638,597,function() self:Discard() end)
    self.apply=T:Button(f,"Review",108,30,728,597,function() self:ReviewChanges() end,true)
    self.reload=T:Button(f,"Reload UI",112,30,844,597,function() self:Reload() end)
    f:SetScript("OnShow",function() self:Render() end)
    self.page="Sanctum"
end
function F:ApplyScale()
    if not self.frame then return end
    local fit=math.min((UIParent:GetWidth()-30)/W,(UIParent:GetHeight()-30)/H)
    self.frame:SetScale(math.min(self.db.settings.scale,fit))
end
function F:Toggle()
    if not self.db then return end
    self:BuildUI(); self.frame:SetShown(not self.frame:IsShown())
end
function F:NewPage()
    if self.pageFrame then self.pageFrame:Hide() end
    self.pageCache=self.pageCache or {}
    -- Each page is built once. Row pools prevent widget accumulation on refresh.
    local p=self.pageCache[self.page]
    if not p then
        p=CreateFrame("Frame",nil,self.content); p:SetAllPoints(); self.pageCache[self.page]=p
    end
    p:Show(); self.pageFrame=p; return p
end
function F:Render()
    if not self.frame then return end
    self:Scan()
    local count=0; for _ in pairs(self.pending) do count=count+1 end
    self.footer:SetText(InCombatLockdown() and "Combat lock active  /  Changes are paused" or
        (count>0 and (count.." staged changes  /  Review before applying") or
        (self.char.reload and "Changes applied  /  Reload UI to finish" or "ForeverCore 1.0.3-rc4  /  by 0xgle")))
    self.discard:SetShown(count>0); self.apply:SetShown(count>0)
    for name,b in pairs(self.nav) do b:SetBackdropBorderColor(unpack(name==self.page and T.gold or {.18,.25,.25})) end
    local p=self:NewPage()
    if self.page=="Sanctum" then self:RenderHome(p)
    elseif self.page=="Addons" then self:RenderAddons(p)
    elseif self.page=="Profiles" then self:RenderProfiles(p)
    elseif self.page=="Diagnostics" then self:RenderDiagnostics(p)
    elseif self.page=="Appearance" then self:RenderAppearance(p)
    else self:RenderAbout(p) end
end
function F:Header(p,title,subtitle)
    T:Text(p,title,25,0,0,CW,T.gold); T:Text(p,subtitle,12,0,35,CW,T.muted)
end
function F:RenderHome(p)
    if not p.built then
        p.built=true
        local hero=T:Panel(p,CW,218,0,0)
        local art=hero:CreateTexture(nil,"BACKGROUND"); art:SetAllPoints(); art:SetTexture(self.media.."Sanctum.tga")
        art:SetTexCoord(0,1,.06,.90)
        T:Text(hero,"F O R E V E R   C O L L E C T I O N",10,24,24,400,T.teal)
        T:Text(hero,"One core.\nEvery adventure.",30,24,53,410,T.gold)
        T:Text(hero,"Your addons. Your setup. Your world.",13,24,139,415)
        T:Button(hero,"Explore your addons",174,31,24,169,function() self.page="Addons"; self:Render() end,true)
        p.stats={}
        for i,v in ipairs({{"INSTALLED",1},{"LOADED",10},{"PROFILE",7}}) do
            local card=T:Panel(p,230,69,(i-1)*243,231)
            T:Icon(card,v[2],40,12,14); T:Text(card,v[1],10,66,12,150,T.muted)
            p.stats[i]=T:Text(card,"",18,66,32,150,T.gold); p.stats[i]:SetMaxLines(1)
        end
        T:Text(p,"QUICK LAUNCH",11,0,322,500,T.gold)
        p.quick={}
        for i=1,3 do
            local c=T:Panel(p,230,115,(i-1)*243,348)
            c.icon=T:Icon(c,1,42,12,12); c.title=T:Text(c,"",14,66,17,148); c.title:SetMaxLines(1)
            c.status=T:Text(c,"",10,66,39,148,T.muted)
            c.button=T:Button(c,"Open",204,28,13,72,function() if c.id then F:OpenModule(c.id) end end,true)
            p.quick[i]=c
        end
        T:Text(p,"Manage installed addons locally. New downloads are installed outside the game.",11,0,480,CW,T.muted)
    end
    local installed,loaded=0,0; local quick={}
    for _,a in ipairs(self.addons) do
        if a.suite then
            installed=installed+1; if a.loaded then loaded=loaded+1 end
            if a.id~=self.name then quick[#quick+1]=a end
        end
    end
    p.stats[1]:SetText(installed.." addons"); p.stats[2]:SetText(loaded.." active")
    p.stats[3]:SetText(self.char.profile or "Custom")
    for i,c in ipairs(p.quick) do
        local a=quick[i]; c.id=a and a.id
        c.title:SetText(a and a.title or "Room to grow")
        c.status:SetText(a and (a.loaded and "Ready for your adventure" or "Not loaded") or "Your next Forever addon")
        local idx=(a and a.spec and a.spec.icon or 16)-1; local x,y=idx%4,math.floor(idx/4)
        c.icon:SetTexCoord(x/4+.008,(x+1)/4-.008,y/4+.008,(y+1)/4-.008)
        c.button:SetShown(a~=nil and a.spec~=nil and a.spec.open~=nil)
    end
end
function F:RenderAddons(p)
    if not p.built then
        p.built=true; self:Header(p,"Your addons","Stage addon state changes and toggle detected minimap launchers directly from the list.")
        p.search=T:Edit(p,268,32,0,65); p.search:SetMaxLetters(60)
        T:Text(p,"Search name",10,8,52,250,T.muted)
        p.search:SetScript("OnTextChanged",function() p.offset=0; F:UpdateAddonRows(p) end)
        p.scope="suite"; p.offset=0
        p.scopeButton=T:Button(p,"Forever only",134,32,280,65,function()
            p.scope=p.scope=="suite" and "all" or "suite"; p.scopeButton.label:SetText(p.scope=="suite" and "Forever only" or "All installed")
            p.offset=0; F:UpdateAddonRows(p)
        end)
        p.favButton=T:Button(p,"Favorites: off",134,32,426,65,function()
            p.onlyFav=not p.onlyFav; p.favButton.label:SetText(p.onlyFav and "Favorites: on" or "Favorites: off")
            p.offset=0; F:UpdateAddonRows(p)
        end)
        T:Button(p,"Refresh",144,32,572,65,function() F:Scan(); F:UpdateAddonRows(p) end)
        p.rows={}
        for i=1,5 do
            local row=T:Panel(p,CW,64,0,111+(i-1)*70)
            row.icon=T:Icon(row,1,44,10,10)
            row.title=T:Text(row,"",14,66,10,232); row.title:SetMaxLines(1)
            row.info=T:Text(row,"",10,66,33,232,T.muted)
            row.favorite=T:Button(row,"*",27,27,304,19,function()
                self.db.favorites[row.id]=not self.db.favorites[row.id]; self:Scan(); self:UpdateAddonRows(p)
            end)
            T:Tip(row.favorite,"Favorite","Pin this addon to the top of the list.")
            row.minimap=T:Check(row,"Minimap",92,27,340,19,function(visible)
                if not row.id then return end
                if row.id==self.name then
                    self.db.settings.minimap=visible; self:UpdateMinimap(); self:Refresh()
                else
                    self:SetAddonMinimapIconVisible(row.id,visible)
                end
            end)
            T:Tip(row.minimap,"Minimap icon","Show or hide this addon's detected minimap launcher. Uses the same setting as Appearance > Minimap addon icons.")
            row.open=T:Button(row,"Open",60,27,438,19,function() self:OpenModule(row.id) end)
            row.settings=T:Button(row,"Config",60,27,504,19,function() self:OpenModule(row.id,true) end)
            row.state=T:Button(row,"",135,27,570,19,function() self:Stage(row.id,not self:Desired(row.id)) end,true)
            row:EnableMouse(true)
            row:SetScript("OnEnter",function()
                local a=self.byID[row.id]; if not a then return end
                GameTooltip:SetOwner(row,"ANCHOR_RIGHT"); GameTooltip:SetText(a.title)
                GameTooltip:AddLine(a.notes,.8,.85,.83,true)
                GameTooltip:AddLine("Folder: "..a.id,.6,.7,.7,true)
                if #a.deps>0 then GameTooltip:AddLine("Requires: "..table.concat(a.deps,", "),1,.8,.4,true) end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave",function() GameTooltip:Hide() end)
            p.rows[i]=row
        end
        p.empty=T:Text(p,"No addons match this view.",16,18,145,650,T.muted)
        p.count=T:Text(p,"",11,0,481,440,T.muted)
        T:Button(p,"Previous",91,28,518,471,function() p.offset=math.max(0,p.offset-5); self:UpdateAddonRows(p) end)
        T:Button(p,"Next",91,28,625,471,function()
            if p.offset+5<#p.filtered then p.offset=p.offset+5 end; self:UpdateAddonRows(p)
        end)
        p:EnableMouseWheel(true); p:SetScript("OnMouseWheel",function(_,d)
            p.offset=math.max(0,math.min(math.max(0,math.ceil(#p.filtered/5)-1)*5,p.offset-d*5)); self:UpdateAddonRows(p)
        end)
    end
    self:UpdateAddonRows(p)
end
function F:UpdateAddonRows(p)
    local query=(p.search:GetText() or ""):lower(); local list={}
    for _,a in ipairs(self.addons) do
        if (p.scope=="all" or a.suite) and (not p.onlyFav or self.db.favorites[a.id]) and
            (a.id:lower():find(query,1,true) or a.title:lower():find(query,1,true)) then list[#list+1]=a end
    end
    p.filtered=list; p.offset=math.min(p.offset,math.max(0,math.ceil(#list/5)-1)*5)
    self:ScanMinimapButtons()
    local minimapOwners={}
    for _,key in pairs(self.minimapButtonOwners or {}) do minimapOwners[key]=true end
    for i,row in ipairs(p.rows) do
        local a=list[p.offset+i]; row:SetShown(a~=nil)
        if a then
            row.id=a.id; row.title:SetText(a.title)
            row.info:SetText(a.version.."  /  "..(a.loaded and "Loaded" or (a.enabled and (a.lod and "On demand" or "Not loaded") or "Disabled")))
            row.favorite.label:SetTextColor(unpack(self.db.favorites[a.id] and T.gold or T.muted))
            row.open:SetShown(a.id~=self.name and a.spec~=nil and a.spec.open~=nil)
            row.settings:SetShown(a.spec~=nil and a.spec.settings~=nil)
            local isCore=a.id==self.name
            local iconKnown=isCore or minimapOwners[a.id] or self.db.settings.minimapIconOverrides[a.id]~=nil
            row.minimap:SetEnabled(iconKnown)
            row.minimap.label:SetTextColor(unpack(iconKnown and T.text or T.muted))
            row.minimap:SetValue(iconKnown and (isCore and self.db.settings.minimap or self:GetAddonMinimapIconVisible(a.id)) or false)
            local staged=self.pending[a.id]~=nil
            row.state.label:SetText(a.id==self.name and "Core / protected" or (staged and "> " or "")..(self:Desired(a.id) and "Enabled" or "Disabled"))
            row.state:SetEnabled(a.id~=self.name)
            local idx=(a.spec and a.spec.icon or 16)-1; local x,y=idx%4,math.floor(idx/4)
            row.icon:SetTexCoord(x/4+.008,(x+1)/4-.008,y/4+.008,(y+1)/4-.008)
        end
    end
    p.empty:SetShown(#list==0); p.count:SetText(#list.." addons  /  Page "..(math.floor(p.offset/5)+1).." of "..math.max(1,math.ceil(#list/5)))
end
function F:RenderProfiles(p)
    if not p.built then
        p.built=true; self:Header(p,"Loadouts for every journey","Profiles store addon enabled states. They do not copy the addons' internal settings.")
        T:Text(p,"NEW PROFILE NAME",10,0,63,350,T.gold)
        p.name=T:Edit(p,260,32,0,82); p.name:SetMaxLetters(40)
        p.scope="suite"
        p.scopeBtn=T:Button(p,"Scope: Forever",142,32,272,82,function()
            p.scope=p.scope=="suite" and "all" or "suite"; p.scopeBtn.label:SetText(p.scope=="suite" and "Scope: Forever" or "Scope: all addons")
        end)
        T:Button(p,"Save new",132,32,426,82,function()
            local ok,msg=self:SaveProfile(p.name:GetText(),p.scope)
            if not ok then self:Print(msg) else p.name:SetText(""); self:RenderProfiles(p) end
        end,true)
        T:Button(p,"Import",146,32,570,82,function()
            self:TextDialog("Import profile","Paste an FCORE1 profile. Import saves it; use Stage to apply it.","",function(txt)
                local ok,msg=self:ImportProfile(txt); if not ok then return false,msg end
                self:Refresh(); return true
            end)
        end)
        p.rows={}; p.offset=0
        for i=1,5 do
            local row=T:Panel(p,CW,56,0,130+(i-1)*61)
            T:Icon(row,7,32,10,12); row.title=T:Text(row,"",14,54,10,285); row.title:SetMaxLines(1)
            row.info=T:Text(row,"",10,54,32,285,T.muted)
            T:Button(row,"Stage",83,28,349,14,function()
                local profile=self.db.profiles[row.id]
                if profile and self:StageSnapshot(profile.states) then self.stagedProfile=row.id; self:ReviewChanges() end
            end,true)
            T:Button(row,"Export",83,28,442,14,function() self:TextDialog("Export profile","Ctrl+A, Ctrl+C to copy. No executable code is included.",self:ExportProfile(row.id)) end)
            T:Button(row,"Delete",83,28,535,14,function()
                local name=row.id
                self:Confirm("Delete profile?",name.."\nThis removes the saved loadout, not addon data.",function()
                    self.db.profiles[name]=nil; if self.char.profile==name then self.char.profile=nil end; self:Refresh()
                end)
            end)
            p.rows[i]=row
        end
        p.empty=T:Text(p,"Save your first loadout above.\nTry names such as Hardcore, Gathering or Raid.",16,18,159,660,T.muted)
        p.count=T:Text(p,"",11,0,457,450,T.muted)
        T:Button(p,"Previous",91,28,518,449,function() p.offset=math.max(0,p.offset-5); self:RenderProfiles(p) end)
        T:Button(p,"Next",91,28,625,449,function() if p.offset+5<#p.list then p.offset=p.offset+5 end; self:RenderProfiles(p) end)
        T:Text(p,"Saved account-wide. Applying changes only affects your current character.",11,0,490,CW,T.muted)
    end
    local list={}; for name in pairs(self.db.profiles) do list[#list+1]=name end; table.sort(list)
    p.list=list; p.offset=math.min(p.offset,math.max(0,math.ceil(#list/5)-1)*5)
    for i,row in ipairs(p.rows) do
        local name=list[p.offset+i]; row:SetShown(name~=nil)
        if name then
            row.id=name; local profile=self.db.profiles[name]; local n=0; for _ in pairs(profile.states) do n=n+1 end
            row.title:SetText(name); row.info:SetText(n.." addon states  /  "..(profile.scope=="all" and "All addons" or "Forever collection"))
        end
    end
    p.empty:SetShown(#list==0); p.count:SetText(#list.." saved profiles  /  Current: "..(self.char.profile or "Custom"))
end
function F:RenderDiagnostics(p)
    if not p.built then
        p.built=true; self:Header(p,"Know your collection","Manual measurements. No background polling, global error hooks or forced garbage collection.")
        T:Button(p,"Measure memory",157,32,0,65,function() self:SampleMemory(); self:RenderDiagnostics(p) end,true)
        T:Button(p,"Copy report",137,32,169,65,function() self:TextDialog("Diagnostic report","Copy this text when reporting a problem. No character name is included.",self:DiagnosticReport()) end)
        T:Button(p,"Undo last apply",154,32,318,65,function()
            if not self.db.undo then self:Print("No previous apply to restore."); return end
            if self:StageSnapshot(self.db.undo) then self:ReviewChanges() end
        end)
        T:Button(p,"Core-only mode",232,32,484,65,function()
            self:Confirm("Stage Core-only mode?","Other Forever addons will be disabled after Apply + Reload.\nTheir saved data is retained. Non-Forever addons are left as configured.",function()
                local states=self:Snapshot("suite"); for id in pairs(states) do states[id]=false end
                if self:StageSnapshot(states) then self:ReviewChanges() end
            end)
        end)
        local box=T:Panel(p,CW,225,0,111)
        p.summary=T:Text(box,"",12,16,15,684)
        T:Text(p,"RECENT ACTIVITY",10,0,358,CW,T.gold)
        p.history=T:Text(p,"",12,0,382,CW,T.muted)
    end
    local lines={"Last memory sample: "..(self.sampleTime or "not measured"),""}
    local count,total=0,0
    for _,a in ipairs(self.addons) do
        if a.suite then
            local kb=self.memory and self.memory[a.id] or 0; total=total+kb; count=count+1
            if count<=7 then lines[#lines+1]=a.id.."  |  "..a.version.."  |  "..(a.loaded and "loaded" or "not loaded").."  |  "..(self.sampleTime and string.format("%.0f KB",kb) or "--") end
        end
    end
    if count>7 then lines[#lines+1]="More addons are included in Copy report." end
    lines[#lines+1]="\nSuite memory: "..string.format("%.2f MB",total/1024).."  /  Core callback errors: "..#self.errors
    p.summary:SetText(table.concat(lines,"\n"))
    local hist={}; for i=1,5 do hist[i]=self.db.history[i] end
    p.history:SetText(#hist>0 and table.concat(hist,"\n") or "No changes yet. Your next adventure starts here.")
end
function F:RenderAppearance(p)
    if not p.built then
        p.built=true; self:Header(p,"Make yourself at home","The Sanctum theme keeps artwork behind the controls and text above it.")
        local box=T:Panel(p,CW,133,0,70)
        T:Icon(box,6,68,20,26); T:Text(box,"Interface scale",18,111,25,570,T.gold)
        p.scale=T:Text(box,"",13,111,55,570,T.muted)
        T:Button(box,"Smaller",106,28,111,86,function() self.db.settings.scale=math.max(.65,self.db.settings.scale-.05); self:ApplyScale(); self:RenderAppearance(p) end)
        T:Button(box,"Larger",106,28,229,86,function() self.db.settings.scale=math.min(1.25,self.db.settings.scale+.05); self:ApplyScale(); self:RenderAppearance(p) end)
        T:Button(box,"Reset position",150,28,347,86,function()
            self.db.settings.position=nil; self.db.settings.scale=1
            self.frame:ClearAllPoints(); self.frame:SetPoint("CENTER"); self:ApplyScale(); self:RenderAppearance(p)
        end)
        local map=T:Panel(p,CW,168,0,218)
        T:Icon(map,5,60,23,25); T:Text(map,"Minimap launcher",18,111,21,570,T.gold)
        T:Text(map,"Left-click to open. Right-click for Addons. Drag to reposition.",12,111,50,570,T.muted)
        p.map=T:Button(map,"",182,28,111,73,function()
            self.db.settings.minimap=not self.db.settings.minimap; self:UpdateMinimap(); self:RenderAppearance(p)
        end)
        p.otherIcons=T:Button(map,"",220,28,305,73,function()
            self:SetOtherMinimapButtonsHidden(not self.db.settings.hideOtherMinimapButtons); self:RenderAppearance(p)
        end)
        p.manageIcons=T:Button(map,"Choose individual addon icons",414,28,111,108,function() self:OpenMinimapIconManager() end,true)
        p.iconSummary=T:Text(map,"",11,111,143,570,T.muted)
        T:Text(p,"Keyboard shortcut",18,0,405,CW,T.gold)
        T:Text(p,"Set a key in the game's Key Bindings > AddOns > ForeverCore.\nNo existing game bindings are replaced.\nUse /fc or /forevercore at any time. Press Escape to close the window.",13,0,438,CW,T.muted)
    end
    p.scale:SetText(string.format("Requested: %d%%  /  Automatically fits your screen",math.floor(self.db.settings.scale*100+.5)))
    p.map.label:SetText(self.db.settings.minimap and "Hide Core button" or "Show Core button")
    p.otherIcons.label:SetText(self.db.settings.hideOtherMinimapButtons and "Default others: hidden" or "Default others: visible")
    local groups=self:GetMinimapIconGroups(); local visible=0
    for _,g in ipairs(groups) do if self:GetAddonMinimapIconVisible(g.key) then visible=visible+1 end end
    p.iconSummary:SetText(#groups.." addon launchers detected  /  "..visible.." currently allowed on the minimap")
end
function F:RenderAbout(p)
    if p.built then return end; p.built=true
    self:Header(p,"ForeverCore","The Sanctum  /  1.0.3-rc4")
    T:Icon(p,1,126,0,80)
    T:Text(p,"A home for every Forever addon.",23,151,96,555,T.gold)
    T:Text(p,"Created by 0xgle\nCopyright 2026 0xgle. All rights reserved.",14,151,139,555)
    T:Text(p,"BUILT TO GROW",11,0,245,CW,T.teal)
    T:Text(p,"Discover installed Forever addons automatically. Launch supported modules, save addon loadouts and review every change before a reload.\n\nForeverBags and ForeverGather have built-in launchers. Other addons can register with the documented ForeverCore API.\n\nThis release targets Classic Era 1.15.9. Other clients, including Forever, need an in-game compatibility check. The addon cannot download or update files from the internet.",14,0,274,CW,T.muted)
    T:Text(p,"Original UI code and AI-assisted original artwork. No external runtime libraries required.",11,0,466,CW,T.muted)
end

function F:BuildIconManager()
    if self.iconManager then return self.iconManager end
    self:BuildUI()
    local shade=CreateFrame("Frame","ForeverCoreIconManager",self.frame); shade:SetAllPoints(); shade:SetFrameLevel(self.frame:GetFrameLevel()+50); shade:EnableMouse(true)
    local dark=shade:CreateTexture(nil,"BACKGROUND"); dark:SetAllPoints(); dark:SetColorTexture(0,0,0,.80)
    local box=T:Panel(shade,650,500,0,0,{.025,.05,.055,1}); box:ClearAllPoints(); box:SetPoint("CENTER",shade,"CENTER",0,0)
    box.title=T:Text(box,"Minimap addon icons",22,22,20,420,T.gold)
    box.hint=T:Text(box,"Keep everything hidden by default, then allow only the launchers you actually want.",12,22,54,605,T.muted)
    box.default=T:Button(box,"",238,30,22,82,function()
        F:SetOtherMinimapButtonsHidden(not F.db.settings.hideOtherMinimapButtons); F:RefreshIconManager()
    end)
    box.refresh=T:Button(box,"Rescan minimap",146,30,272,82,function() F:Scan(); F:ApplyMinimapButtonPolicy(); F:RefreshIconManager() end)
    box.rows={}; shade.offset=0
    for i=1,6 do
        local row=T:Panel(box,606,48,22,126+(i-1)*52)
        row.title=T:Text(row,"",13,12,8,260); row.title:SetMaxLines(1)
        row.info=T:Text(row,"",10,12,27,300,T.muted); row.info:SetMaxLines(1)
        row.toggle=T:Button(row,"",112,28,374,10,function()
            if row.key then F:SetAddonMinimapIconVisible(row.key,not F:GetAddonMinimapIconVisible(row.key)); F:RefreshIconManager() end
        end,true)
        row.reset=T:Button(row,"Default",96,28,496,10,function()
            if row.key then F:SetAddonMinimapIconVisible(row.key,nil); F:RefreshIconManager() end
        end)
        box.rows[i]=row
    end
    box.empty=T:Text(box,"No third-party minimap launchers detected yet. Open or reload the relevant addon, then Rescan minimap.",13,36,160,570,T.muted)
    box.count=T:Text(box,"",11,22,448,250,T.muted)
    box.prev=T:Button(box,"Previous",96,30,326,438,function() shade.offset=math.max(0,shade.offset-6); F:RefreshIconManager() end)
    box.next=T:Button(box,"Next",96,30,432,438,function() if shade.offset+6<#(shade.list or {}) then shade.offset=shade.offset+6 end; F:RefreshIconManager() end)
    box.close=T:Button(box,"Close",96,30,532,438,function() shade:Hide() end)
    shade.box=box; shade:Hide(); self.iconManager=shade
    UISpecialFrames[#UISpecialFrames+1]="ForeverCoreIconManager"
    return shade
end
function F:RefreshIconManager()
    local m=self:BuildIconManager(); local b=m.box
    self:ApplyMinimapButtonPolicy(); local list=self:GetMinimapIconGroups(); m.list=list
    m.offset=math.min(m.offset or 0,math.max(0,math.ceil(#list/6)-1)*6)
    b.default.label:SetText(self.db.settings.hideOtherMinimapButtons and "Default: hide other icons" or "Default: show other icons")
    for i,row in ipairs(b.rows) do
        local g=list[m.offset+i]; row:SetShown(g~=nil)
        if g then
            row.key=g.key; row.title:SetText(g.title or g.key)
            row.info:SetText((g.id and ("Addon: "..g.id) or ("Launcher: "..g.key:gsub("^button:",""))).."  /  "..g.count.." button"..(g.count==1 and "" or "s"))
            local visible=self:GetAddonMinimapIconVisible(g.key)
            row.toggle.label:SetText(visible and "Visible" or "Hidden")
            row.reset:SetShown(self.db.settings.minimapIconOverrides[g.key]~=nil)
        end
    end
    b.empty:SetShown(#list==0); b.count:SetText(#list.." detected  /  Page "..(math.floor(m.offset/6)+1).." of "..math.max(1,math.ceil(#list/6)))
end
function F:OpenMinimapIconManager()
    self:BuildUI(); local m=self:BuildIconManager(); m.offset=0; self:RefreshIconManager(); m:Show()
end

function F:BuildModal()
    if self.modal then return self.modal end
    local shade=CreateFrame("Frame",nil,self.frame); shade:SetAllPoints(); shade:SetFrameLevel(self.frame:GetFrameLevel()+40); shade:EnableMouse(true)
    local dark=shade:CreateTexture(nil,"BACKGROUND"); dark:SetAllPoints(); dark:SetColorTexture(0,0,0,.78)
    local box=T:Panel(shade,650,460,165,89,{.025,.05,.055,1})
    box.title=T:Text(box,"",22,22,22,605,T.gold); box.hint=T:Text(box,"",12,22,59,605,T.muted)
    local sf=CreateFrame("ScrollFrame",nil,box,"UIPanelScrollFrameTemplate"); sf:SetPoint("TOPLEFT",23,-116); sf:SetSize(578,263)
    local edit=CreateFrame("EditBox",nil,sf); edit:SetWidth(566); edit:SetHeight(263); edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal); edit:SetMaxLetters(64000)
    edit:SetScript("OnEscapePressed",function() shade:Hide() end); sf:SetScrollChild(edit)
    box.edit=edit; box.scroll=sf
    box.error=T:Text(box,"",11,23,388,604,{1,.55,.4})
    box.cancel=T:Button(box,"Close",112,30,22,414,function() shade:Hide() end)
    box.ok=T:Button(box,"Confirm",160,30,468,414,function()
        if not box.callback then shade:Hide(); return end
        local cb,txt=box.callback,edit:GetText()
        shade:Hide()
        local ok,msg=cb(txt)
        if ok==false then shade:Show(); box.error:SetText(msg or "Action could not be completed.") end
    end,true)
    shade.box=box; shade:Hide(); self.modal=shade
    _G.ForeverCoreModal=shade; UISpecialFrames[#UISpecialFrames+1]="ForeverCoreModal"
    return shade
end
function F:TextDialog(title,hint,text,callback)
    local m=self:BuildModal(); local b=m.box
    b.title:SetText(title); b.hint:SetText(hint); b.edit:SetText(text); b.edit:SetCursorPosition(0); b.scroll:SetVerticalScroll(0)
    b.error:SetText(""); b.callback=callback; b.ok:SetShown(callback~=nil); b.ok.label:SetText("Import")
    b.edit:SetScript("OnTextChanged",function(e) e:SetHeight(math.max(263,e:GetNumLines()*16+20)) end)
    b.edit:SetHeight(math.max(263,b.edit:GetNumLines()*16+20)); m:Show(); b.edit:SetFocus()
    if not callback then b.edit:HighlightText() end
end
function F:Confirm(title,body,callback)
    self:TextDialog(title,"Review the action below.",body,function() callback(); return true end)
    self.modal.box.ok.label:SetText("Confirm")
    self.modal.box.edit:ClearFocus()
end
function F:ReviewChanges()
    local lines={}; local ids={}; for id in pairs(self.pending) do ids[#ids+1]=id end; table.sort(ids)
    for _,id in ipairs(ids) do lines[#lines+1]=(self.pending[id] and "ENABLE   " or "DISABLE  ")..id end
    if #lines==0 then
        if self.stagedProfile then self.char.profile=self.stagedProfile; self.stagedProfile=nil; self:Refresh() end
        self:Print("No enabled-state changes needed."); return
    end
    self:TextDialog("Review addon changes","Applies only to this character. Reload afterward to finish. Saved addon data is retained.",table.concat(lines,"\n"),function()
        if not self:Apply() then return false,"Changes were not applied. Check chat for details." end
        self.char.profile=self.stagedProfile; self.stagedProfile=nil; self:Refresh(); return true
    end)
    self.modal.box.ok.label:SetText("Apply changes"); self.modal.box.edit:ClearFocus()
end
