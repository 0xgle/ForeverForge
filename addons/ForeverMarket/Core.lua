local ADDON, FM = ...
_G.ForeverMarket = FM
FM.name, FM.version, FM.author = ADDON, "2.4.0-debug7", "0xgle"
FM.media = "Interface\\AddOns\\ForeverMarket\\Media\\"
FM.callbacks = {}
FM.unsupportedEvents = {}
FM.Events = CreateFrame("Frame")

function FM:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4ad6bForeverMarket|r  "..tostring(text))
end

function FM:Status(text)
    self.lastStatus = text
    if self.UI then self.UI:SetStatus(text) end
end

-- Event registration is deliberately defensive. WoW Forever combines APIs
-- from different client generations, so an event may exist on one build and
-- be unknown on another.
function FM:On(event, fn)
    if self.unsupportedEvents[event] then return false end
    if not self.callbacks[event] then
        local ok = pcall(self.Events.RegisterEvent, self.Events, event)
        if not ok then
            self.unsupportedEvents[event] = true
            return false
        end
        self.callbacks[event] = {}
    end
    table.insert(self.callbacks[event], fn)
    return true
end

FM.Events:SetScript("OnEvent", function(_, event, ...)
    for _, fn in ipairs(FM.callbacks[event] or {}) do
        local ok, err = pcall(fn, ...)
        if not ok then
            FM.lastError = tostring(err)
            FM:Print(event..": "..tostring(err))
            if geterrorhandler then geterrorhandler()(err) end
        end
    end
end)

function FM:After(seconds, fn) C_Timer.After(seconds, fn) end

function FM:Money(value)
    local c = math.floor(math.max(0, tonumber(value) or 0)+0.5)
    local g,s = math.floor(c/10000),math.floor(c/100)%100
    if g > 0 then return string.format("|cffd4ad6b%dg|r |cffc4d1d0%02ds|r |cffb4937a%02dc|r",g,s,c%100) end
    if s > 0 then return string.format("|cffc4d1d0%ds|r |cffb4937a%02dc|r",s,c%100) end
    return string.format("|cffb4937a%dc|r",c)
end

function FM:PlainMoney(value)
    local c = math.floor(math.max(0,tonumber(value) or 0)+0.5)
    return string.format("%dg %ds %dc",math.floor(c/10000),math.floor(c/100)%100,c%100)
end

function FM:ParseMoney(text)
    text = tostring(text or ""):lower():gsub(",", ".")
    if text:match("^%s*%d+%s*$") then return tonumber(text) end
    local total,seen = 0,false
    local rest = text:gsub("(%d+%.?%d*)%s*([gsc])", function(n,u)
        total=total+tonumber(n)*({g=10000,s=100,c=1})[u]; seen=true; return ""
    end)
    if not seen or rest:match("%S") or total~=total then return nil end
    return math.floor(total+0.5)
end

function FM:Int(text,min,max)
    local n=tonumber(text)
    if not n or n~=math.floor(n) or n<min or n>max then return nil end
    return n
end

function FM:Refresh()
    if self.UI and self.UI.frame then self.UI:Refresh() end
end

function FM:AuctionBackend()
    if C_AuctionHouse and type(C_AuctionHouse.SendBrowseQuery)=="function" and type(C_AuctionHouse.GetBrowseResults)=="function" then
        return "modern"
    end
    if type(QueryAuctionItems)=="function" and type(GetAuctionItemInfo)=="function" then
        return "legacy"
    end
    return nil
end

function FM:Supported()
    return self:AuctionBackend() ~= nil
end

function FM:IsModernAH()
    return self:AuctionBackend()=="modern"
end

function FM:GetItemInfo(item)
    if C_Item and type(C_Item.GetItemInfo)=="function" then
        local ok,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q=pcall(C_Item.GetItemInfo,item)
        if ok then return a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q end
    end
    if type(GetItemInfo)=="function" then
        local ok,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q=pcall(GetItemInfo,item)
        if ok then return a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q end
    end
end

function FM:GetItemClassName(classID)
    if C_Item and type(C_Item.GetItemClassInfo)=="function" then
        local ok,v=pcall(C_Item.GetItemClassInfo,classID)
        if ok then return v end
    end
    if type(GetItemClassInfo)=="function" then
        local ok,v=pcall(GetItemClassInfo,classID)
        if ok then return v end
    end
end

function FM:GetItemSubClassName(classID,subClassID)
    if C_Item and type(C_Item.GetItemSubClassInfo)=="function" then
        local ok,v=pcall(C_Item.GetItemSubClassInfo,classID,subClassID)
        if ok then return v end
    end
    if type(GetItemSubClassInfo)=="function" then
        local ok,v=pcall(GetItemSubClassInfo,classID,subClassID)
        if ok then return v end
    end
end

SLASH_FOREVERMARKET1,SLASH_FOREVERMARKET2="/fm","/forevermarket"
SlashCmdList.FOREVERMARKET=function(msg)
    msg=(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg=="scan" then
        FM.Market:FullScan()
    elseif msg=="blizzard" then
        FM.Native:SwitchToBlizzard()
    elseif msg=="reset" then
        FM.DB.settings.position=nil
        FM.UI:ApplyPosition()
        FM:Print("Window position reset. Price data has been preserved.")
    elseif msg=="settings" then
        if FM.Native and FM.Native.OpenMarket then FM.Native:OpenMarket("Settings") end
    elseif msg=="debug" then
        local root=(AuctionHouseFrame and "AuctionHouseFrame") or (AuctionFrame and "AuctionFrame") or "none"
        local A=FM.AuctionService
        local transport=A and (" | throttle="..tostring(A:IsThrottleReady()).." | queue="..tostring(#A.queue).." | specific="..tostring(A.activeSearch~=nil)) or ""
        FM:Print("v"..FM.version.." | build "..tostring(select(4,GetBuildInfo())).." | backend="..tostring(FM:AuctionBackend()).." | root="..root.." | AH="..tostring(FM.Market.open)..transport.." | "..tostring(FM.lastError or "no errors"))
    else
        if FM.Native and FM.Native.OpenMarket then FM.Native:OpenMarket() else FM.UI:Toggle() end
    end
end

FM:On("ADDON_LOADED",function(name)
    if name==ADDON then FM:InitDB() end
end)

FM:On("PLAYER_LOGIN",function()
    if not FM.DB then FM:InitDB() end
    FM:Print("v"..FM.version.."  |cff65d6c1by 0xgle|r  /fm")
    if ForeverCore and ForeverCore.apiVersion==1 then
        ForeverCore:RegisterModule(ADDON,{
            title="ForeverMarket",
            description="Market, Trader Engine, Flip Finder, Empire analytics and shopping.",
            icon=12,
            open=function()
                if FM.Native and FM.Native.OpenMarket then FM.Native:OpenMarket() else FM.UI:Toggle() end
            end,
            settings=function()
                if FM.Native and FM.Native.OpenMarket then FM.Native:OpenMarket("Settings") else FM.UI:Show();FM.UI:SetTab("Settings") end
            end
        })
    end
end)
