local _,FM=...
local U,T=FM.UI,FM.T

local function signedMoney(value)
    value=tonumber(value) or 0;return (value<0 and "-" or (value>0 and "+" or ""))..FM:Money(math.abs(value))
end
local function ledgerText(label,sales,profit)
    return label.."\nNet sales: "..FM:Money(sales).."\nFlip P/L: "..signedMoney(profit)
end

function U:BuildLedger()
    local p=self:NewPanel("Ledger","Empire Ledger / all characters","Account-wide gold snapshots, net sales and realized flip profit. Character attribution starts with ForeverMarket 2.1.")
    self.ledgerMode=self.ledgerMode or "empire";self.ledgerChartMode=self.ledgerChartMode or "sales"
    self.ledgerEmpireButton=T:Button(p,"Empire",104,28,662,2,function() U.ledgerMode="empire";U:RefreshLedger() end)
    self.ledgerActivityButton=T:Button(p,"Activity",104,28,776,2,function() U.ledgerMode="activity";U:RefreshLedger() end)
    self.ledgerToday=T:Panel(p,282,82,0,58);self.ledgerWeek=T:Panel(p,282,82,305,58);self.ledgerAll=T:Panel(p,282,82,610,58)
    self.ledgerTodayText=T:Text(self.ledgerToday,"",11,13,13,256,T.text);self.ledgerWeekText=T:Text(self.ledgerWeek,"",11,13,13,256,T.text);self.ledgerAllText=T:Text(self.ledgerAll,"",11,13,13,256,T.text)

    self.ledgerEmpire=CreateFrame("Frame",nil,p);self.ledgerEmpire:SetAllPoints()
    local chart=T:Panel(self.ledgerEmpire,892,238,0,158);self.ledgerChart=chart
    self.ledgerChartTitle=T:Text(chart,"14-DAY ACCOUNT FLOW",11,16,13,360,T.gold)
    self.ledgerChartTotal=T:Text(chart,"",10,16,34,440,T.muted)
    self.ledgerSalesButton=T:Button(chart,"Net sales",100,25,664,10,function() U.ledgerChartMode="sales";U:RefreshLedger() end)
    self.ledgerProfitButton=T:Button(chart,"Flip profit",106,25,774,10,function() U.ledgerChartMode="profit";U:RefreshLedger() end)
    self.ledgerAxis=T:Panel(chart,846,1,22,126,{.15,.22,.23,.9})
    self.ledgerBars={}
    for i=1,14 do
        local b=CreateFrame("Frame",nil,chart,"BackdropTemplate");b:SetSize(38,1);b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});b:EnableMouse(true)
        b.label=T:Text(chart,"",8,26+(i-1)*60,207,50,T.muted);b.label:SetJustifyH("CENTER")
        b:SetScript("OnEnter",function(s) if not s.data then return end;GameTooltip:SetOwner(s,"ANCHOR_RIGHT");GameTooltip:SetText(date("%d.%m.%Y",s.data.t));GameTooltip:AddLine((U.ledgerChartMode=="profit" and "Realized flip profit: " or "Net sales: ")..FM:PlainMoney(s.data.value),.75,.84,.82,true);GameTooltip:Show() end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end);self.ledgerBars[i]=b
    end
    T:Text(self.ledgerEmpire,"CHARACTERS",10,0,414,220,T.gold)
    local head=T:Panel(self.ledgerEmpire,892,22,0,432);T:Text(head,"CHARACTER",9,10,6,210,T.muted);T:Text(head,"REALM / FACTION",9,230,6,205,T.muted);T:Text(head,"GOLD",9,470,6,118,T.muted);T:Text(head,"7D SALES",9,600,6,120,T.muted);T:Text(head,"7D FLIP P/L",9,735,6,140,T.muted)
    self.ledgerCharRows={}
    for i=1,4 do
        local r=T:Panel(self.ledgerEmpire,892,31,0,457+(i-1)*34);r.name=T:Text(r,"",10,10,9,210,T.text);r.realm=T:Text(r,"",9,230,10,205,T.muted);r.gold=T:Text(r,"",10,470,9,118,T.gold);r.sales=T:Text(r,"",10,600,9,120,T.text);r.profit=T:Text(r,"",10,735,9,140,T.teal);self.ledgerCharRows[i]=r
    end
    self.ledgerEmpireFoot=T:Text(self.ledgerEmpire,"",9,0,594,892,T.muted);self.ledgerEmpireFoot:SetJustifyH("RIGHT")

    self.ledgerActivity=CreateFrame("Frame",nil,p);self.ledgerActivity:SetAllPoints()
    T:Text(self.ledgerActivity,"RECENT ACTIVITY",10,0,166,300,T.gold)
    self.ledgerRows={}
    for i=1,8 do
        local r=T:Panel(self.ledgerActivity,892,43,0,190+(i-1)*46);r.kind=T:Text(r,"",10,10,13,70,T.teal);r.name=T:Text(r,"",11,90,12,330,T.text);r.qty=T:Text(r,"",10,435,13,80,T.muted);r.amount=T:Text(r,"",10,530,13,170,T.gold);r.when=T:Text(r,"",9,720,14,155,T.muted);r.when:SetJustifyH("RIGHT");self.ledgerRows[i]=r
    end
    self.ledgerFoot=T:Text(self.ledgerActivity,"",10,0,574,600,T.muted)
    T:Button(self.ledgerActivity,"Refresh inventory",180,28,712,566,function() FM.Inventory:Scan();FM.Empire:CaptureGold();U:RefreshLedger() end,true)
end

function U:RefreshLedgerChart()
    local mode=self.ledgerChartMode or "sales";local series=FM.Empire:Series(14,mode);local maxAbs=1;local total=0
    for _,d in ipairs(series) do maxAbs=math.max(maxAbs,math.abs(d.value or 0));total=total+(d.value or 0) end
    self.ledgerChartTitle:SetText(mode=="profit" and "14-DAY REALIZED FLIP PROFIT" or "14-DAY NET SALES — ALL CHARACTERS")
    self.ledgerChartTotal:SetText("Total in window: "..FM:Money(total)..(mode=="profit" and " | matched tracked flip purchases only" or " | after AH cut"))
    self.ledgerSalesButton.active=mode=="sales";self.ledgerSalesButton:Paint();self.ledgerProfitButton.active=mode=="profit";self.ledgerProfitButton:Paint()
    local baseline=126;local posRange,negRange=66,52
    for i,b in ipairs(self.ledgerBars) do local d=series[i];b.data=d;b:ClearAllPoints();local v=d and d.value or 0;local h
        if v>=0 then h=math.max(v==0 and 1 or 3,math.floor((math.abs(v)/maxAbs)*posRange));b:SetPoint("BOTTOMLEFT",self.ledgerChart,"TOPLEFT",32+(i-1)*60,-baseline);b:SetSize(34,h);b:SetBackdropColor(.12,.43,.38,.95);b:SetBackdropBorderColor(.30,.67,.58,1)
        else h=math.max(3,math.floor((math.abs(v)/maxAbs)*negRange));b:SetPoint("TOPLEFT",self.ledgerChart,"TOPLEFT",32+(i-1)*60,-baseline);b:SetSize(34,h);b:SetBackdropColor(.46,.16,.15,.95);b:SetBackdropBorderColor(.72,.30,.26,1) end
        b.label:SetText(d and date("%d.%m",d.t) or "")
    end
end

function U:RefreshLedger()
    if not self.ledgerRows then return end;FM.Ledger:Ensure();FM.Empire:Ensure();FM.Empire:CaptureGold()
    local totalGold,charCount=FM.Empire:TotalGold();local flipToday=FM.Flip:RecentProfit(1);local flipWeek=FM.Flip:RecentProfit(7);local flipAll=FM.Flip:RecentProfit(nil)
    self.ledgerTodayText:SetText(ledgerText("TODAY",FM.Empire:NetSales(1),flipToday));self.ledgerWeekText:SetText(ledgerText("7 DAYS",FM.Empire:NetSales(7),flipWeek))
    self.ledgerAllText:SetText("EMPIRE GOLD\n"..FM:Money(totalGold).."\n"..charCount.." characters tracked")
    local empire=self.ledgerMode~="activity";self.ledgerEmpire:SetShown(empire);self.ledgerActivity:SetShown(not empire);self.ledgerEmpireButton.active=empire;self.ledgerEmpireButton:Paint();self.ledgerActivityButton.active=not empire;self.ledgerActivityButton:Paint()
    if empire then
        self:RefreshLedgerChart();local chars=FM.Empire:CharacterStats(7)
        for i,r in ipairs(self.ledgerCharRows) do local d=chars[i];r:SetShown(d~=nil);if d then r.name:SetText(d.name);r.realm:SetText(d.realm.." / "..d.faction);r.gold:SetText(FM:Money(d.gold));r.sales:SetText(FM:Money(d.sales));r.profit:SetText((d.profit>=0 and "+" or "-")..FM:Money(math.abs(d.profit))) end end
        self.ledgerEmpireFoot:SetText(#chars>4 and ("Showing 4 / "..#chars.." characters | open another character once to add/update its gold snapshot") or "Open each character once to keep its gold snapshot current.")
    else
        local list=FM.Data.ledger.entries or {};for i,r in ipairs(self.ledgerRows) do local d=list[#list-i+1];r:SetShown(d~=nil);if d then r.kind:SetText(d.kind);r.name:SetText(d.name);r.qty:SetText("x"..(d.quantity or 1));r.amount:SetText(FM:Money(d.amount or 0));r.when:SetText(date("%d.%m %H:%M",d.t)) end end
        self.ledgerFoot:SetText(#list.." current-realm ledger entries | switch to Empire for account-wide charts")
    end
end
