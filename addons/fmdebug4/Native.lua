local _,FM=...
local N={};FM.Native=N

function N:GetHost()
    if FM:IsModernAH() and AuctionHouseFrame then return AuctionHouseFrame end
    if AuctionFrame then return AuctionFrame end
    return AuctionHouseFrame
end

function N:IsIntegrated()
    return FM.Market.open and self:GetHost()~=nil
end

-- Keep the Blizzard Auction House technically open so the live AH session and
-- C_AuctionHouse API stay available, but visually hand the screen to
-- ForeverMarket. We deliberately do not Hide() the host here because doing so
-- may close the underlying Auction House interaction on some clients.
function N:ConcealHost()
    -- Do not alpha-hide, disable, or reparent Blizzard's AuctionHouseFrame.
    -- ForeverMarket is a child overlay of that frame, so protected AH actions
    -- run in the same live interaction context as the native UI.
    local host=self:GetHost()
    if not host then return false end
    self.hostConcealed=true
    return true
end

function N:RestoreHost()
    self.hostConcealed=false
end

-- WoW/third-party bag addons may auto-open inventory when the Auction House
-- interaction starts. ForeverMarket has its own inventory view, so keep external
-- bag windows out of the way without affecting bag data scanning.
function N:CloseExternalBags()
    if type(CloseAllBags)=="function" then pcall(CloseAllBags) end
    if C_Container and type(C_Container.CloseAllBags)=="function" then
        pcall(C_Container.CloseAllBags)
    end
    if type(ContainerFrame_CloseAll)=="function" then pcall(ContainerFrame_CloseAll) end
end

function N:SuppressAuctionBagAutoOpen()
    -- Different bag UIs react at slightly different points in the interaction
    -- startup. Close once immediately and twice after the event queue settles.
    self:CloseExternalBags()
    FM:After(0.05,function()
        if FM.Market.open and FM.UI and FM.UI.frame and FM.UI.frame:IsShown() then
            N:CloseExternalBags()
        end
    end)
    FM:After(0.20,function()
        if FM.Market.open and FM.UI and FM.UI.frame and FM.UI.frame:IsShown() then
            N:CloseExternalBags()
        end
    end)
end

function N:SelectForeverMarket(tabName)
    if not FM.Market.open then
        FM:Print("Open the Auction House at an auctioneer first.")
        return false
    end

    local host=self:GetHost()
    if not host then
        FM:Print("Auction House frame is not available yet.")
        return false
    end

    self.manual=false
    self:ConcealHost()
    FM.UI:Show()
    self:SuppressAuctionBagAutoOpen()
    if tabName then FM.UI:SetTab(tabName) end
    FM:Status("Live Auction House connected. ForeverMarket is running inside the native Auction House session.")
    return true
end

function N:OpenMarket(tabName)
    if not FM.Market.open then
        local host=self:GetHost()
        if host and host.IsShown and host:IsShown() then FM.Market.open=true end
    end
    return self:SelectForeverMarket(tabName)
end


function N:BeginNativePostConfirmation(tabName)
    self.pendingNativePost=true
    self.pendingReturnTab=tabName or "Sell"
    self:RestoreHost()
    if FM.UI then FM.UI:Hide() end
    FM:Status("The game requires an additional Auction House confirmation. Confirm it in the Blizzard window.")
end

function N:FinishNativePostConfirmation()
    if not self.pendingNativePost then return end
    local tab=self.pendingReturnTab or "Sell"
    self.pendingNativePost=nil
    self.pendingReturnTab=nil
    FM:After(.05,function()
        if FM.Market.open and not N.manual then N:SelectForeverMarket(tab) end
    end)
end

function N:SwitchToBlizzard()
    self.manual=true
    self.pendingNativePost=nil
    self.pendingReturnTab=nil
    FM.Market:Stop()
    if FM.UI then
        FM.UI:DismissConfirm()
        FM.UI:Hide()
    end

    self:RestoreHost()

    -- Return to a normal Blizzard AH page when the frame exposes tabs.
    if AuctionHouseFrame and AuctionHouseFrame.Tabs and AuctionHouseFrame.Tabs[1] then
        local first=AuctionHouseFrame.Tabs[1]
        if first.Click then pcall(first.Click,first) end
    elseif AuctionFrame and _G.AuctionFrameTab1 and _G.AuctionFrameTab1.Click then
        pcall(_G.AuctionFrameTab1.Click,_G.AuctionFrameTab1)
    end
    FM:Status("Blizzard Auction House selected. Use /fm to return to ForeverMarket.")
end

function N:CloseAuctionHouse()
    -- Restore first so the native frame's own close/on-hide logic sees its
    -- expected visual state.
    self.manual=false
    if FM.UI then
        FM.UI:DismissConfirm()
        FM.UI:Hide()
    end
    self:RestoreHost()

    local host=self:GetHost()
    if host then
        local closed=false
        if type(HideUIPanel)=="function" then
            local ok=pcall(HideUIPanel,host)
            closed=ok
        end
        if not closed and host.Hide then pcall(host.Hide,host) end
    end
end

function N:AuctionHouseShown()
    FM.Market.open=true
    self.manual=false
    FM:After(0,function()
        if not FM.Market.open then return end
        if FM.DB and FM.DB.settings.openWithAH and FM:Supported() and not InCombatLockdown() then
            N:SelectForeverMarket()
        elseif not FM:Supported() then
            FM:Print("This Auction House API is not supported by ForeverMarket.")
        else
            N:RestoreHost()
        end
    end)
end

function N:AuctionHouseClosed()
    self.pendingNativePost=nil
    self.pendingReturnTab=nil
    -- Always restore the host before forgetting the state; this also keeps
    -- /reload and future AH openings sane after a custom-window session.
    self:RestoreHost()
    self.hostState=nil
    FM.Market.open=false
    FM.Market:Stop()
    FM.Market.results={}
    FM.Market.owned={}
    if FM.UI then
        FM.UI:DismissConfirm()
        FM.UI:Hide()
    end
end

FM:On("AUCTION_HOUSE_SHOW",function() N:AuctionHouseShown() end)
FM:On("AUCTION_HOUSE_CLOSED",function() N:AuctionHouseClosed() end)

FM:On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW",function(interactionType)
    if Enum and Enum.PlayerInteractionType and interactionType==Enum.PlayerInteractionType.Auctioneer then
        N:AuctionHouseShown()
    end
end)

FM:On("PLAYER_INTERACTION_MANAGER_FRAME_HIDE",function(interactionType)
    if Enum and Enum.PlayerInteractionType and interactionType==Enum.PlayerInteractionType.Auctioneer then
        N:AuctionHouseClosed()
    end
end)

FM:On("PLAYER_REGEN_DISABLED",function()
    if FM.UI and FM.UI.frame and FM.UI.frame:IsShown() then
        N:SwitchToBlizzard()
    end
end)
