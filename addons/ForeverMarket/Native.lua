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

function N:CloseExternalBags()
    if type(CloseAllBags)=="function" then pcall(CloseAllBags) end
    if C_Container and type(C_Container.CloseAllBags)=="function" then pcall(C_Container.CloseAllBags) end
    if type(ContainerFrame_CloseAll)=="function" then pcall(ContainerFrame_CloseAll) end
end

function N:SuppressAuctionBagAutoOpen()
    self:CloseExternalBags()
    FM:After(.05,function()
        if FM.Market.open and FM.UI and FM.UI.frame and FM.UI.frame:IsShown() then N:CloseExternalBags() end
    end)
    FM:After(.20,function()
        if FM.Market.open and FM.UI and FM.UI.frame and FM.UI.frame:IsShown() then N:CloseExternalBags() end
    end)
end

local function deselect(tab)
    if tab and type(PanelTemplates_DeselectTab)=="function" then pcall(PanelTemplates_DeselectTab,tab) end
end
local function selectTab(tab)
    if tab and type(PanelTemplates_SelectTab)=="function" then pcall(PanelTemplates_SelectTab,tab) end
end

-- Clean-room native AH tab bridge. The custom frame remains entirely
-- ForeverMarket, while the host integration follows Blizzard's display-tab
-- contract instead of modifying AuctionHouseFrame ad hoc.
function N:EnsureModernTab()
    if not FM:IsModernAH() then return false end
    local host=AuctionHouseFrame
    if not host then return false end
    if self.tabButton and self.tabButton.GetParent then return true end

    if FM.UI and FM.UI.Build then FM.UI:Build() end

    local root=CreateFrame("Frame","ForeverMarketAHTabRoot",host)
    root:SetSize(10,10)
    local nativeTabs=host.Tabs or {}
    local anchor=nativeTabs[#nativeTabs]
    if anchor then root:SetPoint("TOPLEFT",anchor,"TOPRIGHT",3,0)
    else root:SetPoint("TOPLEFT",host,"TOPLEFT",20,-20) end

    local tab=CreateFrame("Button","ForeverMarketAHTab",root,"AuctionHouseFrameDisplayModeTabTemplate")
    tab:SetText("ForeverMarket")
    if type(PanelTemplates_TabResize)=="function" then pcall(PanelTemplates_TabResize,tab,20,nil,90) end
    tab:SetPoint("TOPLEFT",root,"TOPLEFT",3,0)
    deselect(tab)

    self.tabRoot=root
    self.tabButton=tab

    if not self.displayHooked and type(hooksecurefunc)=="function" and type(host.SetDisplayMode)=="function" then
        hooksecurefunc(host,"SetDisplayMode",function(_,mode)
            if type(mode)=="table" and #mode>0 then
                if FM.UI and FM.UI.frame then FM.UI.frame:Hide() end
                deselect(N.tabButton)
            end
        end)
        self.displayHooked=true
    end

    tab:SetScript("OnClick",function()
        if not FM.Market.open then return end
        local h=AuctionHouseFrame
        if not h then return end
        if type(h.SetDisplayMode)=="function" then h:SetDisplayMode({}) end
        h.displayMode=nil
        for _,t in ipairs(h.Tabs or {}) do deselect(t) end
        deselect(tab)
        selectTab(tab)
        if type(h.SetTitle)=="function" then h:SetTitle("ForeverMarket") end
        if FM.UI then FM.UI:Show() end
        N.manual=false
        N:SuppressAuctionBagAutoOpen()
        FM:Status("Live Auction House connected. ForeverMarket tab is active.")
        if FM.Debug then FM.Debug:Log("FOREVER_TAB_SELECTED","button="..tostring(tab:GetName())) end
    end)

    if FM.Debug then FM.Debug:Log("FOREVER_TAB_CREATED","button="..tostring(tab:GetName())) end
    return true
end

function N:SelectForeverMarket(tabName)
    if not FM.Market.open then
        FM:Print("Open the Auction House at an auctioneer first.")
        return false
    end
    if FM:IsModernAH() then
        if not self:EnsureModernTab() then return false end
        if self.tabButton and self.tabButton.Click then self.tabButton:Click() end
        if tabName and FM.UI then FM.UI:SetTab(tabName) end
        return true
    end
    if FM.UI then FM.UI:Show(); if tabName then FM.UI:SetTab(tabName) end end
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
    if FM.UI then FM.UI:Hide() end
    FM:Status("The game requires an additional Auction House confirmation. Confirm it in the Blizzard window.")
end

function N:FinishNativePostConfirmation()
    if not self.pendingNativePost then return end
    local tab=self.pendingReturnTab or "Sell"
    self.pendingNativePost=nil;self.pendingReturnTab=nil
    FM:After(.05,function()
        if FM.Market.open and not N.manual then N:SelectForeverMarket(tab) end
    end)
end

function N:SwitchToBlizzard()
    self.manual=true
    self.pendingNativePost=nil;self.pendingReturnTab=nil
    if FM.UI then FM.UI:DismissConfirm();FM.UI:Hide() end
    deselect(self.tabButton)
    local host=self:GetHost()
    if host and host.Tabs and host.Tabs[1] and host.Tabs[1].Click then
        host.Tabs[1]:Click()
    elseif AuctionFrame and _G.AuctionFrameTab1 and _G.AuctionFrameTab1.Click then
        _G.AuctionFrameTab1:Click()
    end
    FM:Status("Blizzard Auction House selected. Use /fm to return to ForeverMarket.")
end

function N:CloseAuctionHouse()
    self.manual=false
    if FM.UI then FM.UI:DismissConfirm();FM.UI:Hide() end
    local host=self:GetHost()
    if host then
        if type(HideUIPanel)=="function" then
            local ok=pcall(HideUIPanel,host)
            if ok then return end
        end
        if host.Hide then host:Hide() end
    end
end

function N:AuctionHouseShown()
    FM.Market.open=true
    self.manual=false
    FM:After(0,function()
        if not FM.Market.open then return end
        if FM:IsModernAH() then N:EnsureModernTab() end
        if FM.DB and FM.DB.settings.openWithAH and FM:Supported() and not InCombatLockdown() then
            N:SelectForeverMarket()
        elseif not FM:Supported() then
            FM:Print("This Auction House API is not supported by ForeverMarket.")
        end
    end)
end

function N:AuctionHouseClosed()
    self.pendingNativePost=nil;self.pendingReturnTab=nil
    FM.Market.open=false
    FM.Market:Stop();FM.Market.results={};FM.Market.owned={}
    if FM.UI then FM.UI:DismissConfirm();FM.UI:Hide() end
    deselect(self.tabButton)
end

FM:On("AUCTION_HOUSE_SHOW",function() N:AuctionHouseShown() end)
FM:On("AUCTION_HOUSE_CLOSED",function() N:AuctionHouseClosed() end)
FM:On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW",function(interactionType)
    if Enum and Enum.PlayerInteractionType and interactionType==Enum.PlayerInteractionType.Auctioneer then N:AuctionHouseShown() end
end)
FM:On("PLAYER_INTERACTION_MANAGER_FRAME_HIDE",function(interactionType)
    if Enum and Enum.PlayerInteractionType and interactionType==Enum.PlayerInteractionType.Auctioneer then N:AuctionHouseClosed() end
end)
FM:On("PLAYER_REGEN_DISABLED",function()
    if FM.UI and FM.UI.frame and FM.UI.frame:IsShown() then N:SwitchToBlizzard() end
end)
