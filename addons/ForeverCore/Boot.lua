local ADDON,F=...
local MINIMAP_SAFE = {
    ForeverCoreMinimapButton=true, MinimapZoomIn=true, MinimapZoomOut=true,
    MiniMapTracking=true, MiniMapTrackingButton=true, MiniMapWorldMapButton=true,
    GameTimeFrame=true, TimeManagerClockButton=true, MinimapBackdrop=true,
    MinimapNorthTag=true, MiniMapMailFrame=true, QueueStatusMinimapButton=true,
    GarrisonLandingPageMinimapButton=true, ExpansionLandingPageMinimapButton=true,
}
local function norm(s)
    return type(s)=="string" and s:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("[^%w]",""):lower() or ""
end
local function addCandidate(out,value)
    if type(value)=="string" and value~="" then out[#out+1]=value
    elseif type(value)=="table" then
        for _,k in ipairs({"name","label","text","title"}) do
            if type(value[k])=="string" and value[k]~="" then out[#out+1]=value[k] end
        end
    end
end
function F:GetMinimapButtonOwner(frame)
    if not frame then return nil end
    local name=frame.GetName and frame:GetName() or nil
    local candidates={}
    addCandidate(candidates,name)
    if name then
        addCandidate(candidates,name:match("^LibDBIcon%d*_(.+)$"))
        addCandidate(candidates,name:match("^LDBIcon%d*_(.+)$"))
    end
    addCandidate(candidates,frame.addonName)
    addCandidate(candidates,frame.addon)
    addCandidate(candidates,frame.moduleName)
    addCandidate(candidates,frame.dataObject)
    addCandidate(candidates,frame.minimapDataObject)
    for _,a in ipairs(self.addons or {}) do
        if a.id~=ADDON then
            local aid=norm(a.id)
            local atitle=norm(a.title)
            for _,candidate in ipairs(candidates) do
                local c=norm(candidate)
                if c~="" then
                    if c==aid or (#aid>=4 and c:find(aid,1,true)) or
                       (#atitle>=4 and (c==atitle or c:find(atitle,1,true) or atitle:find(c,1,true))) then
                        return a.id
                    end
                end
            end
        end
    end
    return nil
end
function F:IsAddonMinimapButton(frame)
    if not frame or frame==self.minimap or not frame.GetObjectType or frame:GetObjectType()~="Button" then return false end
    local name=frame.GetName and frame:GetName() or nil
    if name and MINIMAP_SAFE[name] then return false end
    if self:GetMinimapButtonOwner(frame) then return true end
    if name and (name:find("LibDBIcon",1,true) or name:find("LDBIcon",1,true)) then return true end
    if frame.minimapDataObject or frame.dataObject then return true end
    if name then
        local low=name:lower()
        if low:find("minimapbutton",1,true) and not low:find("tracking",1,true) and not low:find("zoom",1,true) then return true end
    end
    return false
end
function F:ScanMinimapButtons()
    self.minimapButtonOwners=self.minimapButtonOwners or {}
    self.minimapButtonLabels=self.minimapButtonLabels or {}
    local seen={}
    local function scan(parent)
        if not parent or not parent.GetChildren then return end
        local children={parent:GetChildren()}
        for _,frame in ipairs(children) do
            if F.IsAddonMinimapButton and F:IsAddonMinimapButton(frame) then
                seen[frame]=true
                local owner=F:GetMinimapButtonOwner(frame)
                local name=frame.GetName and frame:GetName() or nil
                local key=owner or (name and ("button:"..name) or "button:unidentified")
                F.minimapButtonOwners[frame]=key
                if owner and F.byID and F.byID[owner] then
                    F.minimapButtonLabels[key]=F.byID[owner].title or owner
                elseif name then
                    local broker=name:match("^LibDBIcon%d*_(.+)$") or name:match("^LDBIcon%d*_(.+)$")
                    F.minimapButtonLabels[key]=broker or name
                else
                    F.minimapButtonLabels[key]="Unidentified addon button"
                end
            end
        end
    end
    scan(Minimap)
    if MinimapCluster and MinimapCluster~=Minimap then scan(MinimapCluster) end
    for frame in pairs(self.minimapButtonOwners) do
        if not seen[frame] then self.minimapButtonOwners[frame]=nil end
    end
    return self.minimapButtonOwners
end
function F:GetAddonMinimapIconVisible(key)
    if not self.db then return true end
    local s=self.db.settings
    local overrides=s.minimapIconOverrides or {}
    if overrides[key]~=nil then return not not overrides[key] end
    return not s.hideOtherMinimapButtons
end
function F:ShouldHideMinimapButton(frame)
    if not self.db or frame==self.minimap then return false end
    local key=self.minimapButtonOwners and self.minimapButtonOwners[frame]
    if not key then
        self:ScanMinimapButtons(); key=self.minimapButtonOwners and self.minimapButtonOwners[frame]
    end
    if not key then return false end
    return not self:GetAddonMinimapIconVisible(key)
end
function F:GetMinimapIconGroups()
    self:ScanMinimapButtons()
    local groups={}
    for frame,key in pairs(self.minimapButtonOwners or {}) do
        local g=groups[key]
        if not g then
            local a=self.byID and self.byID[key]
            g={key=key,id=a and key or nil,title=(a and a.title) or self.minimapButtonLabels[key] or key,count=0}
            groups[key]=g
        end
        g.count=g.count+1
    end
    local list={}; for _,g in pairs(groups) do list[#list+1]=g end
    table.sort(list,function(a,b) return (a.title or a.key):lower() < (b.title or b.key):lower() end)
    return list
end
function F:ApplyMinimapButtonPolicy()
    if not Minimap or not self.db then return end
    self:ScanMinimapButtons()
    self.managedMinimapButtons=self.managedMinimapButtons or {}
    self.coreHiddenMinimapButtons=self.coreHiddenMinimapButtons or {}
    for frame in pairs(self.minimapButtonOwners or {}) do
        if frame and frame.Hide and frame.Show then
            if not self.managedMinimapButtons[frame] then
                self.managedMinimapButtons[frame]=true
                if frame.HookScript then frame:HookScript("OnShow",function(btn)
                    if F.db and F:ShouldHideMinimapButton(btn) then
                        F.coreHiddenMinimapButtons[btn]=true
                        btn:Hide()
                    end
                end) end
            end
            if self:ShouldHideMinimapButton(frame) then
                if not frame.IsShown or frame:IsShown() then self.coreHiddenMinimapButtons[frame]=true end
                frame:Hide()
            elseif self.coreHiddenMinimapButtons[frame] then
                self.coreHiddenMinimapButtons[frame]=nil
                frame:Show()
            end
        end
    end
end
function F:SetOtherMinimapButtonsHidden(hidden)
    self.db.settings.hideOtherMinimapButtons=not not hidden
    self:ApplyMinimapButtonPolicy()
    self:Refresh()
end
function F:SetAddonMinimapIconVisible(key,visible)
    if not self.db or type(key)~="string" then return end
    local t=self.db.settings.minimapIconOverrides
    if visible==nil then t[key]=nil else t[key]=not not visible end
    self:ApplyMinimapButtonPolicy()
    self:Refresh()
end
function F:UpdateMinimap()
    if not self.minimap then return end
    local angle=math.rad(self.db.settings.minimapAngle)
    self.minimap:ClearAllPoints(); self.minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*80,math.sin(angle)*80)
    self.minimap:SetShown(self.db.settings.minimap)
end
function F:CreateLauncher()
    if not Minimap or self.minimap then return end
    local b=CreateFrame("Button","ForeverCoreMinimapButton",Minimap,"BackdropTemplate")
    self.minimap=b; b:SetSize(33,33); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
    b:SetNormalTexture(self.media.."Core.tga")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function(_,button)
        if button=="RightButton" then self:BuildUI(); self.page="Addons"; self.frame:Show(); self:Render() else self:Toggle() end
    end)
    b:SetScript("OnDragStart",function()
        b:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition(); local scale=Minimap:GetEffectiveScale(); local cx,cy=Minimap:GetCenter()
            self.db.settings.minimapAngle=math.deg(math.atan2(y/scale-cy,x/scale-cx)); self:UpdateMinimap()
        end)
    end)
    b:SetScript("OnDragStop",function() b:SetScript("OnUpdate",nil) end)
    self.T:Tip(b,"ForeverCore | by 0xgle","Left-click: Sanctum\nRight-click: Addons\nDrag: move launcher")
    self:UpdateMinimap()
end
function F:RegisterBroker()
    if not LibStub then return end
    local lib=LibStub("LibDataBroker-1.1",true)
    if lib and not self.broker then self.broker=lib:NewDataObject("ForeverCore",{
        type="launcher",text="ForeverCore",icon=self.media.."Core.tga",
        OnClick=function() F:Toggle() end,
        OnTooltipShow=function(t) t:AddLine("ForeverCore | by 0xgle"); t:AddLine("Click to open the Sanctum") end}) end
end
SLASH_FOREVERCORE1="/fc"; SLASH_FOREVERCORE2="/forevercore"
SlashCmdList.FOREVERCORE=function(msg)
    msg=(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg=="reset" then
        if F.db then F.db.settings.position=nil; F.db.settings.scale=1 end
        F:BuildUI(); F.frame:ClearAllPoints(); F.frame:SetPoint("CENTER"); F:ApplyScale(); F.frame:Show()
    elseif msg=="help" then F:Print("/fc | /fc addons | /fc profiles | /fc diag | /fc reset | /fc minimap | /fc icons | /fc icons hide | /fc icons show")
    elseif msg=="minimap" then F.db.settings.minimap=not F.db.settings.minimap; F:UpdateMinimap()
    elseif msg=="icons" then F:BuildUI(); F.frame:Show(); F:OpenMinimapIconManager()
    elseif msg=="icons hide" then F:SetOtherMinimapButtonsHidden(true)
    elseif msg=="icons show" then F:SetOtherMinimapButtonsHidden(false)
    elseif msg=="addons" or msg=="profiles" or msg=="diag" then
        F:BuildUI(); F.page=({addons="Addons",profiles="Profiles",diag="Diagnostics"})[msg]; F.frame:Show(); F:Render()
    else F:Toggle() end
end
_G.BINDING_HEADER_FOREVERCORE="ForeverCore"
_G.BINDING_NAME_FOREVERCORE_TOGGLE="Open ForeverCore"
function ForeverCore_Toggle() F:Toggle() end
local e=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","DISPLAY_SIZE_CHANGED","UI_SCALE_CHANGED"}) do e:RegisterEvent(event) end
e:SetScript("OnEvent",function(_,event,arg)
    if event=="ADDON_LOADED" and arg==ADDON then F:InitDB(); F.char.reload=nil
    elseif event=="PLAYER_LOGIN" then
        F:Scan(); F:CreateLauncher(); F:RegisterBroker(); F:ApplyMinimapButtonPolicy()
        if C_Timer and C_Timer.After then
            C_Timer.After(1,function() F:ApplyMinimapButtonPolicy() end)
            C_Timer.After(3,function() F:ApplyMinimapButtonPolicy() end)
            C_Timer.After(6,function() F:ApplyMinimapButtonPolicy() end)
        end
        if not F.db.welcomed then F:Print("Welcome to the Sanctum. Open with /fc or the minimap crystal. By 0xgle."); F.db.welcomed=true end
    elseif event=="ADDON_LOADED" and F.db then
        if C_Timer and C_Timer.After then C_Timer.After(.2,function() F:Scan(); F:ApplyMinimapButtonPolicy() end) end
    elseif event=="DISPLAY_SIZE_CHANGED" or event=="UI_SCALE_CHANGED" then F:ApplyScale()
    elseif F.db then F:Refresh() end
end)
