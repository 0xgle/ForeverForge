local _,FM=...
local A={rows={}};FM.Advisor=A
function A:Build()
    local rows={}
    for key,hist in pairs(FM.Data.history or {}) do
        local h=FM:GetHistoryStats(key);local c=FM.Data.catalog[key]
        if h and c and h.count>=2 and h.median>0 and h.low>0 then
            local ratio=h.low/h.median;local spread=(h.max-h.min)/math.max(1,h.median)
            local owned=FM.Ledger and FM.Ledger:OwnedEverywhere(key) or 0
            local score=(1-ratio)*100-math.max(0,spread-.7)*20
            local tag
            if ratio<=.70 then tag="DEEP DISCOUNT" elseif ratio<=.85 then tag="BELOW HISTORY" elseif ratio>=1.25 then tag="ABOVE HISTORY" else tag="STABLE" end
            rows[#rows+1]={key=key,name=c.name,link=c.link,low=h.low,median=h.median,last=h.last,ratio=ratio,score=score,tag=tag,owned=owned,samples=h.count,t=h.t}
        end
    end
    table.sort(rows,function(a,b) if a.score==b.score then return a.name<b.name end;return a.score>b.score end)
    self.rows=rows;return rows
end
