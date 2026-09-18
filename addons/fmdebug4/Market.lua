local _,FM=...
local M={results={},owned={},bids={},ownerChecks={},generation=0,open=false,page=0,total=0,ownerPage=0};FM.Market=M
local function same(a,b)
    return a and b and a.key==b.key and a.link==b.link and a.name==b.name and a.count==b.count and a.buyout==b.buyout and a.bid==b.bid and a.minBid==b.minBid and a.owner==b.owner
end

local function modern()
    return FM:IsModernAH()
end

local function itemKeyEqual(a,b)
    if type(a)~="table" or type(b)~="table" then return false end
    return (a.itemID or 0)==(b.itemID or 0)
        and (a.itemLevel or 0)==(b.itemLevel or 0)
        and (a.itemSuffix or 0)==(b.itemSuffix or 0)
        and (a.battlePetSpeciesID or 0)==(b.battlePetSpeciesID or 0)
end

local function timeBucket(seconds)
    seconds=tonumber(seconds) or 0
    if seconds<=0 then return 4 end
    if seconds<1800 then return 1 end
    if seconds<7200 then return 2 end
    if seconds<43200 then return 3 end
    return 4
end

local function modernItemInfo(itemKey,itemLink)
    local info
    if C_AuctionHouse and type(C_AuctionHouse.GetItemKeyInfo)=="function" and itemKey then
        local ok,v=pcall(C_AuctionHouse.GetItemKeyInfo,itemKey)
        if ok then info=v end
    end
    local itemID=itemKey and itemKey.itemID
    local name,link,quality,_,_,_,_,_,_,texture=FM:GetItemInfo(itemLink or itemID)
    return {
        name=(info and info.itemName) or name or ("Item "..tostring(itemID or "?")),
        link=itemLink or link,
        quality=(info and info.quality) or quality or 1,
        texture=(info and info.iconFileID) or texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        isCommodity=info and info.isCommodity,
    }
end

local QUALITY_FILTERS={
    [0]="PoorQuality",[1]="CommonQuality",[2]="UncommonQuality",[3]="RareQuality",
    [4]="EpicQuality",[5]="LegendaryQuality",[6]="ArtifactQuality",
}

function M:ModernBrowseQuery(q)
    local f=q.filters or {}
    local filters={}
    if f.quality~=nil and Enum and Enum.AuctionHouseFilter then
        local key=QUALITY_FILTERS[f.quality]
        local value=key and Enum.AuctionHouseFilter[key]
        if value~=nil then filters[#filters+1]=value end
    end
    if f.usable and Enum and Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.Usable~=nil then
        filters[#filters+1]=Enum.AuctionHouseFilter.Usable
    end
    local classes={}
    if f.classID~=nil then
        classes[1]={classID=f.classID,subClassID=f.subClassID,inventoryType=nil}
    end
    return {
        searchString=q.text or "",
        minLevel=f.minLevel,
        maxLevel=f.maxLevel,
        filters=filters,
        itemClassFilters=classes,
        sorts={},
    }
end

function M:ReadBrowseModern()
    if not self.open or not C_AuctionHouse or not self.request then return end
    local ok,raw=pcall(C_AuctionHouse.GetBrowseResults)
    if not ok or type(raw)~="table" then
        self.request=nil
        FM:Status("Could not read Auction House browse results.")
        FM:Refresh()
        return
    end

    local q=self.request
    local data={}
    for i,b in ipairs(raw) do
        local key=b.itemKey
        local meta=modernItemInfo(key)
        local exactOK=true
        if q and q.exact and q.text~="" and not meta.name:match("^Item %d+$") then
            exactOK=meta.name:lower()==q.text:lower()
        end
        if exactOK then
            local unit=tonumber(b.minPrice) or 0
            local itemID=key and key.itemID
            local row={
                index=i,
                modern=true,
                summary=true,
                itemKey=key,
                itemID=itemID,
                name=meta.name,
                texture=meta.texture,
                quality=meta.quality,
                link=meta.link,
                isCommodity=meta.isCommodity,
                count=tonumber(b.totalQuantity) or 1,
                availableQuantity=tonumber(b.totalQuantity) or 1,
                minBid=0,
                increment=0,
                buyout=unit,
                bid=0,
                highBidder=false,
                containsOwnerItem=not not b.containsOwnerItem,
                containsAccountItem=not not b.containsAccountItem,
                owner=b.containsOwnerItem and "Includes yours" or "Market",
                key=FM:ItemKey(meta.link,meta.name),
                unit=unit,
                complete=true,
                kind="modern-browse",
                generation=self.generation,
                actionable=true,
                saleStatus=0,
                seen=time(),
            }
            data[#data+1]=row
        end
    end

    local full=true
    if type(C_AuctionHouse.HasFullBrowseResults)=="function" then
        local okFull,v=pcall(C_AuctionHouse.HasFullBrowseResults)
        full=okFull and v~=false
    end

    self.results=data
    self.total=#data
    self.page=0
    if full then
        self.request=nil
        if q then
            FM:Observe(data,q.full and "full" or "page")
            FM.Data.stats.scans=(FM.Data.stats.scans or 0)+1
            FM.Data.stats.seen=(FM.Data.stats.seen or 0)+#data
            if q.full then FM.Data.stats.lastFull=time() end
        end
    elseif type(C_AuctionHouse.RequestMoreBrowseResults)=="function" then
        local now=GetTime()
        if not self.lastMoreRequest or now-self.lastMoreRequest>.2 then
            self.lastMoreRequest=now
            if FM.AuctionService then FM.AuctionService:RequestMoreBrowse() end
        end
    end

    local groups={}
    for _,r in ipairs(data) do
        if r.unit>0 then groups[r.key]=groups[r.key] or {};groups[r.key][#groups[r.key]+1]=r.unit end
    end
    for _,prices in pairs(groups) do table.sort(prices) end
    for _,r in ipairs(data) do
        local h=FM:GetHistoryStats(r.key)
        if h and time()-h.t<7*86400 and h.count>=2 then
            r.reference=h.median;r.referenceSource="history"
        end
        if r.reference and r.unit>0 then r.deal=r.unit/r.reference end
    end

    FM:Status(full and (string.format("%d market results loaded.",#data)) or (string.format("%d results loaded; receiving more...",#data)))
    if self.ownerCheck and full then self:FinishOwnedCheck() end
    if FM.Sell and FM.Sell.pendingCheck and full then FM.Sell:OnMarketResults() end
    if FM.Trader and FM.Trader.scan and full then FM.Trader:OnMarketResults() end
    if FM.ShoppingScan and FM.ShoppingScan.scan and full then FM.ShoppingScan:OnMarketResults() end
    if FM.Flip and (FM.Flip.scan or FM.Flip.review) and full then FM.Flip:OnMarketResults() end
    FM:Refresh()
end

function M:ReadOwnedModern(silent)
    if not self.open or not C_AuctionHouse then
        self.ownerLoading=false
        return
    end
    local n=0
    if type(C_AuctionHouse.GetNumOwnedAuctions)=="function" then
        local ok,v=pcall(C_AuctionHouse.GetNumOwnedAuctions);if ok then n=tonumber(v) or 0 end
    end
    local wasLoading=self.ownerLoading
    self.ownerLoading=false
    self.ownerGeneration=(self.ownerGeneration or 0)+1
    self.ownerTotal=n
    self.owned={}
    local player=UnitName("player") or "You"
    for i=1,n do
        local ok,info=pcall(C_AuctionHouse.GetOwnedAuctionInfo,i)
        if ok and info then
            local meta=modernItemInfo(info.itemKey,info.itemLink)
            local quantity=tonumber(info.quantity) or 1
            local price=tonumber(info.buyoutAmount) or 0
            local bid=tonumber(info.bidAmount) or 0
            local unit=price>0 and price or (bid>0 and bid or 0)
            local row={
                index=i,auctionID=info.auctionID,modern=true,itemKey=info.itemKey,itemID=info.itemKey and info.itemKey.itemID,
                name=meta.name,texture=meta.texture,quality=meta.quality,link=info.itemLink or meta.link,
                count=quantity,buyout=price,bid=bid,minBid=bid,increment=0,owner=player,
                key=FM:ItemKey(info.itemLink or meta.link,meta.name),unit=unit,complete=true,kind="owner",
                ownerGeneration=self.ownerGeneration,saleStatus=tonumber(info.status) or 0,
                timeLeft=timeBucket(info.timeLeftSeconds),timeLeftSeconds=info.timeLeftSeconds,seen=time(),
            }
            self.owned[#self.owned+1]=row
        end
    end
    if FM.Ledger then FM.Ledger:ObserveOwned(self.owned) end
    if not silent and wasLoading and FM.UI and FM.UI.activeTab=="Owned" then
        FM:Status(n==0 and "No active auctions found." or (tostring(n).." active auction"..(n==1 and "" or "s").." loaded."))
    end
    FM:Refresh()
end

function M:RefreshOwnedModern(silent)
    if not self:Ready() then return end
    if not (C_AuctionHouse and type(C_AuctionHouse.QueryOwnedAuctions)=="function") then
        FM:Status("Owned-auction queries are unavailable on this client.");return
    end
    local A=FM.AuctionService
    if not A then if not silent then FM:Status("Auction House service is unavailable.") end;return end

    self.ownerLoading=true
    if not silent then self.owned={} end
    self.ownerGeneration=(self.ownerGeneration or 0)+1
    local requestGeneration=self.ownerGeneration
    local sent=false

    A:QueryOwned(function()
        sent=true
        if not silent and FM.UI and FM.UI.activeTab=="Owned" then FM:Status("Loading your auctions...") end
        -- OWNED_AUCTIONS_UPDATED is authoritative. The short cache read only
        -- prevents UI stalls on Forever builds that occasionally miss it.
        FM:After(.75,function()
            if M.open and M.ownerLoading and M.ownerGeneration==requestGeneration then M:ReadOwnedModern(silent) end
        end)
    end,function(err)
        M.ownerLoading=false
        if not silent then FM:Status("Could not load your auctions: "..tostring(err)) end
        FM:Refresh()
    end)

    -- A queued owned request must never leave the page in an endless loading
    -- state if the throttle never becomes ready. Sell is completely independent
    -- from this request.
    FM:After(5,function()
        if M.open and M.ownerLoading and M.ownerGeneration==requestGeneration then
            M.ownerLoading=false
            if sent then M:ReadOwnedModern(silent) elseif not silent and FM.UI and FM.UI.activeTab=="Owned" then FM:Status("Auction House is busy. Click Refresh to load your auctions.") end
            FM:Refresh()
        end
    end)
    FM:Refresh()
end

function M:BuyModern(row,bidding)
    if not self:Ready() or not row or not row.itemKey then return end
    if self.request or self.queued then FM:Status("Wait for the current market search to finish before buying.");return end
    local A=FM.AuctionService
    if not A or not A:IsModern() then FM:Status("Modern Auction House service is unavailable.");return end
    if self.purchasePending or self.commodityPurchase then FM:Status("Finish the current purchase first.");return end

    self.purchasePending={row=row,bidding=not not bidding,kind="resolving"}
    FM:Status("Loading live offers for "..tostring(row.name).."...")

    A:SearchItem(row.itemKey,{owner="buy",timeout=8,onCancel=function()
        if M.purchasePending and M.purchasePending.row==row then M.purchasePending=nil end
    end},function(itemKey,meta)
        local pending=M.purchasePending
        if not pending or pending.row~=row then return end
        M.purchasePending=nil
        row.isCommodity=meta and meta.keyInfo and not not meta.keyInfo.isCommodity or false
        if row.isCommodity then
            M:PrepareCommodityPurchase(row,1)
        else
            M:PrepareItemPurchase(row,pending.bidding,itemKey)
        end
    end,function(err)
        if M.purchasePending and M.purchasePending.row==row then M.purchasePending=nil end
        FM:Status(tostring(err).." Click Buy again after the market settles.")
        FM:Refresh()
    end)
end

function M:PrepareItemPurchase(row,bidding,itemKey)
    local n=tonumber(C_AuctionHouse.GetNumItemSearchResults(itemKey)) or 0
    local best,bestAmount
    for i=1,n do
        local info=C_AuctionHouse.GetItemSearchResultInfo(itemKey,i)
        if info and not info.containsOwnerItem and not info.containsAccountItem then
            local amount
            if bidding then
                amount=tonumber(info.bidAmount) or tonumber(info.minBid) or tonumber(info.buyoutAmount)
            else
                amount=tonumber(info.buyoutAmount)
            end
            if amount and amount>0 and (not bestAmount or amount<bestAmount) then
                best,bestAmount=info,amount
            end
        end
    end

    if not best then
        FM:Status(bidding and "No auction is currently available to bid on." or "No buyout is currently available.")
        return
    end
    if bestAmount>GetMoney() then FM:Status("You do not have enough gold.");return end

    local live={
        name=row.name,link=best.itemLink or row.link,key=row.key,
        count=tonumber(best.quantity) or 1,buyout=tonumber(best.buyoutAmount) or 0,bid=tonumber(best.bidAmount) or 0,
        auctionID=best.auctionID,itemKey=best.itemKey or itemKey,modern=true,
    }
    local label=bidding and "Bid" or "Purchase"
    FM.UI:Confirm(label,live,(live.link or live.name).."\nQuantity: "..live.count.."  |  Total: "..FM:Money(bestAmount),function()
        if not M:Ready() then return end
        if GetMoney()<bestAmount then FM:Status("You do not have enough gold.");return end
        if type(C_AuctionHouse.PlaceBid)~="function" then FM:Status("Buying is unavailable on this client.");return end

        -- PlaceBid is a protected user action. Keep it on this click path and
        -- do not serialize it through the query throttle or a receipt lock.
        C_AuctionHouse.PlaceBid(best.auctionID,bestAmount)
        M.recentAction={kind=bidding and "Bid" or "Purchase",row=live,amount=bestAmount,started=GetTime()}
        FM:Log(M.recentAction.kind,live,bestAmount,"submitted")
        FM:Status(label.." submitted. Updating live offers...")
        M:ScheduleModernMarketRefresh(.5)
    end)
end

function M:PrepareCommodityPurchase(row,quantity)
    local itemID=tonumber(row.itemID or (row.itemKey and row.itemKey.itemID))
    if not itemID then FM:Status("Commodity item ID is unavailable.");return end
    quantity=math.max(1,math.floor(tonumber(quantity) or 1))

    local available=tonumber(C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID)) or 0
    local num=tonumber(C_AuctionHouse.GetNumCommoditySearchResults(itemID)) or 0
    if available<=0 and num>0 then
        for i=1,num do
            local r=C_AuctionHouse.GetCommoditySearchResultInfo(itemID,i)
            if r then available=available+(tonumber(r.quantity) or 0) end
        end
    end
    local first=num>0 and C_AuctionHouse.GetCommoditySearchResultInfo(itemID,1) or nil
    local firstPrice=first and tonumber(first.unitPrice) or 0
    if available<quantity or firstPrice<=0 then
        FM:Status("This commodity is no longer available. Refresh Deals and try again.")
        return
    end

    FM.UI:Confirm("Buy commodity",row,
        (row.link or row.name).."\nQuantity: "..quantity.."  |  Current unit price: "..FM:Money(firstPrice)..
        "\nThe server will return the exact total before the final confirmation.",
        function()
            if not M:Ready() then return end
            if type(C_AuctionHouse.StartCommoditiesPurchase)~="function" then FM:Status("Commodity buying is unavailable on this client.");return end
            if M.commodityPurchase and C_AuctionHouse.CancelCommoditiesPurchase then pcall(C_AuctionHouse.CancelCommoditiesPurchase) end
            M.commodityPurchase={row=row,quantity=quantity,previewUnitPrice=firstPrice,itemID=itemID,started=GetTime()}
            C_AuctionHouse.StartCommoditiesPurchase(itemID,quantity)
            FM:Status("Checking the current commodity price...")
        end)
end

function M:ModernCommodityPrice(unitPrice,totalPrice)
    local pending=self.commodityPurchase
    if not pending then return end
    unitPrice=tonumber(unitPrice) or 0
    totalPrice=tonumber(totalPrice) or (unitPrice*pending.quantity)
    local row=pending.row

    FM.UI:Confirm("Purchase",row,(row.link or row.name).."\nQuantity: "..pending.quantity.."  |  Total: "..FM:Money(totalPrice).."\nUnit price: "..FM:Money(unitPrice),function()
        if not M:Ready() then return end
        if GetMoney()<totalPrice then
            if C_AuctionHouse.CancelCommoditiesPurchase then pcall(C_AuctionHouse.CancelCommoditiesPurchase) end
            M.commodityPurchase=nil
            FM:Status("You do not have enough gold.")
            return
        end
        if type(C_AuctionHouse.ConfirmCommoditiesPurchase)~="function" then
            M.commodityPurchase=nil;FM:Status("Commodity confirmation is unavailable on this client.");return
        end

        local txRow={}
        for k,v in pairs(row) do txRow[k]=v end
        txRow.count=pending.quantity
        C_AuctionHouse.ConfirmCommoditiesPurchase(pending.itemID,pending.quantity)
        M.commodityPurchase=nil
        M.recentAction={kind="Purchase",row=txRow,amount=totalPrice,started=GetTime()}
        FM:Log("Purchase",txRow,totalPrice,"submitted")
        FM:Status("Purchase submitted. Updating live offers...")
        M:ScheduleModernMarketRefresh(.5)
    end,function()
        if C_AuctionHouse and C_AuctionHouse.CancelCommoditiesPurchase then pcall(C_AuctionHouse.CancelCommoditiesPurchase) end
        M.commodityPurchase=nil
        FM:Status("Commodity purchase cancelled.")
    end)
end
function M:IsMine(owner)
    if owner=="player" or owner=="You" or owner=="Includes yours" then return true end
    local name,realm=UnitFullName("player");name=name or UnitName("player")
    return owner==name or owner==name.."-"..(realm or GetRealmName()):gsub("%s","")
end
function M:Ready()
    if not self.open then FM:Status("Visit an auctioneer and open the Auction House.");return false end
    if not FM:Supported() then FM:Status("Unsupported auction API. Use the Blizzard interface.");return false end
    if InCombatLockdown() then FM:Status("Trading is paused during combat.");return false end
    if self.transaction and not modern() then FM:Status("Wait for the previous request to finish.");return false end
    return true
end
function M:Invalidate()
    self.generation=self.generation+1
    if FM.UI then FM.UI:DismissConfirm() end
end
function M:Stop()
    if self.transaction then self.transaction.log.status="tracking stopped; check mail/auctions" end
    if self.commodityPurchase and C_AuctionHouse and C_AuctionHouse.CancelCommoditiesPurchase then
        pcall(C_AuctionHouse.CancelCommoditiesPurchase)
    end
    self:Invalidate();self.request=nil;self.queued=nil;self.transaction=nil;self.mode=nil
    self.purchasePending=nil;self.commodityPurchase=nil;self.recentAction=nil
    if FM.AuctionService then FM.AuctionService:Stop() end
end
function M:Search(text,page,exact,filters)
    if not self:Ready() then return end
    if self.purchasePending or self.commodityPurchase then FM:Status("Finish the current purchase first.");return end
    text=tostring(text or ""):match("^%s*(.-)%s*$")
    if #text>63 then FM:Status("The name is too long (maximum 63 bytes).");return end
    if self.request then FM:Status("Search in progress. Please wait or click Stop.");return end
    self:Queue({text=text,page=math.max(0,page or 0),exact=not not exact,full=false,filters=filters})
end
function M:FullScan()
    if not self:Ready() or self.request then return end
    if self.purchasePending or self.commodityPurchase then FM:Status("Finish the current purchase first.");return end
    if modern() then
        self:Queue({text="",page=0,exact=false,full=true})
        return
    end
    local can,all=CanSendAuctionQuery()
    if not can or not all then FM:Status("Full scan is on server cooldown. Use Search instead.");return end
    self:Queue({text="",page=0,exact=false,full=true})
end
function M:Queue(q)
    if modern() and FM.AuctionService then FM.AuctionService:CancelSearch() end
    self.purchasePending=nil
    self:Invalidate();self.results={};self.queued=q;q.started=GetTime()
    FM:Status("Waiting for the next available query...");FM:Refresh();self:SendQueued()
end
function M:SendQueued()
    local q=self.queued;if not q or not self.open then return end
    if GetTime()-q.started>25 then self.queued=nil;FM:Status("The server did not accept the query. Try again.");return end

    if modern() then
        local A=FM.AuctionService
        if not A then self.queued=nil;FM:Status("Auction House service is unavailable.");return end
        local query=self:ModernBrowseQuery(q)
        A:Enqueue("browse",function()
            if M.queued~=q or not M.open then return end
            M.queued=nil;M.request=q;M.mode=q.full and "scan" or "search"
            M.page=0;M.query=q.text;M.exact=q.exact;M.filters=q.filters
            M.sending=true
            C_AuctionHouse.SendBrowseQuery(query)
            M.sending=false
            q.sentAt=GetTime()
            FM:Status(q.full and "Scanning the Auction House..." or "Searching: "..(q.text~="" and q.text or "all items"))
            FM:After(.5,function() if M.request==q then M:ReadBrowseModern() end end)
            FM:After(25,function()
                if M.request==q then M.request=nil;FM:Status("The Auction House query timed out. Search again.");FM:Refresh() end
            end)
        end,function(err)
            if M.queued==q then M.queued=nil end
            if M.request==q then M.request=nil end
            FM:Status("Query error: "..tostring(err));FM:Refresh()
        end,25)
        return
    end

    local can,all=CanSendAuctionQuery()
    if not can then FM:After(.3,function() M:SendQueued() end);return end
    if q.full and not all then self.queued=nil;FM:Status("Full scan is on server cooldown.");return end
    self.queued=nil;self.request=q;self.mode=q.full and "scan" or "search"
    self.page=q.page;self.query=q.text;self.exact=q.exact;self.filters=q.filters
    self.sending=true
    local f=q.filters or {}
    local filterData=nil
    if f.classID~=nil then
        filterData={{classID=f.classID,subClassID=f.subClassID,inventoryType=nil}}
    end
    local ok,err=pcall(QueryAuctionItems,q.text,f.minLevel,f.maxLevel,q.page,f.usable or false,f.quality,q.full,q.exact,filterData)
    self.sending=false
    if not ok then self.request=nil;FM:Status("Query error: "..tostring(err));return end
    q.sentAt=GetTime()
    FM:Status(q.full and "Full market scan: waiting for data..." or "Searching: "..(q.text~="" and q.text or "all items"))
    FM:After(.15,function() M:PollBrowse(q) end)
    FM:After(q.full and 90 or 25,function()
        if M.request==q then M.request=nil;M:Invalidate();FM:Status("Incomplete response. Please search again.");FM:Refresh() end
    end)
end
function M:PollBrowse(q)
    if modern() then return end
    if self.request~=q or not self.open then return end
    local batch,total=GetNumAuctionItems("list");batch=batch or 0;total=total or 0
    local age=GetTime()-(q.sentAt or GetTime())
    if age>=.35 and (batch>0 or total>0) then self:ReadBrowse();return end
    local can=false
    if age>=1 and type(CanSendAuctionQuery)=="function" then can=select(1,CanSendAuctionQuery()) and true or false end
    if (age>=1 and can) or age>=3 then self:ReadBrowse();return end
    FM:After(.15,function() M:PollBrowse(q) end)
end
function M:ReadRow(kind,index)
    local name,texture,count,quality,usable,level,header,minBid,increment,buyout,bid,highBidder,bidder,owner,fullOwner,saleStatus,itemID,complete=GetAuctionItemInfo(kind,index)
    if not name or count==nil then return nil end
    -- The legacy Auction House API can keep recently sold owner rows with count=0 / saleStatus=1.
    -- Preserve those rows so My Auctions can report SOLD instead of silently hiding them.
    if count<1 and not (kind=="owner" and saleStatus==1) then return nil end
    local link=GetAuctionItemLink(kind,index)
    local unit=(count>0 and buyout and buyout>0) and buyout/count or 0
    return {index=index,name=name,texture=texture,count=count,quality=quality or 1,minBid=minBid or 0,increment=increment or 0,
        buyout=buyout or 0,bid=bid or 0,highBidder=not not highBidder,owner=fullOwner or owner or "?",link=link,key=FM:ItemKey(link,name),
        unit=unit,complete=complete~=false and (kind=="owner" or (link~=nil and (owner~=nil or fullOwner~=nil))),
        saleStatus=saleStatus,kind=kind,generation=self.generation,itemID=itemID,seen=time()}
end
function M:ReadBrowse()
    if modern() then return self:ReadBrowseModern() end
    if not self.open or not self.mode then return end
    local batch,total=GetNumAuctionItems("list");batch=batch or 0;total=total or 0
    local q=self.request
    if q and batch==0 and total>0 then return end
    local data={};local complete=true
    for i=1,batch do
        local r=self:ReadRow("list",i)
        if r then data[#data+1]=r;if not r.complete then complete=false end else complete=false end
    end
    if q and not complete and (q.retries or 0)<15 then
        q.retries=(q.retries or 0)+1
        FM:After(.25,function() if M.request==q then M:ReadBrowse() end end);return
    end
    self:Invalidate()
    local historyCache={}
    for _,r in ipairs(data) do
        r.generation=self.generation;r.actionable=self.mode=="search" and complete
        if historyCache[r.key]==nil then historyCache[r.key]=FM:GetHistoryStats(r.key) or false end
        r.market=historyCache[r.key] or nil
    end
    self.results=data;self.total=total;self.request=nil
    if q then
        FM:Observe(data,q.full and "full" or "page")
        FM.Data.stats.scans=(FM.Data.stats.scans or 0)+1
        FM.Data.stats.seen=(FM.Data.stats.seen or 0)+#data
        if q.full then FM.Data.stats.lastFull=time() end
    end
    -- Current-query medians are a clearly labelled fallback, not a global market price.
    local groups={}
    for _,r in ipairs(data) do if r.unit>0 then groups[r.key]=groups[r.key] or {};table.insert(groups[r.key],r.unit) end end
    for _,prices in pairs(groups) do table.sort(prices) end
    for _,r in ipairs(data) do
        local prices=groups[r.key] or {};local n=#prices
        if r.market and time()-r.market.t<7*86400 and r.market.count>=2 then r.reference=r.market.median;r.referenceSource="history"
        elseif n>=3 then r.reference=(prices[math.floor((n+1)/2)]+prices[math.ceil((n+1)/2)])/2;r.referenceSource="results" end
        if r.reference and r.unit>0 then r.deal=r.unit/r.reference end
    end
    FM:Status(string.format("%d auctions / %d on server | %s%s",#data,total,self.mode=="scan" and "Scan results: search again before buying" or ("page "..(self.page+1)),complete and "" or " | incomplete data"))
    if self.ownerCheck then self:FinishOwnedCheck() end
    if FM.Sell and FM.Sell.pendingCheck then FM.Sell:OnMarketResults() end
    if FM.Trader and FM.Trader.scan then FM.Trader:OnMarketResults() end
    if FM.ShoppingScan and FM.ShoppingScan.scan then FM.ShoppingScan:OnMarketResults() end
    if FM.Flip and (FM.Flip.scan or FM.Flip.review) then FM.Flip:OnMarketResults() end
    FM:Refresh()
end
function M:Valid(row,kind)
    if not self:Ready() or self.request or self.queued or not row then return false end
    if kind=="list" and (not row.actionable or row.generation~=self.generation) then FM:Status("This auction is out of date. Search again.");return false end
    if kind=="owner" and row.ownerGeneration~=self.ownerGeneration then FM:Status("The auction list has changed.");return false end
    if kind=="bidder" and row.bidderGeneration~=self.bidderGeneration then FM:Status("Your bids list has changed.");return false end
    local live=self:ReadRow(kind,row.index)
    if not live or not live.complete or not same(row,live) then FM:Status("This auction has changed. Refresh the list first.");return false end
    return true
end
function M:ScheduleModernMarketRefresh(delay)
    local query,page,exact,filters=self.query or "",self.page or 0,self.exact,self.filters
    FM:After(delay or .9,function()
        if not M.open or M.request or M.queued or M.purchasePending or M.commodityPurchase then return end
        M:Search(query,page,exact,filters)
    end)
end

function M:BeginTransaction(kind,row,amount,timeout)
    local t={kind=kind,row=row,amount=amount,log=FM:Log(kind,row,amount,"request sent")};self.transaction=t
    timeout=tonumber(timeout) or 12
    FM:After(timeout,function()
        if M.transaction==t then
            t.log.status="unconfirmed"
            M.transaction=nil
            FM:Status("The client sent the request but did not expose a final confirmation event. Refresh the market or check mail before retrying.")
            FM:Refresh()
        end
    end)
    return t
end
function M:Buy(row,bidding)
    if modern() then return self:BuyModern(row,bidding) end
    if not self:Valid(row,"list") then return end
    if self:IsMine(row.owner) then FM:Status("You cannot buy your own auction.");return end
    local amount=bidding and math.max(row.minBid,row.bid>0 and row.bid+math.max(1,row.increment) or 0) or row.buyout
    if amount<=0 then FM:Status("This auction has no buyout price.");return end
    if bidding and row.buyout>0 then amount=math.min(amount,row.buyout) end
    if amount>GetMoney() then FM:Status("You do not have enough gold.");return end
    local kind=bidding and "Bid" or "Purchase"
    local flipLine=""
    if row.flipCandidate and row.flipPlan then flipLine="\nFlip plan: exit "..FM:Money(row.flipPlan.exitUnit).." / item | net "..(row.flipPlan.profit>=0 and "+" or "-")..FM:Money(math.abs(row.flipPlan.profit)) end
    FM.UI:Confirm(kind,row,(row.link or row.name).."\nQuantity: "..row.count.."  |  Total: "..FM:Money(amount).."\nUnit price: "..FM:Money(amount/row.count)..flipLine,function()
        if not M:Valid(row,"list") or GetMoney()<amount then return end
        M:BeginTransaction(kind,row,amount)
        local ok,err=pcall(PlaceAuctionBid,"list",row.index,amount)
        if not ok then M:FailTransaction(err) else FM:Status("Request sent: "..kind:lower()..". Waiting for the server...") end
    end)
end
function M:FailTransaction(errorText)
    local kind=self.transaction and self.transaction.kind
    if self.transaction then self.transaction.log.status="Error: "..tostring(errorText);self.transaction=nil end
    if kind=="Posting" and FM.Native and FM.Native.pendingNativePost and FM.Native.FinishNativePostConfirmation then
        FM.Native:FinishNativePostConfirmation()
    end
    FM:Status(tostring(errorText));FM:Refresh()
end
function M:RefreshOwned()
    if modern() then return self:RefreshOwnedModern() end
    if not self:Ready() then return end
    if type(GetOwnerAuctionItems)~="function" then FM:Status("Owned-auction queries are unavailable on this client.");return end
    self.ownerPage=0;self.owned={};self.ownerLoading=true;self.ownerGeneration=(self.ownerGeneration or 0)+1
    local ok,err=pcall(GetOwnerAuctionItems)
    if not ok then
        self.ownerLoading=false;FM:Status("Could not load your auctions: "..tostring(err));FM:Refresh();return
    end
    FM:Status("Loading your auctions...");FM:Refresh()
    -- Read the cache as a fallback as well. WoW Forever builds can omit the
    -- legacy owner-list event while keeping the legacy owner query API.
    local requestGeneration=self.ownerGeneration
    FM:After(.35,function()
        if M.open and M.ownerLoading and M.ownerGeneration==requestGeneration then M:ReadOwned() end
    end)
end
function M:ReadOwned()
    if modern() then return self:ReadOwnedModern() end
    if not self.open then return end
    local n,total=GetNumAuctionItems("owner");n=n or 0
    self.ownerTotal=total or n or 0;self.ownerPage=0;self.ownerLoading=false
    self.ownerGeneration=(self.ownerGeneration or 0)+1;self.owned={}
    for i=1,n do
        local r=self:ReadRow("owner",i)
        if r then r.ownerGeneration=self.ownerGeneration;r.timeLeft=GetAuctionItemTimeLeft("owner",i);self.owned[#self.owned+1]=r end
    end
    if FM.Ledger then FM.Ledger:ObserveOwned(self.owned) end
    FM:Refresh()
end
function M:OwnerStatus(row)
    if not row then return "-" end
    if row.saleStatus==1 then return "SOLD" end
    if row.buyout<=0 or row.unit<=0 then return "BID ONLY" end
    local c=self.ownerChecks[row.key]
    if not c then return "NOT CHECKED" end
    if c.competitors==0 then return "ONLY YOU" end
    if c.lowest and c.lowest<row.unit then return "UNDERCUT" end
    if c.lowest and c.lowest==row.unit then return "MATCHED" end
    return "LOWEST"
end
function M:OwnerCheckText(row)
    local status=self:OwnerStatus(row);local c=row and self.ownerChecks[row.key]
    if status=="SOLD" then return "Sold. Collect the proceeds from your mailbox." end
    if status=="BID ONLY" then return "This auction has no buyout price." end
    if not c then return "Price not checked yet. Select the auction and click Check price." end
    local age=math.max(0,math.floor((time()-(c.checked or time()))/60))
    if c.competitors==0 then return "No competing buyout found on the loaded exact-name page | checked "..age.." min ago." end
    return status.." | lowest competitor: "..FM:Money(c.lowest or 0).." / item | "..c.competitors.." competing auctions | checked "..age.." min ago."
end
function M:CheckOwned(row)
    if not row then FM:Status("Select one of your auctions first.");return end
    if row.saleStatus==1 then FM:Status("This auction is already sold.");return end
    if row.buyout<=0 or row.unit<=0 then FM:Status("This auction has no buyout price to compare.");return end
    if self.request or self.queued then FM:Status("Wait for the current market query to finish.");return end
    if not self:Ready() then return end
    self.ownerCheck={key=row.key,name=row.name,started=time()}
    FM:Status("Checking competing prices for "..row.name.."...")
    self:Search(row.name,0,true)
end
function M:FinishOwnedCheck()
    local pending=self.ownerCheck;if not pending then return end
    self.ownerCheck=nil
    local lowest,competitors
    competitors=0
    for _,r in ipairs(self.results or {}) do
        if r.key==pending.key and r.unit>0 and (modern() or not self:IsMine(r.owner)) then
            competitors=competitors+1;lowest=math.min(lowest or r.unit,r.unit)
        end
    end
    self.ownerChecks[pending.key]={lowest=lowest,competitors=competitors,checked=time()}
    FM:Status(competitors>0 and ("Price check complete. Lowest competitor: "..FM:Money(lowest).." / item.") or "Price check complete. No competing buyout found on the loaded page.")
end
function M:RefreshBids()
    if modern() then
        self.bids={};self.bidderLoading=false
        FM:Status("This Auction House API does not expose a separate My Bids list.")
        FM:Refresh();return
    end
    if not self:Ready() then return end
    if type(GetBidderAuctionItems)~="function" then FM:Status("Bid queries are unavailable on this client.");return end
    self.bids={};self.bidderLoading=true;self.bidderGeneration=(self.bidderGeneration or 0)+1
    local ok,err=pcall(GetBidderAuctionItems)
    if not ok then self.bidderLoading=false;FM:Status("Could not load your bids: "..tostring(err));FM:Refresh();return end
    local token=self.bidderGeneration;FM:Status("Loading your bids...");FM:Refresh()
    FM:After(.35,function() if M.open and M.bidderLoading and M.bidderGeneration==token then M:ReadBids() end end)
end
function M:ReadBids()
    if not self.open then return end
    local n,total=GetNumAuctionItems("bidder");n=n or 0;self.bidderTotal=total or n;self.bidderLoading=false
    self.bidderGeneration=(self.bidderGeneration or 0)+1;self.bids={}
    for i=1,n do local r=self:ReadRow("bidder",i);if r then r.bidderGeneration=self.bidderGeneration;r.timeLeft=GetAuctionItemTimeLeft("bidder",i);self.bids[#self.bids+1]=r end end
    FM:Refresh()
end
function M:BidStatus(row)
    if not row then return "-" end
    if row.highBidder then return "WINNING" end
    if row.bid and row.bid>0 then return "OUTBID" end
    return "WATCHING"
end
function M:BidderBid(row,buyout)
    if modern() then FM:Status("Use the Market tab to place bids on this client.");return end
    if not self:Valid(row,"bidder") then return end
    local amount
    if buyout then amount=row.buyout else amount=math.max(row.minBid or 0,(row.bid or 0)+math.max(1,row.increment or 1));if row.buyout and row.buyout>0 then amount=math.min(amount,row.buyout) end end
    if not amount or amount<=0 then FM:Status("No valid bid amount is available.");return end
    if amount>GetMoney() then FM:Status("You do not have enough gold.");return end
    local label=buyout and "Buyout" or "Bid"
    FM.UI:Confirm(label,row,(row.link or row.name).."\nQuantity: "..row.count.." | Amount: "..FM:Money(amount).."\nStatus: "..self:BidStatus(row),function()
        if not M:Valid(row,"bidder") or GetMoney()<amount then return end
        M:BeginTransaction("Bid",row,amount);local ok,err=pcall(PlaceAuctionBid,"bidder",row.index,amount);if not ok then M:FailTransaction(err) else FM:Status("Bid request sent. Waiting for server confirmation...") end
    end)
end

function M:Cancel(row)
    if row and row.saleStatus==1 then FM:Status("Sold auctions cannot be cancelled. Collect the proceeds from your mailbox.");return end
    if modern() then
        if not self:Ready() or not row or not row.auctionID then return end
        if type(C_AuctionHouse.CancelAuction)~="function" then FM:Status("Cancellation is unavailable on this client.");return end
        if C_AuctionHouse.CanCancelAuction then
            local ok,can=pcall(C_AuctionHouse.CanCancelAuction,row.auctionID)
            if ok and not can then FM:Status("This auction cannot be cancelled.");return end
        end

        local cost=0
        if type(C_AuctionHouse.GetCancelCost)=="function" then
            local ok,v=pcall(C_AuctionHouse.GetCancelCost,row.auctionID)
            if ok then cost=tonumber(v) or 0 end
        end
        local details=(row.link or row.name).."\nThe item will return by mail."
        if cost>0 then details=details.."\nCancellation fee: "..FM:Money(cost) end
        FM.UI:Confirm("Cancel auction",row,details,function()
            if not M:Ready() then return end
            if C_AuctionHouse.CanCancelAuction then
                local ok,can=pcall(C_AuctionHouse.CanCancelAuction,row.auctionID)
                if ok and not can then FM:Status("This auction can no longer be cancelled.");return end
            end
            C_AuctionHouse.CancelAuction(row.auctionID)
            M.recentAction={kind="Cancellation",row=row,amount=cost,started=GetTime()}
            FM:Log("Cancellation",row,cost,"submitted")
            FM:Status("Cancellation submitted. Updating My Auctions...")
            FM:After(.35,function() if M.open then M:RefreshOwnedModern() end end)
        end)
        return
    end
    if not self:Valid(row,"owner") then return end
    if CanCancelAuction and not CanCancelAuction(row.index) then FM:Status("This auction cannot be cancelled.");return end
    FM.UI:Confirm("Cancel auction",row,(row.link or row.name).."\nThe deposit will be lost. Your item will return by mail.\nAn active bid may result in an additional fee.",function()
        if not M:Valid(row,"owner") then return end
        if CanCancelAuction and not CanCancelAuction(row.index) then return end
        M:BeginTransaction("Cancellation",row,0)
        local ok,err=pcall(CancelAuction,row.index);if not ok then M:FailTransaction(err) end
    end)
end
local function browseUpdated()
    if modern() then
        FM:After(.03,function() if M.open then M:ReadBrowseModern() end end)
        return
    end
    local token=M.generation
    FM:After(.05,function() if token==M.generation then M:ReadBrowse() end end)
end

FM:On("AUCTION_ITEM_LIST_UPDATE",browseUpdated)
FM:On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",browseUpdated)
FM:On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED",browseUpdated)
FM:On("AUCTION_HOUSE_BROWSE_FAILURE",function()
    if modern() then
        M.request=nil;M.queued=nil
        FM:Status("The Auction House rejected the search. Try again.")
        FM:Refresh()
    end
end)
FM:On("REPLICATE_ITEM_LIST_UPDATE",browseUpdated)

FM:On("COMMODITY_PRICE_UPDATED",function(unitPrice,totalPrice)
    if modern() then M:ModernCommodityPrice(unitPrice,totalPrice) end
end)
FM:On("COMMODITY_PRICE_UNAVAILABLE",function()
    if modern() and M.commodityPurchase then
        M.commodityPurchase=nil
        if C_AuctionHouse and C_AuctionHouse.CancelCommoditiesPurchase then pcall(C_AuctionHouse.CancelCommoditiesPurchase) end
        FM:Status("The commodity price changed or is no longer available.")
    end
end)

FM:On("AUCTION_OWNED_LIST_UPDATE",function() M:ReadOwned() end)
FM:On("OWNED_AUCTIONS_UPDATED",function()
    if modern() then
        if M.open then
            local silent=not (FM.UI and FM.UI.activeTab=="Owned")
            M:ReadOwnedModern(silent)
        end
    elseif M.ownerLoading then M:ReadOwned() end
end)
FM:On("AUCTION_BIDDER_LIST_UPDATE",function() M:ReadBids() end)
FM:On("BIDS_UPDATED",function() if M.bidderLoading then M:ReadBids() end end)
FM:On("AUCTION_HOUSE_SHOW_ERROR",function(_,msg)
    local text=tostring(msg or "Auction House rejected the request.")
    if FM.Sell and FM.Sell.pendingPost then FM.Sell.pendingPost=nil end
    if M.commodityPurchase and C_AuctionHouse and C_AuctionHouse.CancelCommoditiesPurchase then
        pcall(C_AuctionHouse.CancelCommoditiesPurchase)
        M.commodityPurchase=nil
    end
    M.recentAction=nil
    FM:Status("Auction House: "..text)
end)

FM:On("UI_ERROR_MESSAGE",function(_,msg)
    if modern() and FM.Sell and FM.Sell.pendingPost then
        FM.Sell.pendingPost=nil
        if FM.Native and FM.Native.FinishNativePostConfirmation then FM.Native:FinishNativePostConfirmation() end
        FM:Status("Auction House: "..tostring(msg))
    elseif modern() and M.commodityPurchase then
        if C_AuctionHouse and C_AuctionHouse.CancelCommoditiesPurchase then pcall(C_AuctionHouse.CancelCommoditiesPurchase) end
        M.commodityPurchase=nil
        FM:Status("Auction House: "..tostring(msg))
    elseif modern() and M.recentAction and GetTime()-(M.recentAction.started or 0)<3 then
        FM:Status("Auction House: "..tostring(msg))
        M.recentAction=nil
    elseif M.transaction then
        M:FailTransaction(msg)
    end
end)
function M:AcceptTransaction(kind)
    local t=self.transaction;if not t or (kind and t.kind~=kind) then return end
    t.log.status="accepted by server";self.transaction=nil
    if FM.Ledger then
        if t.kind=="Purchase" then FM.Ledger:Record("BUY",t.row,t.amount,t.row and t.row.count,(t.row and t.row.flipCandidate) and "Flip purchase" or "Server accepted purchase")
        elseif t.kind=="Posting" then FM.Ledger:Record("POST",t.row,t.amount,t.row and t.row.count,"Server accepted posting")
        elseif t.kind=="Cancellation" then FM.Ledger:Record("CANCEL",t.row,0,t.row and t.row.count,"Server accepted cancellation") end
    end
    FM:Status("Request accepted by the server. Collect items and proceeds from your mailbox.");FM:Refresh()
    if t.kind=="Posting" and FM.Native and FM.Native.FinishNativePostConfirmation then FM.Native:FinishNativePostConfirmation() end
    if t.kind=="Posting" or t.kind=="Cancellation" then
        FM:After(.25,function() if M.open and not M.transaction then M:RefreshOwned() end end)
    end
end
FM:On("CHAT_MSG_SYSTEM",function(msg)
    local t=M.transaction;if not t then return end
    local accepted=(t.kind=="Purchase" or t.kind=="Bid") and ERR_AUCTION_BID_PLACED and msg==ERR_AUCTION_BID_PLACED
        or t.kind=="Posting" and ERR_AUCTION_STARTED and msg==ERR_AUCTION_STARTED
        or t.kind=="Cancellation" and ERR_AUCTION_REMOVED and msg==ERR_AUCTION_REMOVED
    if accepted then M:AcceptTransaction() end
end)
FM:On("AUCTION_HOUSE_AUCTION_CREATED",function()
    if modern() then
        if FM.Sell and FM.Sell.OnModernPostAccepted then FM.Sell:OnModernPostAccepted() end
        if M.open then FM:After(.2,function() if M.open then M:RefreshOwnedModern(true) end end) end
    else
        M:AcceptTransaction("Posting")
    end
end)
FM:On("AUCTION_CANCELED",function()
    if modern() then
        M.recentAction=nil
        FM:Status("Auction cancelled.")
        if M.open then FM:After(.15,function() if M.open then M:RefreshOwnedModern() end end) end
    else
        M:AcceptTransaction("Cancellation")
    end
end)
FM:On("BID_ADDED",function()
    if modern() then M.recentAction=nil;FM:Status("Bid accepted.");M:ScheduleModernMarketRefresh(.15)
    else M:AcceptTransaction("Bid") end
end)
FM:On("ITEM_PURCHASED",function()
    if modern() then M.recentAction=nil;FM:Status("Purchase completed.");M:ScheduleModernMarketRefresh(.15)
    else M:AcceptTransaction("Purchase") end
end)
FM:On("COMMODITY_PURCHASE_SUCCEEDED",function()
    M.commodityPurchase=nil
    if modern() then M.recentAction=nil;FM:Status("Commodity purchase completed.");M:ScheduleModernMarketRefresh(.15)
    else M:AcceptTransaction("Purchase") end
end)
FM:On("COMMODITY_PURCHASE_FAILED",function()
    M.commodityPurchase=nil
    M.recentAction=nil
    if modern() then FM:Status("Commodity purchase failed. Refresh the offer and try again.")
    elseif M.transaction and M.transaction.kind=="Purchase" then M:FailTransaction("Commodity purchase failed.") end
end)
FM:On("PLAYER_LOGIN",function()
    if type(QueryAuctionItems)=="function" then
        hooksecurefunc("QueryAuctionItems",function()
            if not M.sending then
                M:Invalidate();M.request=nil;M.queued=nil;M.mode=nil;M.results={}
                FM:Status("Another interface sent a query. Search again in ForeverMarket.");FM:Refresh()
            end
        end)
    end
end)
