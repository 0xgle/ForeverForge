local ADDON,F=...
local MINIMAP_SAFE = {
    ForeverCoreMinimapButton=true, MinimapZoomIn=true, MinimapZoomOut=true,
    MiniMapTracking=true, MiniMapTrackingButton=true, MiniMapWorldMapButton=true,
    GameTimeFrame=true, TimeManagerClockButton=true, MinimapBackdrop=true,
    MinimapNorthTag=true, MiniMapMailFrame=true, QueueStatusMinimapButton=true,
    GarrisonLandingPageMinimapButton=true, ExpansionLandingPageMinimapButton=true,
}
function F:IsAddonMinimapButton(frame)
    if not frame or frame==self.minimap or not frame.GetObjectType or frame:GetObjectType()~="Button" then return false end
    local name=frame:GetName()
    if name and MINIMAP_SAFE[name] then return false end
    if name and (name:find("LibDBIcon",1,true) or name:find("LDBIcon",1,true)) then return true end
    if frame.minimapDataObject or frame.dataObject or frame.db then return true end
    if name then
        local low=name:lower()
        if low:find("minimapbutton",1,true) and not low:find("tracking",1,true) and not low:find("zoom",1,true) then return true end
        for i=1,(self.A.GetNumAddOns and self.A.GetNumAddOns() or 0) do
            local addon=self.A.GetAddOnInfo(i)
            if addon and addon~=ADDON then
                local key=addon:gsub("[^%w]",""):lower()
                if #key>=4 and low:gsub("[^%w]",""):find(key,1,true) then return true end
            end
        end
    end
    return false
end
function F:ApplyMinimapButtonPolicy()
    if not Minimap or not self.db then return end
    local hide=self.db.settings.hideOtherMinimapButtons
    self.hiddenMinimapButtons=self.hiddenMinimapButtons or {}
    local children={Minimap:GetChildren()}
    for _,frame in ipairs(children) do
        if self:IsAddonMinimapButton(frame) then
            if hide then
                if not self.hiddenMinimapButtons[frame] then
                    self.hiddenMinimapButtons[frame]=true
                    if frame.HookScript then frame:HookScript("OnShow",function(btn)
                        if F.db and F.db.settings.hideOtherMinimapButtons and btn~=F.minimap then btn:Hide() end
                    end) end
                end
                frame:Hide()
            elseif self.hiddenMinimapButtons[frame] then
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
    elseif msg=="help" then F:Print("/fc | /fc addons | /fc profiles | /fc diag | /fc reset | /fc minimap | /fc icons")
    elseif msg=="minimap" then F.db.settings.minimap=not F.db.settings.minimap; F:UpdateMinimap()
    elseif msg=="icons" then F:SetOtherMinimapButtonsHidden(not F.db.settings.hideOtherMinimapButtons)
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
        if C_Timer and C_Timer.After then C_Timer.After(1,function() F:ApplyMinimapButtonPolicy() end); C_Timer.After(3,function() F:ApplyMinimapButtonPolicy() end) end
        if not F.db.welcomed then F:Print("Welcome to the Sanctum. Open with /fc or the minimap crystal. By 0xgle."); F.db.welcomed=true end
    elseif event=="DISPLAY_SIZE_CHANGED" or event=="UI_SCALE_CHANGED" then F:ApplyScale()
    elseif F.db then F:Refresh() end
end)
