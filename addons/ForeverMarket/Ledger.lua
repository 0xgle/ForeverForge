local _,FM=...
local L={};FM.Ledger=L

function L:Ensure()
    if not FM.Data then return end
    FM.Data.ledger=FM.Data.ledger or {entries={},seenSales={},ownerMemory={}}
    FM.Data.ledger.entries=FM.Data.ledger.entries or {};FM.Data.ledger.seenSales=FM.Data.ledger.seenSales or {};FM.Data.ledger.ownerMemory=FM.Data.ledger.ownerMemory or {}
    FM.Data.snapshots=FM.Data.snapshots or {}
end
function L:Record(kind,row,amount,quantity,note)
    self:Ensure();row=row or {};quantity=quantity or row.count or 1
    local charKey=FM.Empire and FM.Empire.CharacterKey and FM.Empire:CharacterKey() or ((UnitName("player") or "?").." / "..(GetRealmName() or "?").." / "..(UnitFactionGroup("player") or "neutral"))
    local e={t=time(),kind=kind,key=row.key or FM:ItemKey(row.link,row.name),name=row.name or "?",link=row.link,
        amount=math.floor(tonumber(amount) or 0),quantity=math.max(1,tonumber(quantity) or 1),note=note,
        character=charKey,characterName=UnitName("player") or "?",realm=GetRealmName() or "?",faction=UnitFactionGroup("player") or "neutral",
        flip=row.flipCandidate==true}
    e.unit=e.quantity>0 and e.amount/e.quantity or 0
    local list=FM.Data.ledger.entries;list[#list+1]=e
    while #list>1000 do table.remove(list,1) end
    return e
end
function L:Averages(key)
    self:Ensure();local buyN,buyQ,sellN,sellQ=0,0,0,0
    for _,e in ipairs(FM.Data.ledger.entries) do
        if e.key==key then
            if e.kind=="BUY" then buyN=buyN+e.amount;buyQ=buyQ+(e.quantity or 1)
            elseif e.kind=="SOLD" then sellN=sellN+e.amount;sellQ=sellQ+(e.quantity or 1) end
        end
    end
    return buyQ>0 and buyN/buyQ or nil,sellQ>0 and sellN/sellQ or nil
end
function L:Summary(days)
    self:Ensure();local since=days and (time()-days*86400) or 0
    local s={spent=0,gross=0,net=0,bought=0,sold=0,fees=0,posts=0,cancels=0}
    for _,e in ipairs(FM.Data.ledger.entries) do if e.t>=since then
        if e.kind=="BUY" then s.spent=s.spent+e.amount;s.bought=s.bought+e.quantity
        elseif e.kind=="SOLD" then s.gross=s.gross+e.amount;s.sold=s.sold+e.quantity;local net=math.floor(e.amount*(1-(FM.DB.settings.cut or .05)));s.net=s.net+net;s.fees=s.fees+(e.amount-net)
        elseif e.kind=="POST" then s.posts=s.posts+1
        elseif e.kind=="CANCEL" then s.cancels=s.cancels+1 end
    end end
    s.profit=s.net-s.spent;return s
end
function L:ObserveOwned(rows)
    self:Ensure();local memory=FM.Data.ledger.ownerMemory
    for _,r in ipairs(rows or {}) do
        local base=(r.key or r.name)..":"..tostring(r.buyout or 0)..":"..tostring(r.minBid or 0)
        if r.saleStatus~=1 and (r.count or 0)>0 then memory[base]={count=r.count,t=time()}
        elseif r.saleStatus==1 and r.buyout and r.buyout>0 then
            local quantity=(memory[base] and memory[base].count) or math.max(1,r.count or 0)
            local sig=base..":"..tostring(r.index)..":"..tostring(r.buyout)
            if not FM.Data.ledger.seenSales[sig] then
                FM.Data.ledger.seenSales[sig]=time();self:Record("SOLD",r,r.buyout,quantity,"Observed in My Auctions")
            end
        end
    end
    local cutoff=time()-30*86400
    for sig,t in pairs(FM.Data.ledger.seenSales) do if t<cutoff then FM.Data.ledger.seenSales[sig]=nil end end
    for sig,d in pairs(memory) do if not d.t or d.t<cutoff then memory[sig]=nil end end
end
function L:CaptureBags()
    if not FM.Data or not FM.Inventory then return end;self:Ensure()
    local char=(UnitName("player") or "?").." / "..(GetRealmName() or "?")
    local snap={t=time(),bags={}}
    for _,r in ipairs(FM.Inventory.items or {}) do snap.bags[r.key]=(snap.bags[r.key] or 0)+(r.total or r.count or 0) end
    local old=FM.Data.snapshots[char] or {};old.bags=snap.bags;old.t=snap.t;old.name=UnitName("player");FM.Data.snapshots[char]=old
end
function L:CaptureBank()
    if not FM.Data then return end;self:Ensure()
    local slots=C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local infoFn=C_Container and C_Container.GetContainerItemInfo
    if not slots then return end
    local bank={}
    for _,bag in ipairs({-1,5,6,7,8,9,10,11}) do
        for slot=1,(slots(bag) or 0) do
            local link,count
            if infoFn then local i=infoFn(bag,slot);if i then link=i.hyperlink;count=i.stackCount end
            elseif GetContainerItemInfo then local _,c,_,_,_,_,l=GetContainerItemInfo(bag,slot);link=l;count=c end
            if link then local name=GetItemInfo(link);local key=FM:ItemKey(link,name);bank[key]=(bank[key] or 0)+(count or 1) end
        end
    end
    local char=(UnitName("player") or "?").." / "..(GetRealmName() or "?")
    local old=FM.Data.snapshots[char] or {};old.bank=bank;old.bankT=time();old.name=UnitName("player");FM.Data.snapshots[char]=old
end

function L:CaptureMail()
    if not FM.Data or type(GetInboxNumItems)~="function" or type(GetInboxItemLink)~="function" then return end;self:Ensure()
    local mail={};local n=GetInboxNumItems() or 0;local maxAttachments=ATTACHMENTS_MAX_RECEIVE or 16
    for message=1,n do for attachment=1,maxAttachments do
        local link=GetInboxItemLink(message,attachment)
        if link then
            local name,_,_,count=GetInboxItem(message,attachment);local key=FM:ItemKey(link,name);mail[key]=(mail[key] or 0)+(count or 1)
            local c=FM.Data.catalog[key] or {};c.name=name or c.name;c.link=link;c.seen=time();FM.Data.catalog[key]=c
        end
    end end
    local char=(UnitName("player") or "?").." / "..(GetRealmName() or "?")
    local old=FM.Data.snapshots[char] or {};old.mail=mail;old.mailT=time();old.name=UnitName("player");FM.Data.snapshots[char]=old
end
function L:OwnedEverywhere(key)
    self:Ensure();local total=0
    for _,snap in pairs(FM.Data.snapshots) do total=total+(snap.bags and snap.bags[key] or 0)+(snap.bank and snap.bank[key] or 0)+(snap.mail and snap.mail[key] or 0) end
    for _,r in ipairs((FM.Market and FM.Market.owned) or {}) do if r.key==key and r.saleStatus~=1 then total=total+(r.count or 0) end end
    return total
end
FM:On("BANKFRAME_OPENED",function() L:CaptureBank() end)
FM:On("MAIL_SHOW",function() L:CaptureMail() end)
FM:On("MAIL_INBOX_UPDATE",function() L:CaptureMail() end)
