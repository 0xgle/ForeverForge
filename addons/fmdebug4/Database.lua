local _,FM=...
local defaults={openWithAH=true,undercut=1,dealThreshold=.8,maxHistory=90,scale=1,tooltip=true,cut=.05,defaultDuration=2}
function FM:InitDB()
    if type(ForeverMarketDB)~="table" then ForeverMarketDB={} end
    local db=ForeverMarketDB
    db.settings=type(db.settings)=="table" and db.settings or {}
    for k,v in pairs(defaults) do if db.settings[k]==nil then db.settings[k]=v end end
    db.realms=type(db.realms)=="table" and db.realms or {}
    self.realmKey=(GetRealmName() or "unknown").." / "..(UnitFactionGroup("player") or "neutral")
    db.realms[self.realmKey]=db.realms[self.realmKey] or {history={},catalog={},watchlist={},shopping={},presets={},log={},stats={},groups={},operations={},itemGroups={},ledger={entries={},seenSales={}},snapshots={},crafting={},flip={}}
    local data=db.realms[self.realmKey]
    for _,k in ipairs({"history","catalog","watchlist","shopping","presets","log","stats","groups","operations","itemGroups","snapshots","crafting","flip"}) do data[k]=data[k] or {} end
    data.ledger=type(data.ledger)=="table" and data.ledger or {entries={},seenSales={}}
    data.ledger.entries=data.ledger.entries or {};data.ledger.seenSales=data.ledger.seenSales or {}
    if not db.schema or db.schema<2 then
        db.legacy={history=db.history,stats=db.stats,watchlist=db.watchlist}
        for k,v in pairs(db.watchlist or {}) do data.watchlist[k]=v end
        -- Legacy prices have no realm/faction provenance; archive rather than mixing markets.
        db.schema=2
    end
    if not db.schema or db.schema<3 then db.schema=3 end
    db.empire=type(db.empire)=="table" and db.empire or {characters={}};db.empire.characters=db.empire.characters or {}
    if not db.schema or db.schema<4 then db.schema=4 end
    self.DB,self.Data=db,data
    self:PruneHistory()
end
function FM:ItemKey(link,name)
    local payload=link and link:match("item:([%d:%-]+)")
    if payload then
        local parts={}; for p in (payload..":"):gmatch("(.-):") do parts[#parts+1]=p end
        local suffix=tonumber(parts[7]) or 0
        return "item:"..parts[1]..(suffix~=0 and (":"..suffix) or "")
    end
    return (name or "unknown"):lower()
end
function FM:Remember(row)
    self.Data.catalog[row.key]={name=row.name,link=row.link,texture=row.texture,seen=time()}
end
function FM:PruneHistory()
    local entries={}
    for key,h in pairs(self.Data.history) do
        if #h>0 then entries[#entries+1]={key=key,t=h[#h].t or 0} end
    end
    table.sort(entries,function(a,b) return a.t>b.t end)
    for i=2501,#entries do self.Data.history[entries[i].key]=nil; self.Data.catalog[entries[i].key]=nil end
end
function FM:Observe(rows,source)
    local groups={}
    for _,r in ipairs(rows) do
        self:Remember(r)
        if r.unit>0 then
            groups[r.key]=groups[r.key] or {}; table.insert(groups[r.key],r.unit)
        end
    end
    for key,prices in pairs(groups) do
        table.sort(prices)
        local n=#prices; local mid=(prices[math.floor((n+1)/2)]+prices[math.ceil((n+1)/2)])/2
        local h=self.Data.history[key] or {}; self.Data.history[key]=h
        local sample={t=time(),p=mid,low=prices[1],q=n,s=source}
        -- One sample per item/query, with a one-minute coalescing window.
        if #h>0 and time()-(h[#h].t or 0)<60 then h[#h]=sample else h[#h+1]=sample end
        while #h>90 do table.remove(h,1) end
    end
    self:PruneHistory()
end
function FM:GetHistoryStats(key)
    local h=self.Data.history[key]
    if not h or #h==0 then return nil end
    local vals,sum={},0
    for _,s in ipairs(h) do vals[#vals+1]=s.p; sum=sum+s.p end
    table.sort(vals)
    local n=#vals; local last=h[#h]
    return {count=n,min=vals[1],max=vals[n],avg=sum/n,median=(vals[math.floor((n+1)/2)]+vals[math.ceil((n+1)/2)])/2,last=last.p,low=last.low or last.p,t=last.t}
end
function FM:ToggleWatch(row)
    if self.Data.watchlist[row.key] then self.Data.watchlist[row.key]=nil; return false end
    self.Data.watchlist[row.key]={name=row.name,link=row.link,added=time()}; self:Remember(row); return true
end
function FM:Log(kind,row,amount,status)
    local log=self.Data.log
    log[#log+1]={t=time(),kind=kind,name=row.name,link=row.link,quantity=row.count or 1,amount=amount or 0,status=status or "request sent"}
    while #log>200 do table.remove(log,1) end
    return log[#log]
end

-- Display old activity records in English without rewriting saved user data.
local legacyLogLabels={
    ["Zakup"]="Purchase",["Licytacja"]="Bid",["Sprzedaz"]="Posting",["Anulowanie"]="Cancellation",
    ["wyslano"]="request sent",["serwer przyjal"]="accepted by server",["brak potwierdzenia"]="unconfirmed",
    ["przerwano sledzenie; sprawdz poczte/aukcje"]="tracking stopped; check mail/auctions",
}
function FM:LogLabel(value)
    value=tostring(value or "")
    return legacyLogLabels[value] or value:gsub("^blad: ","Error: ")
end
