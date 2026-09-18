local _,FM=...
local P={};FM.Price=P

local function currentMin(key)
    local best
    for _,r in ipairs((FM.Market and FM.Market.results) or {}) do
        if r.key==key and r.unit and r.unit>0 and not FM.Market:IsMine(r.owner) and (not r.seen or time()-r.seen<600) then
            best=math.min(best or r.unit,r.unit)
        end
    end
    return best
end

function P:Sources(key,link)
    local h=FM:GetHistoryStats(key)
    local buy,sell
    if FM.Ledger and FM.Ledger.Averages then buy,sell=FM.Ledger:Averages(key) end
    local vendor
    if link and GetItemInfo then
        local _,_,_,_,_,_,_,_,_,_,sellPrice=GetItemInfo(link)
        vendor=tonumber(sellPrice)
    end
    return {
        FMMarket=h and h.median or nil,
        FMRecent=h and h.last or nil,
        FMHistorical=h and h.avg or nil,
        FMMinBuyout=currentMin(key) or (h and h.low or nil),
        FMAvgBuy=buy,
        FMAvgSell=sell,
        FMVendorSell=vendor,
        FMCrafting=FM.Crafting and FM.Crafting.CostFor and FM.Crafting:CostFor(key) or nil,
    }
end

local function normalize(expr)
    expr=tostring(expr or "")
    expr=expr:gsub("(%d+%.?%d*)%s*([gGsScC])",function(n,u)
        local mult=({g=10000,s=100,c=1})[u:lower()];return tostring((tonumber(n) or 0)*mult)
    end)
    expr=expr:gsub("(%d+%.?%d*)%s*%%%s*([%a_][%w_]*)",function(n,id)
        return "("..tostring((tonumber(n) or 0)/100).."*"..id..")"
    end)
    expr=expr:gsub("(%d+%.?%d*)%s*%%",function(n) return tostring((tonumber(n) or 0)/100) end)
    return expr
end

local function tokenize(expr)
    local out,i={},1
    while i<=#expr do
        local c=expr:sub(i,i)
        if c:match("%s") then i=i+1
        elseif c:match("[%d%.]") then
            local s=expr:sub(i):match("^%d+%.?%d*") or expr:sub(i):match("^%.%d+")
            if not s then return nil,"Invalid number near position "..i end
            out[#out+1]={k="num",v=tonumber(s)};i=i+#s
        elseif c:match("[%a_]") then
            local s=expr:sub(i):match("^[%a_][%w_]*")
            out[#out+1]={k="id",v=s};i=i+#s
        elseif c=="+" or c=="-" or c=="*" or c=="/" or c=="(" or c==")" or c=="," then
            out[#out+1]={k=c,v=c};i=i+1
        else return nil,"Unsupported character '"..c.."'" end
    end
    out[#out+1]={k="eof"};return out
end

function P:Evaluate(expr,key,link)
    expr=normalize(expr)
    local tokens,err=tokenize(expr);if not tokens then return nil,err end
    local pos=1;local env=self:Sources(key,link)
    local parseExpr,parseTerm,parseFactor
    local function peek() return tokens[pos] end
    local function take(k)
        local t=peek();if t.k==k then pos=pos+1;return t end
    end
    parseFactor=function()
        local t=peek()
        if take("-") then local v,e=parseFactor();if v==nil then return nil,e end;return -v end
        if t.k=="num" then pos=pos+1;return t.v end
        if t.k=="id" then
            pos=pos+1;local id=t.v
            if take("(") then
                local args={}
                if peek().k~=")" then
                    while true do
                        local v,e=parseExpr();if v==nil then return nil,e end;args[#args+1]=v
                        if not take(",") then break end
                    end
                end
                if not take(")") then return nil,"Missing ')'" end
                if id=="min" or id=="max" or id=="avg" then
                    if #args<1 then return nil,id.." needs at least one value" end
                    local v=args[1]
                    if id=="avg" then local s=0;for _,x in ipairs(args) do s=s+x end;return s/#args end
                    for n=2,#args do v=(id=="min") and math.min(v,args[n]) or math.max(v,args[n]) end
                    return v
                end
                return nil,"Unknown function: "..id
            end
            local v=env[id]
            if v==nil then return nil,"Price source unavailable: "..id end
            return v
        end
        if take("(") then local v,e=parseExpr();if v==nil then return nil,e end;if not take(")") then return nil,"Missing ')'" end;return v end
        return nil,"Expected a number or price source"
    end
    parseTerm=function()
        local v,e=parseFactor();if v==nil then return nil,e end
        while peek().k=="*" or peek().k=="/" do
            local op=peek().k;pos=pos+1;local r,re=parseFactor();if r==nil then return nil,re end
            if op=="/" and r==0 then return nil,"Division by zero" end
            v=op=="*" and v*r or v/r
        end
        return v
    end
    parseExpr=function()
        local v,e=parseTerm();if v==nil then return nil,e end
        while peek().k=="+" or peek().k=="-" do
            local op=peek().k;pos=pos+1;local r,re=parseTerm();if r==nil then return nil,re end
            v=op=="+" and v+r or v-r
        end
        return v
    end
    local value,e=parseExpr();if value==nil then return nil,e end
    if peek().k~="eof" then return nil,"Unexpected token" end
    if value~=value or value==math.huge or value==-math.huge then return nil,"Invalid result" end
    return math.max(0,math.floor(value+.5)),env
end

function P:BestReference(key,link)
    local s=self:Sources(key,link)
    return s.FMMinBuyout or s.FMMarket or s.FMHistorical or s.FMRecent, s
end
