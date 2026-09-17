local _,FM=...
local C={rows={}};FM.Crafting=C

function C:Ensure()
    if not FM.Data then return end
    FM.Data.crafting=type(FM.Data.crafting)=="table" and FM.Data.crafting or {}
end

local function outputCount(index)
    if type(GetTradeSkillNumMade)~="function" then return 1 end
    local lo,hi=GetTradeSkillNumMade(index);lo=tonumber(lo) or 1;hi=tonumber(hi) or lo
    return math.max(1,(lo+hi)/2)
end

function C:Capture()
    self:Ensure()
    if type(GetNumTradeSkills)~="function" or type(GetTradeSkillInfo)~="function" or type(GetTradeSkillItemLink)~="function" then
        FM:Status("Classic trade-skill APIs are unavailable on this client.");return false
    end
    local profession=type(GetTradeSkillLine)=="function" and select(1,GetTradeSkillLine()) or "Profession"
    if not profession or profession=="UNKNOWN" or profession=="" then FM:Status("Open a profession window first.");return false end
    local recipes={}
    for i=1,(GetNumTradeSkills() or 0) do
        local name,kind=GetTradeSkillInfo(i)
        if name and kind~="header" then
            local link=GetTradeSkillItemLink(i)
            if link then
                local key=FM:ItemKey(link,name);local reagents={}
                local n=type(GetTradeSkillNumReagents)=="function" and (GetTradeSkillNumReagents(i) or 0) or 0
                for j=1,n do
                    local rname,_,need,have=GetTradeSkillReagentInfo(i,j)
                    local rlink=type(GetTradeSkillReagentItemLink)=="function" and GetTradeSkillReagentItemLink(i,j) or nil
                    if rname then reagents[#reagents+1]={name=rname,link=rlink,key=FM:ItemKey(rlink,rname),count=tonumber(need) or 0,have=tonumber(have) or 0} end
                end
                recipes[#recipes+1]={index=i,name=name,link=link,key=key,profession=profession,reagents=reagents,output=outputCount(i)}
                local c=FM.Data.catalog[key] or {};c.name=name;c.link=link;c.seen=time();FM.Data.catalog[key]=c
            end
        end
    end
    FM.Data.crafting[profession]={t=time(),recipes=recipes}
    FM:Status("Captured "..#recipes.." recipes from "..profession..".");FM:Refresh();return true
end

function C:Value(recipe)
    if not recipe then return nil end
    local cost,complete,craftable=0,true,nil
    for _,r in ipairs(recipe.reagents or {}) do
        local p=FM.Price:BestReference(r.key,r.link)
        if not p or p<=0 then complete=false else cost=cost+p*(r.count or 0) end
        if (r.count or 0)>0 then
            local have=FM.Ledger and FM.Ledger:OwnedEverywhere(r.key) or (r.have or 0)
            local n=math.floor(have/r.count);craftable=craftable and math.min(craftable,n) or n
        end
    end
    local sell=FM.Price:BestReference(recipe.key,recipe.link)
    local output=recipe.output or 1;local revenue=sell and sell*output or nil
    return {cost=complete and math.floor(cost+.5) or nil,sell=sell,revenue=revenue and math.floor(revenue+.5) or nil,profit=(complete and revenue) and math.floor(revenue-cost+.5) or nil,craftable=craftable or 0,complete=complete}
end

function C:Rows()
    self:Ensure();local rows={}
    for profession,data in pairs(FM.Data.crafting) do
        for _,recipe in ipairs(data.recipes or {}) do
            local v=self:Value(recipe);local row={}
            for k,x in pairs(recipe) do row[k]=x end
            for k,x in pairs(v or {}) do row[k]=x end
            row.profession=profession;row.captured=data.t;rows[#rows+1]=row
        end
    end
    table.sort(rows,function(a,b)
        local ap,bp=a.profit or -math.huge,b.profit or -math.huge
        if ap==bp then return a.name<b.name end;return ap>bp
    end)
    self.rows=rows;return rows
end

function C:CostFor(key)
    self:Ensure();local best
    for _,data in pairs(FM.Data.crafting) do for _,recipe in ipairs(data.recipes or {}) do
        if recipe.key==key then local v=self:Value(recipe);if v and v.cost then local per=v.cost/math.max(1,recipe.output or 1);best=math.min(best or per,per) end end
    end end
    return best and math.floor(best+.5) or nil
end

function C:AddShopping(recipe,crafts)
    if not recipe then return end;crafts=math.max(1,math.floor(tonumber(crafts) or 1));local added=0
    local group="Crafting: "..(recipe.profession or "Profession")
    for _,r in ipairs(recipe.reagents or {}) do
        local need=(r.count or 0)*crafts;local owned=FM.Ledger and FM.Ledger:OwnedEverywhere(r.key) or 0;local missing=math.max(0,need-owned)
        if missing>0 then
            local skey=group:lower().."/"..r.name:lower();FM.Data.shopping[skey]={name=r.name,group=group,quantity=missing,cap=0};added=added+1
        end
    end
    FM:Status(added>0 and ("Added "..added.." missing reagents to Shopping.") or "You already own the required reagents in known inventory.");FM:Refresh()
end

FM:On("TRADE_SKILL_SHOW",function() C:Capture() end)
FM:On("TRADE_SKILL_UPDATE",function() C:Capture() end)
