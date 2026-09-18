local _,FM=...

-- Forever AH transport. Query-type operations are serialized against the
-- Blizzard throttle. Protected actions (post/buy/cancel) are NEVER queued;
-- they must stay on the user's hardware click.
local A={queue={},activeSearch=nil,serial=0,dispatching=false};FM.AuctionService=A
A.ItemSort={sortOrder=4,reverseSort=false}
A.CommoditySort={sortOrder=0,reverseSort=false}

local function now() return GetTime and GetTime() or 0 end

function A:IsModern()
    return FM:IsModernAH() and C_AuctionHouse~=nil
end

function A:IsOpen()
    return self:IsModern() and FM.Market and FM.Market.open
end

function A:IsThrottleReady()
    if not self:IsModern() then return false end
    if type(C_AuctionHouse.IsThrottledMessageSystemReady)~="function" then return true end
    local ok,ready=pcall(C_AuctionHouse.IsThrottledMessageSystemReady)
    return ok and ready==true
end

function A:KeyEqual(a,b)
    if type(a)~="table" or type(b)~="table" then return false end
    return (a.itemID or 0)==(b.itemID or 0)
        and (a.itemLevel or 0)==(b.itemLevel or 0)
        and (a.itemSuffix or 0)==(b.itemSuffix or 0)
        and (a.battlePetSpeciesID or 0)==(b.battlePetSpeciesID or 0)
end

function A:GetItemKeyInfo(itemKey)
    if not self:IsModern() or type(itemKey)~="table" or type(C_AuctionHouse.GetItemKeyInfo)~="function" then return nil end
    local ok,info=pcall(C_AuctionHouse.GetItemKeyInfo,itemKey)
    if ok then return info end
end

function A:Remove(tag)
    if not tag then return end
    for i=#self.queue,1,-1 do
        if self.queue[i].tag==tag then table.remove(self.queue,i) end
    end
end

function A:Enqueue(tag,fn,onError,onSent)
    if type(fn)~="function" then return false end
    self:Remove(tag)
    self.serial=self.serial+1
    self.queue[#self.queue+1]={id=self.serial,tag=tag,fn=fn,onError=onError,onSent=onSent}
    self:DispatchOne()
    return true
end

-- Important: send at most ONE queued AH message per server-ready state. Do
-- not timer-pump the queue; the next throttle-ready transition releases the
-- next request. This avoids the silent drops seen on Forever when multiple
-- messages are fired while the server is still processing the previous one.
function A:DispatchOne()
    if self.dispatching or #self.queue==0 or not self:IsOpen() or not self:IsThrottleReady() then return false end
    local job=table.remove(self.queue,1)
    self.dispatching=true
    local ok,err=pcall(job.fn)
    self.dispatching=false
    if ok then
        if job.onSent then pcall(job.onSent) end
    elseif job.onError then
        pcall(job.onError,err)
    end
    return ok
end

function A:ServerStateChanged()
    -- Re-check the actual Blizzard state instead of assuming every throttle
    -- event means ready.
    if self:IsThrottleReady() then self:DispatchOne() end
    if FM.UI and FM.UI.frame and FM.UI.frame:IsShown() then FM:Refresh() end
end

function A:ClearQueue() self.queue={} end

function A:CancelSearch(owner)
    local req=self.activeSearch
    if req and (owner==nil or req.owner==owner) then
        self.activeSearch=nil
        self:Remove(req.queueTag)
        if req.onCancel then pcall(req.onCancel) end
    end
end

function A:FailSearch(req,message)
    if self.activeSearch~=req then return end
    self.activeSearch=nil
    self:Remove(req.queueTag)
    if req.onError then pcall(req.onError,message or "Auction House search failed.") end
end

function A:SearchItem(itemKey,options,onReady,onError)
    if not self:IsOpen() then if onError then onError("Open the Auction House first.") end;return false end
    if type(itemKey)~="table" or not itemKey.itemID then if onError then onError("The selected item has no valid Auction House key.") end;return false end

    options=options or {}
    self:CancelSearch()
    self.serial=self.serial+1
    local req={
        id=self.serial,owner=options.owner,itemKey=itemKey,commodity=options.commodity,
        splitOwned=options.splitOwned,sellQuery=options.sellQuery==true,sorts=options.sorts,
        attempts=0,cacheAttempts=0,started=now(),timeout=tonumber(options.timeout) or 10,
        onReady=onReady,onError=onError,onCancel=options.onCancel,
        queueTag="item-search-"..tostring(self.serial),
    }
    self.activeSearch=req
    self:AttemptSearch(req)
    return true
end

function A:AttemptSearch(req)
    if self.activeSearch~=req then return end
    if not self:IsOpen() then self:FailSearch(req,"Auction House closed during search.");return end
    if now()-req.started>req.timeout then self:FailSearch(req,"Current offers did not load in time.");return end

    local keyInfo=self:GetItemKeyInfo(req.itemKey)
    if not keyInfo then
        req.cacheAttempts=req.cacheAttempts+1
        -- GetItemKeyInfo becomes available asynchronously. Keep this retry
        -- outside the AH query queue because it is a local cache lookup.
        FM:After(req.cacheAttempts<20 and .05 or .15,function() A:AttemptSearch(req) end)
        return
    end

    if req.commodity==nil then req.commodity=not not keyInfo.isCommodity end
    if req.splitOwned==nil then req.splitOwned=true end
    if req.sorts==nil then
        req.sorts={{sortOrder=req.commodity and A.CommoditySort.sortOrder or A.ItemSort.sortOrder,reverseSort=false}}
    end

    req.attempts=req.attempts+1
    self:Enqueue(req.queueTag,function()
        if A.activeSearch~=req then return end
        if req.sellQuery and type(C_AuctionHouse.SendSellSearchQuery)=="function" then
            C_AuctionHouse.SendSellSearchQuery(req.itemKey,req.sorts,req.splitOwned)
        else
            C_AuctionHouse.SendSearchQuery(req.itemKey,req.sorts,req.splitOwned)
        end
    end,function(err)
        if A.activeSearch==req then A:FailSearch(req,"Could not request current offers: "..tostring(err)) end
    end)

    local attempt=req.attempts
    FM:After(3.0,function()
        if A.activeSearch==req and req.attempts==attempt then
            if req.attempts<4 then A:AttemptSearch(req)
            else A:FailSearch(req,"Current offers did not return a usable response.") end
        end
    end)
end

function A:SearchEvent(isCommodity,eventData)
    local req=self.activeSearch
    if not req or req.commodity~=isCommodity then return end
    if isCommodity then
        if tonumber(eventData)~=tonumber(req.itemKey.itemID) then return end
    elseif not self:KeyEqual(eventData,req.itemKey) then
        return
    end

    local has=true
    if type(C_AuctionHouse.HasSearchResults)=="function" then
        local ok,v=pcall(C_AuctionHouse.HasSearchResults,req.itemKey)
        if ok then has=v~=false end
    end

    local full=true
    local quantity=0
    if isCommodity then
        if type(C_AuctionHouse.HasFullCommoditySearchResults)=="function" then
            local ok,v=pcall(C_AuctionHouse.HasFullCommoditySearchResults,req.itemKey.itemID);if ok then full=v~=false end
        end
        if type(C_AuctionHouse.GetCommoditySearchResultsQuantity)=="function" then
            local ok,v=pcall(C_AuctionHouse.GetCommoditySearchResultsQuantity,req.itemKey.itemID);if ok then quantity=tonumber(v) or 0 end
        end
    else
        if type(C_AuctionHouse.HasFullItemSearchResults)=="function" then
            local ok,v=pcall(C_AuctionHouse.HasFullItemSearchResults,req.itemKey);if ok then full=v~=false end
        end
        if type(C_AuctionHouse.GetItemSearchResultsQuantity)=="function" then
            local ok,v=pcall(C_AuctionHouse.GetItemSearchResultsQuantity,req.itemKey);if ok then quantity=tonumber(v) or 0 end
        end
    end

    if (not has or (has and not full and quantity==0)) and req.attempts<4 then
        FM:After(.08,function() A:AttemptSearch(req) end)
        return
    end

    self.activeSearch=nil
    self:Remove(req.queueTag)
    if req.onReady then pcall(req.onReady,req.itemKey,{has=has,full=full,quantity=quantity,keyInfo=self:GetItemKeyInfo(req.itemKey)}) end
end

function A:SendBrowse(query,onSent,onError)
    return self:Enqueue("browse",function() C_AuctionHouse.SendBrowseQuery(query) end,onError,onSent)
end

function A:RequestMoreBrowse(onError)
    if type(C_AuctionHouse.RequestMoreBrowseResults)~="function" then return false end
    return self:Enqueue("browse-more",function() C_AuctionHouse.RequestMoreBrowseResults() end,onError)
end

function A:QueryOwned(onSent,onError)
    if type(C_AuctionHouse.QueryOwnedAuctions)~="function" then
        if onError then onError("Owned-auction queries are unavailable.") end
        return false
    end
    return self:Enqueue("owned",function()
        C_AuctionHouse.QueryOwnedAuctions({{sortOrder=1,reverseSort=false}})
    end,onError,onSent)
end

function A:Stop()
    self:ClearQueue();self:CancelSearch();self.dispatching=false
end

FM:On("ITEM_SEARCH_RESULTS_UPDATED",function(itemKey) A:SearchEvent(false,itemKey) end)
FM:On("COMMODITY_SEARCH_RESULTS_UPDATED",function(itemID) A:SearchEvent(true,itemID) end)
FM:On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY",function() A:ServerStateChanged() end)
FM:On("AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED",function() A:ServerStateChanged() end)
FM:On("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT",function() A:ServerStateChanged() end)
FM:On("AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED",function() A:ServerStateChanged() end)
FM:On("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",function()
    local req=A.activeSearch
    if req and req.attempts<4 then FM:After(.12,function() if A.activeSearch==req then A:AttemptSearch(req) end end) end
    A:ServerStateChanged()
end)
FM:On("AUCTION_HOUSE_BROWSE_FAILURE",function() A:ServerStateChanged() end)
FM:On("AUCTION_HOUSE_CLOSED",function() A:Stop() end)
FM:On("ITEM_KEY_ITEM_INFO_RECEIVED",function(itemID)
    local req=A.activeSearch
    if req and tonumber(req.itemKey and req.itemKey.itemID)==tonumber(itemID) then A:AttemptSearch(req) end
end)
