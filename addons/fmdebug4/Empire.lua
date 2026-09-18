local _,FM=...
local E={};FM.Empire=E

function E:Ensure()
    if not FM.DB then return end
    FM.DB.empire=FM.DB.empire or {};FM.DB.empire.characters=FM.DB.empire.characters or {}
end
function E:CharacterKey()
    local name=UnitName("player") or "?";local realm=GetRealmName() or "?";local faction=UnitFactionGroup("player") or "neutral"
    return name.." / "..realm.." / "..faction
end
function E:CaptureGold()
    if not FM.DB then return end;self:Ensure()
    local key=self:CharacterKey();local d=FM.DB.empire.characters[key] or {}
    d.name=UnitName("player") or d.name or "?";d.realm=GetRealmName() or d.realm or "?";d.faction=UnitFactionGroup("player") or d.faction or "neutral"
    d.gold=GetMoney() or d.gold or 0;d.last=time();FM.DB.empire.characters[key]=d
end
function E:TotalGold()
    self:Ensure();local n,total=0,0
    for _,d in pairs(FM.DB.empire.characters) do n=n+1;total=total+(tonumber(d.gold) or 0) end
    return total,n
end
local function sinceFor(days) return days and (time()-days*86400) or 0 end
function E:NetSales(days)
    local since=sinceFor(days);local total=0;local cut=(FM.DB.settings and FM.DB.settings.cut) or .05
    for _,data in pairs(FM.DB.realms or {}) do for _,e in ipairs((data.ledger and data.ledger.entries) or {}) do
        if e.kind=="SOLD" and (e.t or 0)>=since then total=total+math.floor((tonumber(e.amount) or 0)*(1-cut)) end
    end end
    return total
end
function E:CharacterStats(days)
    self:Ensure();local since=sinceFor(days);local cut=(FM.DB.settings and FM.DB.settings.cut) or .05;local stats={}
    for key,d in pairs(FM.DB.empire.characters) do stats[key]={key=key,name=d.name or key,realm=d.realm or "?",faction=d.faction or "?",gold=d.gold or 0,last=d.last or 0,sales=0,profit=0} end
    for _,data in pairs(FM.DB.realms or {}) do for _,e in ipairs((data.ledger and data.ledger.entries) or {}) do
        if (e.t or 0)>=since and e.kind=="SOLD" then
            local key=e.character or "legacy";stats[key]=stats[key] or {key=key,name=e.characterName or "Legacy / unattributed",realm=e.realm or "?",faction=e.faction or "?",gold=0,last=0,sales=0,profit=0}
            stats[key].sales=stats[key].sales+math.floor((tonumber(e.amount) or 0)*(1-cut))
        end
    end end
    if FM.Flip then for _,ev in ipairs(FM.Flip:BuildAccounting().events or {}) do if (ev.t or 0)>=since then
        local key=ev.character or "legacy";stats[key]=stats[key] or {key=key,name=ev.characterName or "Legacy / unattributed",realm=ev.realmKey or "?",faction="?",gold=0,last=0,sales=0,profit=0}
        stats[key].profit=stats[key].profit+(ev.profit or 0)
    end end end
    local rows={};for _,d in pairs(stats) do rows[#rows+1]=d end
    table.sort(rows,function(a,b) if a.gold==b.gold then return a.name<b.name end;return a.gold>b.gold end);return rows
end
function E:Series(days,mode)
    days=math.max(2,math.floor(days or 14));mode=mode or "sales";local today=math.floor(time()/86400);local buckets={}
    for i=days-1,0,-1 do local day=today-i;buckets[day]={day=day,t=day*86400,value=0} end
    if mode=="profit" and FM.Flip then
        for _,ev in ipairs(FM.Flip:BuildAccounting().events or {}) do local day=math.floor((ev.t or 0)/86400);if buckets[day] then buckets[day].value=buckets[day].value+(ev.profit or 0) end end
    else
        local cut=(FM.DB.settings and FM.DB.settings.cut) or .05
        for _,data in pairs(FM.DB.realms or {}) do for _,e in ipairs((data.ledger and data.ledger.entries) or {}) do
            if e.kind=="SOLD" then local day=math.floor((e.t or 0)/86400);if buckets[day] then buckets[day].value=buckets[day].value+math.floor((tonumber(e.amount) or 0)*(1-cut)) end end
        end end
    end
    local rows={};for i=days-1,0,-1 do rows[#rows+1]=buckets[today-i] end;return rows
end
function E:SeriesTotal(days,mode)
    local n=0;for _,d in ipairs(self:Series(days,mode)) do n=n+(d.value or 0) end;return n
end
FM:On("PLAYER_LOGIN",function() E:CaptureGold() end)
FM:On("PLAYER_MONEY",function() E:CaptureGold();if FM.UI and FM.UI.activeTab=="Ledger" then FM:Refresh() end end)
FM:On("PLAYER_LOGOUT",function() E:CaptureGold() end)
FM:On("AUCTION_HOUSE_SHOW",function() E:CaptureGold() end)
FM:On("AUCTION_HOUSE_CLOSED",function() E:CaptureGold() end)
