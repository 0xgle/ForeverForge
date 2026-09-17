local _,FM=...
local Tr={plan={},mode="post"};FM.Trader=Tr

local function uniqueQueue(kind)
    local q,seen={},{ }
    if kind=="post" then
        FM.Inventory:Scan()
        for _,item in ipairs(FM.Inventory.items or {}) do
            local gid=FM.Data.itemGroups and FM.Data.itemGroups[item.key]
            if gid and not seen[item.key] then seen[item.key]=true;q[#q+1]={key=item.key,name=item.name,link=item.link,item=item} end
        end
    else
        for _,row in ipairs(FM.Market.owned or {}) do
            if row.saleStatus~=1 and row.unit>0 and not seen[row.key] then seen[row.key]=true;q[#q+1]={key=row.key,name=row.name,link=row.link,row=row} end
        end
    end
    table.sort(q,function(a,b) return a.name<b.name end);return q
end

function Tr:Evaluate(item)
    local op,opId,gid,g=FM.Groups:OperationFor(item.key)
    local ref,sources=FM.Price:BestReference(item.key,item.link)
    if not ref or ref<=0 then return {key=item.key,name=item.name,item=item,status="NO PRICE",group=g and g.name or "Ungrouped"} end
    local min=select(1,FM.Price:Evaluate(op.minPrice,item.key,item.link)) or math.floor(ref*.7)
    local normal=select(1,FM.Price:Evaluate(op.normalPrice,item.key,item.link)) or ref
    local max=select(1,FM.Price:Evaluate(op.maxPrice,item.key,item.link)) or math.floor(ref*1.3)
    if max<min then max=min end;normal=math.max(min,math.min(max,normal))
    local comp=sources.FMMinBuyout;local under=tonumber(op.undercut) or FM.DB.settings.undercut or 1
    local target,reason=normal,"NORMAL"
    if comp and comp>0 then
        if comp<min then
            if op.belowMin=="skip" then target=nil;reason="BELOW MIN - SKIP" else target=normal;reason="COMP BELOW MIN" end
        else target=math.max(min,math.min(max,math.floor(comp-under)));reason="UNDERCUT" end
    end
    local qty=math.max(0,(item.total or item.count or 0)-(tonumber(op.keepQuantity) or 0))
    local stack=tonumber(op.stackSize) or 0;if stack<1 then stack=math.min(item.maxStack or 1,qty) end;stack=math.max(1,math.min(stack,item.maxStack or stack,math.max(1,qty)))
    local stacks=qty>0 and math.floor(qty/stack) or 0;local cap=tonumber(op.postCap) or 0;if cap>0 then stacks=math.min(stacks,cap) end
    return {key=item.key,name=item.name,item=item,group=g and g.name or "Ungrouped",gid=gid,opId=opId,price=target,min=min,normal=normal,max=max,competitor=comp,stack=stack,stacks=stacks,quantity=stack*stacks,status=stacks>0 and reason or "KEEP / NONE"}
end

function Tr:Start(kind)
    kind=kind or "post"
    if self.scan then FM:Status("Trader scan already running.");return end
    if FM.ShoppingScan and FM.ShoppingScan.scan then FM:Status("Wait for the Shopping scan to finish.");return end
    if not FM.Market:Ready() then return end
    if kind=="cancel" then FM.Market:RefreshOwned();FM:After(.45,function() if not Tr.scan then Tr:BeginQueue("cancel") end end)
    else self:BeginQueue("post") end
end
function Tr:BeginQueue(kind)
    local q=uniqueQueue(kind);self.plan={};self.scan={kind=kind,queue=q,index=0}
    if #q==0 then self.scan=nil;FM:Status(kind=="post" and "No grouped bag items to scan. Assign items to a Trader group first." or "No active buyout auctions to check.");FM:Refresh();return end
    FM:Status((kind=="post" and "Post" or "Cancel").." scan: 0 / "..#q);self:Next()
end
function Tr:Next()
    local s=self.scan;if not s then return end;s.index=s.index+1
    local entry=s.queue[s.index]
    if not entry then self.scan=nil;FM:Status((s.kind=="post" and "Post" or "Cancel").." scan complete. "..#self.plan.." decisions ready.");FM:Refresh();return end
    s.current=entry;FM:Status((s.kind=="post" and "Post" or "Cancel").." scan: "..s.index.." / "..#s.queue.." - "..entry.name)
    FM.Market:Search(entry.name,0,true)
end
function Tr:OnMarketResults()
    local s=self.scan;if not s or not s.current then return end
    local e=s.current
    if s.kind=="post" then
        local row=self:Evaluate(e.item);self.plan[#self.plan+1]=row
    else
        local lowest,competitors=nil,0
        for _,r in ipairs(FM.Market.results or {}) do if r.key==e.key and r.unit>0 and not FM.Market:IsMine(r.owner) then competitors=competitors+1;lowest=math.min(lowest or r.unit,r.unit) end end
        FM.Market.ownerChecks[e.key]={lowest=lowest,competitors=competitors,checked=time()}
        for _,owned in ipairs(FM.Market.owned or {}) do if owned.key==e.key and owned.saleStatus~=1 then
            local status=FM.Market:OwnerStatus(owned)
            self.plan[#self.plan+1]={key=owned.key,name=owned.name,row=owned,price=owned.unit,competitor=lowest,status=status,group=(select(4,FM.Groups:OperationFor(owned.key)) or {}).name or "Ungrouped"}
        end end
    end
    s.current=nil;FM:Refresh();FM:After(.35,function() Tr:Next() end)
end
function Tr:Stop()
    if not self.scan then return end;self.scan=nil;FM.Market:Stop();FM:Status("Trader scan stopped. Partial plan preserved.");FM:Refresh()
end
function Tr:Prepare(row)
    if not row or not row.item then return end
    FM.Inventory:Select(row.item)
    FM:After(.05,function()
        if FM.Sell.item and FM.Sell.item.key==row.key then
            FM.UI.sellStack:SetText(tostring(row.stack));FM.UI.sellCount:SetText(tostring(math.max(1,row.stacks)));FM.UI.sellPrice:SetText(FM:PlainMoney(row.price));FM.UI.sellFloor:SetText(FM:PlainMoney(row.min or 0));FM.UI:SetTab("Sell");FM:Status("Trader plan applied. Review and confirm the auction.")
        end
    end)
end
