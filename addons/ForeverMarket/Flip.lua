local _,FM=...
local F={candidates={},scan=nil,review=nil};FM.Flip=F

local function median(values)
    if not values or #values==0 then return nil end
    table.sort(values)
    local n=#values
    return (values[math.floor((n+1)/2)]+values[math.ceil((n+1)/2)])/2
end

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$")
end

function F:Ensure()
    if not FM.Data then return end
    FM.Data.flip=FM.Data.flip or {}
    FM.Data.flip.settings=FM.Data.flip.settings or {}
    local s=FM.Data.flip.settings
    if s.minROI==nil then s.minROI=.15 end
    if s.minProfit==nil then s.minProfit=10000 end
    if s.maxInvestment==nil then s.maxInvestment=0 end
    if s.minSamples==nil then s.minSamples=2 end
end

function F:Settings()
    self:Ensure();return FM.Data.flip.settings
end

function F:SetSettings(values)
    local s=self:Settings()
    for k,v in pairs(values or {}) do s[k]=v end
    return s
end

local function pageGroups(rows)
    local groups={}
    for _,r in ipairs(rows or {}) do
        if r and r.key and r.unit and r.unit>0 and r.buyout and r.buyout>0 and not FM.Market:IsMine(r.owner) then
            local g=groups[r.key] or {rows={},prices={}};groups[r.key]=g
            g.rows[#g.rows+1]=r;g.prices[#g.prices+1]=r.unit
        end
    end
    return groups
end

function F:EvaluateRows(rows)
    self:Ensure();local settings=self:Settings();local out={};local groups=pageGroups(rows)
    for key,g in pairs(groups) do
        local hist=FM:GetHistoryStats(key);local pageMedian=median(g.prices)
        local reference,source,samples
        if hist and hist.count>=settings.minSamples then reference,source,samples=hist.median,"history",hist.count
        elseif #g.prices>=5 then reference,source,samples=pageMedian,"loaded market",#g.prices end
        if reference and reference>0 then
            for _,r in ipairs(g.rows) do
                local otherMin
                for _,o in ipairs(g.rows) do
                    if o~=r and o.unit and o.unit>0 then otherMin=math.min(otherMin or o.unit,o.unit) end
                end
                local exit=reference
                if otherMin then exit=math.min(exit,math.max(0,otherMin-1)) end
                local gross=math.floor(exit*(r.count or 1))
                local net=math.floor(gross*(1-(FM.DB.settings.cut or .05)))
                local cost=r.buyout
                local profit=net-cost
                local roi=cost>0 and profit/cost or 0
                local maxOK=settings.maxInvestment<=0 or cost<=settings.maxInvestment
                if exit>r.unit and profit>=settings.minProfit and roi>=settings.minROI and maxOK then
                    local discount=1-r.unit/reference
                    local confidence=math.min(100,math.floor(30+math.min(samples or 0,10)*6+(source=="history" and 10 or 0)))
                    local tag
                    if roi>=.40 and confidence>=70 then tag="GREAT FLIP"
                    elseif roi>=.25 and confidence>=55 then tag="STRONG"
                    else tag="WATCH" end
                    out[#out+1]={key=key,name=r.name,link=r.link,row=r,cost=cost,count=r.count or 1,buyUnit=r.unit,exitUnit=math.floor(exit),
                        profit=profit,roi=roi,discount=discount,confidence=confidence,samples=samples or 0,reference=reference,referenceSource=source,
                        otherMin=otherMin,tag=tag,owner=r.owner,generation=r.generation}
                end
            end
        end
    end
    table.sort(out,function(a,b)
        local as=a.roi*100+(a.confidence or 0)*.25
        local bs=b.roi*100+(b.confidence or 0)*.25
        if as==bs then return a.profit>b.profit end
        return as>bs
    end)
    return out
end

function F:AnalyzeLoaded(append)
    if not FM.Market or not FM.Market.results then return end
    local rows=self:EvaluateRows(FM.Market.results)
    if append then
        local seen={};for _,c in ipairs(self.candidates) do seen[c.key..":"..c.cost..":"..c.count]=true end
        for _,c in ipairs(rows) do local id=c.key..":"..c.cost..":"..c.count;if not seen[id] then self.candidates[#self.candidates+1]=c;seen[id]=true end end
        table.sort(self.candidates,function(a,b) if a.roi==b.roi then return a.profit>b.profit end;return a.roi>b.roi end)
    else self.candidates=rows end
    FM:Status(#rows>0 and ("Flip analysis: "..#rows.." opportunities found in loaded results.") or "Flip analysis: no offers meet your current filters.")
    FM:Refresh();return rows
end

function F:WatchQueue()
    local q={}
    for key,d in pairs(FM.Data.watchlist or {}) do q[#q+1]={key=key,name=d.name,link=d.link} end
    table.sort(q,function(a,b) return (a.name or a.key)<(b.name or b.key) end)
    return q
end

function F:StartWatchScan()
    if self.scan then FM:Status("Flip watchlist scan already running.");return end
    if FM.Trader and FM.Trader.scan then FM:Status("Wait for the Trader scan to finish.");return end
    if FM.ShoppingScan and FM.ShoppingScan.scan then FM:Status("Wait for the Shopping scan to finish.");return end
    if not FM.Market:Ready() then return end
    local q=self:WatchQueue();if #q==0 then FM:Status("Your watchlist is empty. Shift-click items in Market to add them.");return end
    self.candidates={};self.scan={queue=q,index=0,current=nil};self:NextWatch()
end

function F:NextWatch()
    local s=self.scan;if not s then return end
    s.index=s.index+1;local e=s.queue[s.index]
    if not e then self.scan=nil;FM:Status("Flip watchlist scan complete. "..#self.candidates.." opportunities ready.");FM:Refresh();return end
    s.current=e;FM:Status("Flip scan: "..s.index.." / "..#s.queue.." - "..(e.name or e.key));FM.Market:Search(e.name or "",0,true)
end

function F:Stop()
    if not self.scan then return end
    self.scan=nil;FM.Market:Stop();FM:Status("Flip scan stopped. Partial opportunities preserved.");FM:Refresh()
end

function F:OnMarketResults()
    if self.review then
        local p=self.review;self.review=nil;local best
        for _,r in ipairs(FM.Market.results or {}) do
            if r.key==p.key and r.buyout>0 and not FM.Market:IsMine(r.owner) then if not best or r.unit<best.unit then best=r end end
        end
        local fresh=self:EvaluateRows(FM.Market.results);local plan
        for _,c in ipairs(fresh) do if c.key==p.key and (not plan or c.cost<plan.cost) then plan=c end end
        if plan and plan.row then
            plan.row.flipCandidate=true;plan.row.flipPlan=plan
            if FM.UI then FM.UI:SetTab("Market");FM.UI.selected=plan.row;FM.UI:RefreshMarket() end
            FM:Status("Flip refreshed and still meets your filters. Review the live auction and click Buy when ready.")
        elseif best then
            if FM.UI then FM.UI:SetTab("Market");FM.UI.selected=best;FM.UI:RefreshMarket() end
            FM:Status("Price changed: this auction no longer meets your flip filters. Review it manually before buying.")
        else FM:Status("That flip is no longer available at the Auction House.") end
        FM:Refresh();return
    end
    local s=self.scan;if not s or not s.current then return end
    self:AnalyzeLoaded(true);s.current=nil
    FM:After(.35,function() F:NextWatch() end)
end

function F:Review(candidate)
    if not candidate then return end
    if self.scan then FM:Status("Stop the flip scan before reviewing an opportunity.");return end
    local row=candidate.row
    if row and row.generation==FM.Market.generation and row.actionable and FM.Market.mode=="search" then
        row.flipCandidate=true;row.flipPlan=candidate
        if FM.UI then FM.UI:SetTab("Market");FM.UI.selected=row;FM.UI:RefreshMarket() end
        FM:Status("Flip ready. Review the live auction and click Buy when ready.");FM:Refresh();return
    end
    if not FM.Market:Ready() then return end
    self.review={key=candidate.key,name=candidate.name,expected=candidate.buyUnit,started=time()}
    FM:Status("Refreshing flip before purchase: "..candidate.name.."...");FM.Market:Search(candidate.name,0,true)
end

local function historyMedian(data,key)
    local h=data and data.history and data.history[key];if not h or #h==0 then return nil end
    local vals={};for _,s in ipairs(h) do if s.p and s.p>0 then vals[#vals+1]=s.p end end
    return median(vals)
end

function F:AllEntries()
    local list={}
    for realmKey,data in pairs((FM.DB and FM.DB.realms) or {}) do
        for i,e in ipairs((data.ledger and data.ledger.entries) or {}) do list[#list+1]={e=e,realmKey=realmKey,data=data,seq=i} end
    end
    table.sort(list,function(a,b) if (a.e.t or 0)==(b.e.t or 0) then return a.realmKey..":"..a.seq<b.realmKey..":"..b.seq end;return (a.e.t or 0)<(b.e.t or 0) end)
    return list
end

function F:BuildAccounting()
    local positions,events={},{}
    local cut=(FM.DB and FM.DB.settings and FM.DB.settings.cut) or .05
    for _,wrap in ipairs(self:AllEntries()) do
        local e=wrap.e;local id=wrap.realmKey.."|"..tostring(e.key or "?")
        local p=positions[id]
        if e.kind=="BUY" and (e.flip==true or e.note=="Flip purchase") then
            p=p or {realmKey=wrap.realmKey,key=e.key,name=e.name,link=e.link,qty=0,cost=0};positions[id]=p
            local q=math.max(1,tonumber(e.quantity) or 1);p.qty=p.qty+q;p.cost=p.cost+math.max(0,tonumber(e.amount) or 0);p.last=e.t
        elseif e.kind=="SOLD" and p and p.qty>0 then
            local soldQ=math.max(1,tonumber(e.quantity) or 1);local matched=math.min(soldQ,p.qty)
            local avg=p.qty>0 and p.cost/p.qty or 0;local basis=math.floor(avg*matched+.5)
            local netTotal=math.floor((tonumber(e.amount) or 0)*(1-cut));local netMatched=math.floor(netTotal*(matched/soldQ)+.5)
            local profit=netMatched-basis
            events[#events+1]={t=e.t or time(),profit=profit,net=netMatched,basis=basis,quantity=matched,key=e.key,name=e.name,
                character=e.character,characterName=e.characterName,realmKey=wrap.realmKey}
            p.qty=p.qty-matched;p.cost=math.max(0,p.cost-basis);p.last=e.t
            if p.qty<=0 then p.qty=0;p.cost=0 end
        end
    end
    local summary={realized=0,invested=0,marketValue=0,unrealized=0,openPositions=0,events=events,positions=positions}
    for _,e in ipairs(events) do summary.realized=summary.realized+e.profit end
    for _,p in pairs(positions) do if p.qty>0 then
        summary.openPositions=summary.openPositions+1;summary.invested=summary.invested+p.cost
        local data=FM.DB.realms[p.realmKey];local ref=historyMedian(data,p.key)
        if ref then summary.marketValue=summary.marketValue+math.floor(ref*p.qty*(1-cut)) end
    end end
    summary.unrealized=summary.marketValue-summary.invested
    return summary
end


function F:PositionFor(key,realmKey)
    local a=self:BuildAccounting();return a.positions[(realmKey or FM.realmKey).."|"..tostring(key or "?")]
end

function F:RecentProfit(days)
    local since=days and time()-days*86400 or 0;local total=0
    for _,e in ipairs(self:BuildAccounting().events) do if (e.t or 0)>=since then total=total+(e.profit or 0) end end
    return total
end
