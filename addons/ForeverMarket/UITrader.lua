local _,FM=...
local U,T=FM.UI,FM.T

local function selectedGroup()
    FM.Groups:Ensure();local id=U.traderGroupId or "default";return id,FM.Data.groups[id],FM.Data.groups[id] and FM.Data.operations[FM.Data.groups[id].operation]
end

function U:BuildTrader()
    local p=self:NewPanel("Trader","Trader Engine / groups + operations","Group items, define price rules, then build live Post or Cancel plans.")
    T:Text(p,"GROUPS",10,0,62,220,T.gold)
    self.groupName=T:Edit(p,166,29,0,82,"")
    T:Button(p,"+",38,29,174,82,function()
        local id,err=FM.Groups:Create(U.groupName:GetText());if not id then FM:Status(err);return end
        U.groupName:SetText("");U.traderGroupId=id;U:RefreshTrader();FM:Status("Group created.")
    end,true)
    self.groupRows={}
    for i=1,7 do
        local r=T:Button(p,"",250,39,0,120+(i-1)*42,function(b) if b.data then U.traderGroupId=b.data.id;U:RefreshTrader() end end)
        r.name=T:Text(r,"",11,10,7,170,T.text);r.count=T:Text(r,"",10,186,9,52,T.muted);r.count:SetJustifyH("RIGHT")
        self.groupRows[i]=r
    end
    local assign=T:Panel(p,250,122,0,424)
    self.traderSelected=T:Text(assign,"Select an item in Sell",11,12,12,226,T.text);self.traderSelected:SetWordWrap(true);self.traderSelected:SetHeight(38)
    self.assignGroup=T:Button(assign,"Assign selected item",222,29,12,57,function()
        local item=FM.Sell.item;if not item then FM:Status("Select an item in Sell first.");return end
        local id=U.traderGroupId or "default";FM.Groups:Assign(item.key,id);FM:Status(item.name.." assigned to "..((FM.Data.groups[id] or {}).name or "Ungrouped")..".");U:RefreshTrader()
    end,true)
    T:Button(assign,"Remove from group",222,24,12,91,function()
        local item=FM.Sell.item;if not item then return end;FM.Groups:Assign(item.key,"default");FM:Status("Item returned to Ungrouped.");U:RefreshTrader()
    end)

    local op=T:Panel(p,622,304,270,62)
    self.traderTitle=T:Text(op,"OPERATION",13,15,13,390,T.gold)
    T:Text(op,"Min price rule",10,15,47,280,T.muted);self.opMin=T:Edit(op,286,29,15,63,"")
    T:Text(op,"Normal price rule",10,315,47,280,T.muted);self.opNormal=T:Edit(op,286,29,315,63,"")
    T:Text(op,"Max price rule",10,15,104,280,T.muted);self.opMax=T:Edit(op,286,29,15,120,"")
    T:Text(op,"Undercut (copper)",10,315,104,132,T.muted);self.opUndercut=T:Edit(op,132,29,315,120,"")
    T:Text(op,"Stack size (0=auto)",10,461,104,140,T.muted);self.opStack=T:Edit(op,140,29,461,120,"")
    T:Text(op,"Max stacks",10,15,161,132,T.muted);self.opCap=T:Edit(op,132,29,15,177,"")
    T:Text(op,"Keep in bags",10,161,161,132,T.muted);self.opKeep=T:Edit(op,132,29,161,177,"")
    self.opPreview=T:Text(op,"Rules: FMMarket, FMRecent, FMHistorical, FMMinBuyout, FMAvgBuy, FMAvgSell, FMVendorSell. Functions: min(), max(), avg(). Example: 80% FMMarket",10,15,221,586,T.muted)
    self.opPreview:SetWordWrap(true);self.opPreview:SetHeight(35)
    T:Button(op,"Save operation",180,31,421,255,function() U:SaveTraderOperation() end,true)
    T:Button(op,"Delete group",150,31,255,255,function()
        local id=U.traderGroupId;if id and id~="default" and FM.Groups:Delete(id) then U.traderGroupId="default";FM:Status("Group deleted. Items moved to Ungrouped.");U:RefreshTrader() end
    end)

    T:Text(p,"LIVE PLANS",10,270,385,300,T.gold)
    self.postScan=T:Button(p,"Run Post Scan",160,31,270,405,function() FM.Trader:Start("post") end,true)
    self.cancelScan=T:Button(p,"Run Cancel Scan",160,31,440,405,function() FM.Trader:Start("cancel") end)
    self.stopTrader=T:Button(p,"Stop",90,31,610,405,function() FM.Trader:Stop() end)
    self.planMode=T:Text(p,"",10,712,414,180,T.muted);self.planMode:SetJustifyH("RIGHT")
    self.planRows={}
    for i=1,4 do
        local r=T:Button(p,"",622,36,270,445+(i-1)*39,function(b)
            if b.data and b.data.item and b.data.price then FM.Trader:Prepare(b.data)
            elseif b.data and b.data.row and b.data.status=="UNDERCUT" then FM.Market:Cancel(b.data.row) end
        end)
        r.name=T:Text(r,"",11,10,7,220,T.text);r.group=T:Text(r,"",9,235,9,115,T.muted)
        r.status=T:Text(r,"",10,355,8,115,T.teal);r.price=T:Text(r,"",10,476,8,133,T.gold);r.price:SetJustifyH("RIGHT")
        self.planRows[i]=r
    end
    self.planPage=T:Text(p,"",10,270,602,622,T.muted)
end

function U:SaveTraderOperation()
    local id,g,op=selectedGroup();if not g or not op then return end
    local under=tonumber(self.opUndercut:GetText());local stack=tonumber(self.opStack:GetText());local cap=tonumber(self.opCap:GetText());local keep=tonumber(self.opKeep:GetText())
    if not under or under<0 or not stack or stack<0 or not cap or cap<0 or not keep or keep<0 then FM:Status("Check operation numeric fields.");return end
    if self.opMin:GetText()=="" or self.opNormal:GetText()=="" or self.opMax:GetText()=="" then FM:Status("Price rules cannot be empty.");return end
    FM.Groups:SaveOperation(g.operation,{minPrice=self.opMin:GetText(),normalPrice=self.opNormal:GetText(),maxPrice=self.opMax:GetText(),undercut=math.floor(under),stackSize=math.floor(stack),postCap=math.floor(cap),keepQuantity=math.floor(keep)})
    FM:Status("Operation saved for "..g.name..".");self:RefreshTrader()
end

function U:RefreshTrader()
    if not self.groupRows then return end;FM.Groups:Ensure()
    local groups=FM.Groups:All();local current=U.traderGroupId or "default";if not FM.Data.groups[current] then current="default";U.traderGroupId=current end
    for i,r in ipairs(self.groupRows) do local d=groups[i];r.data=d;r:SetShown(d~=nil);if d then r.name:SetText(d.name);r.count:SetText(FM.Groups:Count(d.id));r.active=d.id==current;r:Paint() end end
    local id,g,op=selectedGroup()
    if g and op then
        self.traderTitle:SetText((g.name or id).." / "..(op.name or "Auctioning"))
        self.opMin:SetText(op.minPrice or "70% FMMarket");self.opNormal:SetText(op.normalPrice or "100% FMMarket");self.opMax:SetText(op.maxPrice or "130% FMMarket")
        self.opUndercut:SetText(tostring(op.undercut or 1));self.opStack:SetText(tostring(op.stackSize or 0));self.opCap:SetText(tostring(op.postCap or 5));self.opKeep:SetText(tostring(op.keepQuantity or 0))
    end
    local item=FM.Sell.item
    self.traderSelected:SetText(item and (item.name.."\nCurrent group: "..(((FM.Groups:GroupFor(item.key))) and select(2,FM.Groups:GroupFor(item.key)).name or "Ungrouped")) or "Select an item in Sell first, then return here to assign it.")
    local plan=FM.Trader.plan or {};local start=math.max(1,#plan-3)
    for i,r in ipairs(self.planRows) do local d=plan[start+i-1];r.data=d;r:SetShown(d~=nil);if d then r.name:SetText(d.name);r.group:SetText(d.group or "");r.status:SetText(d.status or "");r.price:SetText(d.price and FM:Money(d.price)..(d.stacks and (" x"..d.stacks) or "") or (d.competitor and FM:Money(d.competitor) or "-")) end end
    self.planMode:SetText(FM.Trader.scan and (string.upper(FM.Trader.scan.kind).." SCANNING") or (#plan>0 and "PLAN READY" or "IDLE"))
    self.planPage:SetText(#plan.." decisions | Post rows: click to prepare Sell. Cancel rows: click UNDERCUT to review cancellation.")
end

function U:BuildAdvisor()
    local p=self:NewPanel("Advisor","Forever Advisor / market signals","Local observations only: price distance, history, sample count and your stored inventory.")
    self.advisorRows={}
    for i=1,10 do
        local r=T:Button(p,"",892,46,0,62+(i-1)*49,function(b) if b.data then U:SetTab("Market");U.search:SetText(b.data.name);FM.Market:Search(b.data.name,0,true) end end)
        r.name=T:Text(r,"",12,12,7,245,T.text);r.sub=T:Text(r,"",9,12,27,245,T.muted)
        r.signal=T:Text(r,"",10,280,16,145,T.teal);r.current=T:Text(r,"",10,440,16,160,T.gold);r.history=T:Text(r,"",10,615,16,150,T.muted);r.owned=T:Text(r,"",10,780,16,95,T.text);r.owned:SetJustifyH("RIGHT")
        self.advisorRows[i]=r
    end
    self.advisorFoot=T:Text(p,"",10,0,566,892,T.muted)
    T:Button(p,"Recalculate",140,28,752,594,function() U:RefreshAdvisor() end,true)
end
function U:RefreshAdvisor()
    if not self.advisorRows then return end;local rows=FM.Advisor:Build()
    for i,r in ipairs(self.advisorRows) do local d=rows[i];r.data=d;r:SetShown(d~=nil);if d then
        r.name:SetText(d.name);r.sub:SetText(d.samples.." samples | "..math.floor((time()-d.t)/60).." min old")
        r.signal:SetText(d.tag);r.current:SetText("Low "..FM:Money(d.low));r.history:SetText("Median "..FM:Money(d.median));r.owned:SetText("Owned "..d.owned)
    end end
    self.advisorFoot:SetText(#rows.." items analyzed. Signals are descriptive, not guaranteed profit forecasts.")
end

function U:BuildLedger()
    local p=self:NewPanel("Ledger","Ledger / gold flow + inventory memory","Confirmed purchase/post requests plus SOLD rows observed in My Auctions.")
    self.ledgerToday=T:Panel(p,282,82,0,62);self.ledgerWeek=T:Panel(p,282,82,305,62);self.ledgerAll=T:Panel(p,282,82,610,62)
    self.ledgerTodayText=T:Text(self.ledgerToday,"",11,13,14,256,T.text);self.ledgerWeekText=T:Text(self.ledgerWeek,"",11,13,14,256,T.text);self.ledgerAllText=T:Text(self.ledgerAll,"",11,13,14,256,T.text)
    T:Text(p,"RECENT ACTIVITY",10,0,166,300,T.gold)
    self.ledgerRows={}
    for i=1,8 do
        local r=T:Panel(p,892,43,0,190+(i-1)*46);r.kind=T:Text(r,"",10,10,13,70,T.teal);r.name=T:Text(r,"",11,90,12,330,T.text);r.qty=T:Text(r,"",10,435,13,80,T.muted);r.amount=T:Text(r,"",10,530,13,170,T.gold);r.when=T:Text(r,"",9,720,14,155,T.muted);r.when:SetJustifyH("RIGHT");self.ledgerRows[i]=r
    end
    self.ledgerFoot=T:Text(p,"",10,0,574,600,T.muted)
    T:Button(p,"Refresh inventory",180,28,712,566,function() FM.Inventory:Scan();U:RefreshLedger() end,true)
end
local function ledgerText(label,s)
    return label.."\nNet sales: "..FM:Money(s.net).."   Spent: "..FM:Money(s.spent).."\nObserved P/L: "..FM:Money(s.profit)
end
function U:RefreshLedger()
    if not self.ledgerRows then return end;FM.Ledger:Ensure()
    self.ledgerTodayText:SetText(ledgerText("TODAY",FM.Ledger:Summary(1)));self.ledgerWeekText:SetText(ledgerText("7 DAYS",FM.Ledger:Summary(7)));self.ledgerAllText:SetText(ledgerText("ALL TIME",FM.Ledger:Summary(nil)))
    local list=FM.Data.ledger.entries or {};for i,r in ipairs(self.ledgerRows) do local d=list[#list-i+1];r:SetShown(d~=nil);if d then r.kind:SetText(d.kind);r.name:SetText(d.name);r.qty:SetText("x"..(d.quantity or 1));r.amount:SetText(FM:Money(d.amount or 0));r.when:SetText(date("%d.%m %H:%M",d.t)) end end
    local chars=0;for _ in pairs(FM.Data.snapshots or {}) do chars=chars+1 end;self.ledgerFoot:SetText(#list.." ledger entries | inventory snapshots: "..chars.." characters | bank snapshots update when the bank is opened")
end

function U:BuildBids()
    local p=self:NewPanel("Bids","My bids / bidder list","Track auctions you bid on. Refresh uses the Classic Era bidder list, not a market search.")
    self.bidsRefresh=T:Button(p,"Refresh bids",140,30,752,4,function() FM.Market:RefreshBids() end,true)
    local head=T:Panel(p,892,24,0,62);T:Text(head,"ITEM",9,10,7,265,T.muted);T:Text(head,"STATUS",9,300,7,100,T.muted);T:Text(head,"CURRENT BID",9,420,7,150,T.muted);T:Text(head,"BUYOUT",9,590,7,130,T.muted);T:Text(head,"TIME",9,735,7,75,T.muted)
    self.bidRows={}
    for i=1,9 do
        local r=T:Panel(p,892,47,0,91+(i-1)*50);r.icon=r:CreateTexture(nil,"ARTWORK");r.icon:SetSize(30,30);r.icon:SetPoint("TOPLEFT",8,-8);r.icon:SetTexCoord(.07,.93,.07,.93)
        r.name=T:Text(r,"",11,48,8,232,T.text);r.owner=T:Text(r,"",9,48,27,232,T.muted);r.status=T:Text(r,"",10,300,17,100,T.teal);r.bid=T:Text(r,"",10,420,17,150,T.gold);r.buyout=T:Text(r,"",10,590,17,130,T.gold);r.time=T:Text(r,"",9,735,18,75,T.muted)
        T:Button(r,"Bid",55,27,812,4,function() if r.data then FM.Market:BidderBid(r.data,false) end end)
        T:Button(r,"Buy",55,27,812,31,function() if r.data then FM.Market:BidderBid(r.data,true) end end,true)
        self.bidRows[i]=r
    end
    self.bidsFoot=T:Text(p,"",10,0,555,892,T.muted)
end
function U:RefreshBids()
    if not self.bidRows then return end;local rows=FM.Market.bids or {}
    for i,r in ipairs(self.bidRows) do local d=rows[i];r.data=d;r:SetShown(d~=nil);if d then
        r.icon:SetTexture(d.texture or "Interface\\Icons\\INV_Misc_QuestionMark");r.name:SetText(d.name);r.owner:SetText("Seller: "..(d.owner or "?"));r.status:SetText(FM.Market:BidStatus(d));r.bid:SetText(FM:Money(d.bid>0 and d.bid or d.minBid));r.buyout:SetText(d.buyout>0 and FM:Money(d.buyout) or "-");r.time:SetText(({"<30m","<2h","<12h",">12h"})[d.timeLeft] or "-")
    end end
    self.bidsFoot:SetText(FM.Market.bidderLoading and "Loading bidder list..." or (#rows.." auctions in your bidder list | green status means you are currently the high bidder"))
end
