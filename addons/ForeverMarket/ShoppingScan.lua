local _,FM=...
local SS={};FM.ShoppingScan=SS
function SS:Start()
    if self.scan then FM:Status("Shopping scan already running.");return end
    if FM.Trader and FM.Trader.scan then FM:Status("Wait for the Trader scan to finish.");return end
    if not FM.Market:Ready() then return end
    local q={}
    for key,d in pairs(FM.Data.shopping or {}) do q[#q+1]={key=key,name=d.name,cap=d.cap or 0,quantity=d.quantity or 1,data=d} end
    table.sort(q,function(a,b) return a.name<b.name end)
    if #q==0 then FM:Status("Your shopping list is empty.");return end
    self.scan={queue=q,index=0};self:Next()
end
function SS:Next()
    local s=self.scan;if not s then return end;s.index=s.index+1;local e=s.queue[s.index]
    if not e then self.scan=nil;FM:Status("Shopping scan complete. Live results saved to the list.");FM:Refresh();return end
    s.current=e;FM:Status("Shopping scan: "..s.index.." / "..#s.queue.." - "..e.name);FM.Market:Search(e.name,0,true)
end
function SS:OnMarketResults()
    local s=self.scan;if not s or not s.current then return end;local e=s.current
    local lowest,available,auctions=0,0,0;lowest=nil
    for _,r in ipairs(FM.Market.results or {}) do
        if r.name==e.name and r.unit and r.unit>0 and not FM.Market:IsMine(r.owner) then
            auctions=auctions+1;lowest=math.min(lowest or r.unit,r.unit)
            if e.cap<=0 or r.unit<=e.cap then available=available+(r.count or 0) end
        end
    end
    e.data.scan={t=time(),lowest=lowest,available=available,auctions=auctions,target=e.quantity,cap=e.cap}
    s.current=nil;FM:Refresh();FM:After(.35,function() SS:Next() end)
end
function SS:Stop()
    if not self.scan then return end;self.scan=nil;FM.Market:Stop();FM:Status("Shopping scan stopped. Partial results preserved.");FM:Refresh()
end
