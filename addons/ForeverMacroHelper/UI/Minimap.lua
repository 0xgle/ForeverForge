local _, FMH = ...
local M={}; FMH.Minimap=M
local function UpdatePosition(btn)
    local angle=math.rad(FMH.settings.minimapAngle or 225)
    btn:ClearAllPoints(); btn:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*80,math.sin(angle)*80)
end
function M:Build()
    if self.button or not Minimap then return end
    local b=CreateFrame("Button","ForeverMacroHelperMinimapButton",Minimap)
    b:SetSize(34,34); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    local bg=b:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    local ic=b:CreateTexture(nil,"ARTWORK"); ic:SetSize(20,20); ic:SetPoint("CENTER",-1,1); ic:SetTexture("Interface\\Icons\\INV_Misc_Note_02")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function(_,button)
        if button=="RightButton" and FMH.frame then FMH:ToggleSettings() else FMH:Toggle() end
    end)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine("ForeverMacroHelper",1,0.82,0.35)
        GameTooltip:AddLine("Created by 0xgle",0.55,0.78,0.9); GameTooltip:AddLine("Left-click: macro library",0.8,0.8,0.8); GameTooltip:AddLine("Right-click: settings",0.8,0.8,0.8); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnDragStart",function(self)
        self:SetScript("OnUpdate",function(btn)
            local mx,my=Minimap:GetCenter(); local cx,cy=GetCursorPosition(); local s=UIParent:GetEffectiveScale(); cx,cy=cx/s,cy/s
            local dy,dx=cy-my,cx-mx; local a
            if math.atan2 then a=math.atan2(dy,dx) elseif dx==0 then a=dy>=0 and math.pi/2 or -math.pi/2 else a=math.atan(dy/dx); if dx<0 then a=a+math.pi end end
            FMH.settings.minimapAngle=math.deg(a); UpdatePosition(btn)
        end)
    end)
    b:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
    self.button=b; UpdatePosition(b); b:SetShown(FMH.settings.minimap~=false)
end
function M:Refresh() if self.button then self.button:SetShown(FMH.settings.minimap~=false); UpdatePosition(self.button) end end
FMH:On("LOGIN",function() C_Timer.After(0.5,function() M:Build() end) end)
