local _, FB = ...
local M = {}
FB.MinimapLauncher = M

local function UpdatePosition(btn)
    local angle = math.rad(FB.settings.minimapAngle or 220)
    local x, y = math.cos(angle)*80, math.sin(angle)*80
    btn:ClearAllPoints(); btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function M:Build()
    if self.button or not Minimap then return end
    local b=CreateFrame("Button","ForeverBagsMinimapButton",Minimap)
    b:SetSize(34,34); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    local icon=b:CreateTexture(nil,"ARTWORK"); icon:SetAllPoints(); icon:SetTexture(FB.Media:Icon("bag"))
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function(_,button) if button=="RightButton" then FB.SettingsUI:Toggle() else FB:Toggle() end end)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine("ForeverBags",1,0.82,0.35); GameTooltip:AddLine("Left-click: inventory",0.8,0.8,0.8); GameTooltip:AddLine("Right-click: settings",0.8,0.8,0.8); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnDragStart",function(self) self:SetScript("OnUpdate",function()
        local mx,my=Minimap:GetCenter(); local cx,cy=GetCursorPosition(); local scale=UIParent:GetEffectiveScale(); cx,cy=cx/scale,cy/scale
        local dy, dx = cy-my, cx-mx
        local a
        if math.atan2 then
            a = math.atan2(dy, dx)
        elseif dx == 0 then
            a = dy >= 0 and (math.pi/2) or (-math.pi/2)
        else
            a = math.atan(dy/dx)
            if dx < 0 then a = a + math.pi end
        end
        FB.settings.minimapAngle=math.deg(a); UpdatePosition(self)
    end) end)
    b:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
    self.button=b; UpdatePosition(b); b:SetShown(FB.settings.minimap~=false)
end

FB:On("LOGIN", function() C_Timer.After(0.5,function() M:Build() end) end)
FB:On("SETTINGS_CHANGED", function() if M.button then M.button:SetShown(FB.settings.minimap~=false); UpdatePosition(M.button) end end)
