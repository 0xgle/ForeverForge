local _,FM=...
local M={results={},owned={},bids={},ownerChecks={},generation=0,open=false,page=0,total=0,ownerPage=0};FM.Market=M
local function same(a,b)
    return a and b and a.key==b.key and a.link==b.link and a.name==b.name and a.count==b.count and a.buyout==b.buyout and a.bid==b.bid and a.minBid==b.minBid and a.owner==b.owner
end
function M:IsMine(owner)
    local name,realm=UnitFullName("player");name=name or UnitName("player")
    return owner==name or owner==name.."-"..(realm or GetRealmName()):gsub("%s","")
end
function M:Ready()
    if not self.open then FM:Status("Visit an auctioneer and open the Auction House.");return false end
    if not FM:Supported() then FM:Status("Unsupported auction API. Use the Blizzard interface.");return false end
    if InCombatLockdown() then FM:Status("Trading is paused during combat.");return false end
    if self.transaction then FM:Status("Wait for the previous request to finish.");return false end
    return true
end
function M:Invalidate()
    self.generation=self.generation+1
    if FM.UI then FM.UI:DismissConfirm() end
end
function M:Stop()
    if self.transaction then self.transaction.log.status="tracking stopped; check mail/auctions" end
    self:Invalidate();self.request=nil;self.queued=nil;self.transaction=nil;self.mode=nil
end
function M:Search(text,page,exact,filters)
    if not self:Ready() then return end
    text=tostring(text or ""):match("^%s*(.-)%s*$")
    if #text>63 then FM:Status("The name is too long (maximum 63 bytes).");return end
    if self.request then FM:Status("Search in progress. Please wait or click Stop.");return end
    self:Queue({text=text,page=math.max(0,page or 0),exact=not not exact,full=false,filters=filters})
end
function M:FullScan()
    if not self:Ready() or self.request then return end
    local can,all=CanSendAuctionQuery()
    if not can or not all then FM:Status("Full scan is on server cooldown. Use Search instead.");return end
    self:Queue({text="",page=0,exact=false,full=true})
end
function M:Queue(q)
    self:Invalidate();self.results={};self.queued=q;q.started=GetTime()
    FM:Status("Waiting for the next available query...");FM:Refresh();self:SendQueued()
end
function M:SendQueued()
    local q=self.queued;if not q or not self.open then return end
    if GetTime()-q.started>25 then self.queued=nil;FM:Status("The server did not accept the query. Try again.");return end
    local can,all=CanSendAuctionQuery()
    if not can then FM:After(.3,function() M:SendQueued() end);return end
    if q.full and not all then self.queued=nil;FM:Status("Full scan is on cooldown.");return end
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
    FM:Status(q.full and "Full market scan: waiting for data..." or "Searching: "..(q.text~="" and q.text or "all items"))
    FM:After(q.full and 90 or 25,function()
        if M.request==q then M.request=nil;M:Invalidate();FM:Status("Incomplete response. Please search again.");FM:Refresh() end
    end)
end
function M:ReadRow(kind,index)
    local name,texture,count,quality,usable,level,header,minBid,increment,buyout,bid,highBidder,bidder,owner,fullOwner,saleStatus,itemID,complete=GetAuctionItemInfo(kind,index)
    if not name or count==nil then return nil end
    -- Classic Era keeps recently sold owner rows with count=0 / saleStatus=1.
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
function M:BeginTransaction(kind,row,amount)
    local t={kind=kind,row=row,amount=amount,log=FM:Log(kind,row,amount,"request sent")};self.transaction=t
    FM:After(12,function()
        if M.transaction==t then t.log.status="unconfirmed";M.transaction=nil;FM:Status("No confirmation received. Check your auctions/mail before retrying.");FM:Refresh() end
    end)
    return t
end
function M:Buy(row,bidding)
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
    if self.transaction then self.transaction.log.status="Error: "..tostring(errorText);self.transaction=nil end
    FM:Status(tostring(errorText));FM:Refresh()
end
function M:RefreshOwned()
    if not self:Ready() then return end
    if type(GetOwnerAuctionItems)~="function" then FM:Status("Owned-auction queries are unavailable on this client.");return end
    self.ownerPage=0;self.owned={};self.ownerLoading=true;self.ownerGeneration=(self.ownerGeneration or 0)+1
    local ok,err=pcall(GetOwnerAuctionItems)
    if not ok then
        self.ownerLoading=false;FM:Status("Could not load your auctions: "..tostring(err));FM:Refresh();return
    end
    FM:Status("Loading your auctions...");FM:Refresh()
    -- Classic Era normally fires AUCTION_OWNED_LIST_UPDATE. Read the cache as a
    -- fallback as well, because some clients do not emit a fresh event every time.
    local requestGeneration=self.ownerGeneration
    FM:After(.35,function()
        if M.open and M.ownerLoading and M.ownerGeneration==requestGeneration then M:ReadOwned() end
    end)
end
function M:ReadOwned()
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
        if r.key==pending.key and r.unit>0 and not self:IsMine(r.owner) then
            competitors=competitors+1;lowest=math.min(lowest or r.unit,r.unit)
        end
    end
    self.ownerChecks[pending.key]={lowest=lowest,competitors=competitors,checked=time()}
    FM:Status(competitors>0 and ("Price check complete. Lowest competitor: "..FM:Money(lowest).." / item.") or "Price check complete. No competing buyout found on the loaded page.")
end
function M:RefreshBids()
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
    if not self:Valid(row,"owner") then return end
    if CanCancelAuction and not CanCancelAuction(row.index) then FM:Status("This auction cannot be cancelled.");return end
    FM.UI:Confirm("Cancel auction",row,(row.link or row.name).."\nThe deposit will be lost. Your item will return by mail.\nAn active bid may result in an additional fee.",function()
        if not M:Valid(row,"owner") then return end
        if CanCancelAuction and not CanCancelAuction(row.index) then return end
        M:BeginTransaction("Cancellation",row,0)
        local ok,err=pcall(CancelAuction,row.index);if not ok then M:FailTransaction(err) end
    end)
end
FM:On("AUCTION_ITEM_LIST_UPDATE",function()
    local token=M.generation
    FM:After(.05,function() if token==M.generation then M:ReadBrowse() end end)
end)
FM:On("AUCTION_OWNED_LIST_UPDATE",function() M:ReadOwned() end)
FM:On("AUCTION_BIDDER_LIST_UPDATE",function() M:ReadBids() end)
FM:On("UI_ERROR_MESSAGE",function(_,msg) if M.transaction then M:FailTransaction(msg) end end)
FM:On("CHAT_MSG_SYSTEM",function(msg)
    local t=M.transaction;if not t then return end
    local accepted=(t.kind=="Purchase" or t.kind=="Bid") and ERR_AUCTION_BID_PLACED and msg==ERR_AUCTION_BID_PLACED
        or t.kind=="Posting" and ERR_AUCTION_STARTED and msg==ERR_AUCTION_STARTED
        or t.kind=="Cancellation" and ERR_AUCTION_REMOVED and msg==ERR_AUCTION_REMOVED
    if accepted then
        t.log.status="accepted by server";M.transaction=nil
        if FM.Ledger then
            if t.kind=="Purchase" then FM.Ledger:Record("BUY",t.row,t.amount,t.row and t.row.count,(t.row and t.row.flipCandidate) and "Flip purchase" or "Server accepted purchase")
            elseif t.kind=="Posting" then FM.Ledger:Record("POST",t.row,t.amount,t.row and t.row.count,"Server accepted posting")
            elseif t.kind=="Cancellation" then FM.Ledger:Record("CANCEL",t.row,0,t.row and t.row.count,"Server accepted cancellation") end
        end
        FM:Status("Request accepted by the server. Collect items and proceeds from your mailbox.");FM:Refresh()
        if t.kind=="Posting" or t.kind=="Cancellation" then
            -- The owner list can lag behind the posting/cancel confirmation on Classic Era.
            -- Ask the server again after the transaction has settled.
            FM:After(.25,function() if M.open and not M.transaction then M:RefreshOwned() end end)
        end
    end
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
