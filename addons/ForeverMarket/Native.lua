local _,FM=...
local N={}; FM.Native=N
-- Keep the Blizzard session alive. Calling Hide() on its root closes the AH.
-- Preserve the frame, scripts and registered events; park only its presentation.
function N:Takeover()
    if not FM.Market.open or not FM:Supported() or self.manual then return end
    local f=AuctionFrame
    if not f or not f:IsShown() or InCombatLockdown() then return end
    if not self.saved then
        local points={};for i=1,f:GetNumPoints() do points[i]={f:GetPoint(i)} end
        self.saved={frame=f,points=points,alpha=f:GetAlpha(),mouse=f:IsMouseEnabled(),clamp=f:IsClampedToScreen()}
    end
    self.moving=true
    f:SetAlpha(0);f:EnableMouse(false);f:SetClampedToScreen(false)
    f:ClearAllPoints();f:SetPoint("TOPRIGHT",UIParent,"BOTTOMLEFT",-10000,-10000)
    self.moving=false
end
function N:Restore()
    local s=self.saved;if not s then return end
    self.saved=nil;self.moving=true
    local f=s.frame
    f:SetAlpha(s.alpha);f:EnableMouse(s.mouse);f:SetClampedToScreen(s.clamp)
    f:ClearAllPoints();for _,p in ipairs(s.points) do f:SetPoint(unpack(p)) end
    self.moving=false
end
function N:Hook()
    local f=AuctionFrame
    if not f or self.hooked then return end
    self.hooked=true
    f:HookScript("OnShow",function()
        if FM.Market.open and FM.DB.settings.openWithAH and not N.manual then
            FM:After(0,function() N:Takeover() end)
        end
    end)
    -- UIParent may reposition its panels after inventory opens.
    hooksecurefunc(f,"SetPoint",function()
        if N.saved and not N.moving then N:Takeover() end
    end)
end
function N:SwitchToBlizzard()
    self.manual=true;FM.Market:Stop();FM.UI:DismissConfirm()
    self:Restore();FM.UI.suppressClose=true;FM.UI:Hide();FM.UI.suppressClose=false
    FM:Status("Blizzard interface restored. Use /fm to return to ForeverMarket.")
end
FM:On("AUCTION_HOUSE_SHOW",function()
    FM.Market.open=true;N.manual=false;N:Hook()
    FM:After(0,function()
        if not FM.Market.open then return end
        N:Hook()
        if FM.DB.settings.openWithAH and FM:Supported() and not InCombatLockdown() then FM.UI:Show() end
        if not FM:Supported() then FM:Print("This build uses a different auction API. Trade through Blizzard; /fm opens local data.") end
    end)
end)
FM:On("AUCTION_HOUSE_CLOSED",function()
    FM.Market.open=false;FM.Market:Stop();FM.Market.results={};FM.Market.owned={}
    N:Restore();FM.UI:DismissConfirm();FM.UI:Hide()
end)
FM:On("PLAYER_REGEN_DISABLED",function()
    if N.saved then N:SwitchToBlizzard() end
end)
FM:On("ADDON_LOADED",function() if AuctionFrame then N:Hook() end end)
