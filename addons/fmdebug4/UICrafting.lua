local _,FM=...
local U,T=FM.UI,FM.T

function U:BuildCrafting()
    local p=self:NewPanel("Crafting","Crafting Profit / profession memory","Open a profession once to capture recipes. Values use your local ForeverMarket price sources.")
    self.craftFilter=T:Edit(p,300,30,0,61,"");self.craftFilter:SetScript("OnTextChanged",function() U.craftOffset=0;U:RefreshCrafting() end)
    T:Button(p,"Capture open profession",190,30,702,61,function() FM.Crafting:Capture() end,true)
    local head=T:Panel(p,892,24,0,103);T:Text(head,"RECIPE",9,10,7,290,T.muted);T:Text(head,"CRAFT COST",9,330,7,125,T.muted);T:Text(head,"MARKET VALUE",9,470,7,135,T.muted);T:Text(head,"PROFIT",9,620,7,115,T.muted);T:Text(head,"OWN MATS",9,745,7,80,T.muted)
    self.craftRows={}
    for i=1,8 do
        local r=T:Button(p,"",892,48,0,132+(i-1)*51,function(b) if b.data then U:SetTab("Market");U.search:SetText(b.data.name);FM.Market:Search(b.data.name,0,true) end end)
        r.name=T:Text(r,"",11,10,7,290,T.text);r.prof=T:Text(r,"",9,10,27,290,T.muted)
        r.cost=T:Text(r,"",10,330,17,125,T.gold);r.value=T:Text(r,"",10,470,17,135,T.gold);r.profit=T:Text(r,"",10,620,17,115,T.teal);r.mats=T:Text(r,"",10,745,17,75,T.text);r.mats:SetJustifyH("RIGHT")
        T:Button(r,"Shop",55,27,827,10,function() if r.data then FM.Crafting:AddShopping(r.data,1) end end,true)
        self.craftRows[i]=r
    end
    self.craftFoot=T:Text(p,"",10,0,551,700,T.muted)
    T:Button(p,"<",52,28,780,558,function() U.craftOffset=math.max(0,(U.craftOffset or 0)-8);U:RefreshCrafting() end)
    T:Button(p,">",52,28,840,558,function() U.craftOffset=(U.craftOffset or 0)+8;U:RefreshCrafting() end)
end

function U:RefreshCrafting()
    if not self.craftRows then return end
    local filter=self.craftFilter:GetText():lower();local rows={}
    for _,r in ipairs(FM.Crafting:Rows()) do if filter=="" or r.name:lower():find(filter,1,true) or r.profession:lower():find(filter,1,true) then rows[#rows+1]=r end end
    local maxOffset=math.max(0,math.floor((#rows-1)/8)*8);self.craftOffset=math.min(self.craftOffset or 0,maxOffset)
    for i,ui in ipairs(self.craftRows) do local d=rows[self.craftOffset+i];ui.data=d;ui:SetShown(d~=nil);if d then
        ui.name:SetText(d.name);ui.prof:SetText(d.profession.." | "..(#(d.reagents or {})).." reagents")
        ui.cost:SetText(d.cost and FM:Money(d.cost) or "missing price");ui.value:SetText(d.revenue and FM:Money(d.revenue) or "missing price")
        ui.profit:SetText(d.profit and ((d.profit>=0 and "+" or "")..FM:Money(d.profit)) or "-");ui.mats:SetText(tostring(d.craftable or 0))
    end end
    local professions=0;for _ in pairs(FM.Data.crafting or {}) do professions=professions+1 end
    self.craftFoot:SetText(#rows.." recipes | "..professions.." professions remembered | values are estimates from asking-price history, not guaranteed sales")
end
