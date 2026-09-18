local _,FM=...
local U,T=FM.UI,FM.T

local function signedMoney(value)
    value=tonumber(value) or 0;return (value<0 and "-" or (value>0 and "+" or ""))..FM:Money(math.abs(value))
end

local function saveFlipFilters()
    local roi=tonumber(U.flipROI:GetText());local profit=FM:ParseMoney(U.flipProfit:GetText());local cap=FM:ParseMoney(U.flipCapital:GetText());local samples=tonumber(U.flipSamples:GetText())
    if not roi or roi<0 or roi>1000 then FM:Status("Flip ROI must be between 0 and 1000 percent.");return false end
    if profit==nil or profit<0 then FM:Status("Enter a valid minimum profit, for example 1g 50s.");return false end
    if cap==nil or cap<0 then FM:Status("Enter a valid investment cap. Use 0 for unlimited.");return false end
    if not samples or samples<1 or samples~=math.floor(samples) then FM:Status("Minimum samples must be a whole number.");return false end
    FM.Flip:SetSettings({minROI=roi/100,minProfit=profit,maxInvestment=cap,minSamples=samples});return true
end

function U:BuildFlips()
    local p=self:NewPanel("Flips","Flip Finder / buy low, exit with a plan","Live opportunities from loaded results or your watchlist. Profit includes the configured Auction House cut.")
    self.flipCardA=T:Panel(p,282,66,0,58);self.flipCardB=T:Panel(p,282,66,305,58);self.flipCardC=T:Panel(p,282,66,610,58)
    self.flipCardAText=T:Text(self.flipCardA,"",11,13,12,256,T.text);self.flipCardBText=T:Text(self.flipCardB,"",11,13,12,256,T.text);self.flipCardCText=T:Text(self.flipCardC,"",11,13,12,256,T.text)

    T:Text(p,"ROI >=",10,0,145,48,T.muted);self.flipROI=T:Edit(p,58,28,52,137,"15")
    T:Text(p,"Profit >=",10,124,145,62,T.muted);self.flipProfit=T:Edit(p,100,28,190,137,"1g")
    T:Text(p,"Max spend",10,304,145,64,T.muted);self.flipCapital=T:Edit(p,100,28,372,137,"0")
    T:Text(p,"Samples",10,486,145,58,T.muted);self.flipSamples=T:Edit(p,50,28,546,137,"2")
    T:Button(p,"Analyze loaded",118,29,602,137,function() if saveFlipFilters() then FM.Flip:AnalyzeLoaded(false) end end,true)
    T:Button(p,"Watch scan",112,29,726,137,function() if saveFlipFilters() then FM.Flip:StartWatchScan() end end)
    T:Button(p,"Stop",48,29,844,137,function() FM.Flip:Stop() end)

    local head=T:Panel(p,892,24,0,180)
    T:Text(head,"ITEM",9,9,7,225,T.muted);T:Text(head,"BUY",9,250,7,100,T.muted);T:Text(head,"EXIT PLAN",9,360,7,105,T.muted)
    T:Text(head,"NET PROFIT",9,480,7,112,T.muted);T:Text(head,"ROI",9,610,7,62,T.muted);T:Text(head,"CONF.",9,686,7,65,T.muted);T:Text(head,"",9,770,7,110,T.muted)
    self.flipRows={}
    for i=1,7 do
        local r=T:Panel(p,892,44,0,207+(i-1)*47)
        r.name=T:Text(r,"",11,10,7,225,T.text);r.sub=T:Text(r,"",9,10,26,225,T.muted)
        r.buy=T:Text(r,"",10,250,15,100,T.gold);r.exit=T:Text(r,"",10,360,15,105,T.text)
        r.profit=T:Text(r,"",10,480,15,112,T.teal);r.roi=T:Text(r,"",10,610,15,62,T.teal);r.conf=T:Text(r,"",10,686,15,65,T.muted)
        r.review=T:Button(r,"Review",96,26,786,9,function() if r.data then FM.Flip:Review(r.data) end end,true)
        self.flipRows[i]=r
    end
    self.flipFoot=T:Text(p,"",10,0,548,892,T.muted);self.flipFoot:SetWordWrap(true);self.flipFoot:SetHeight(42)
end

function U:RefreshFlips()
    if not self.flipRows then return end;FM.Flip:Ensure();local s=FM.Flip:Settings()
    if not self.flipEditing then
        self.flipROI:SetText(tostring(math.floor((s.minROI or .15)*100+.5)));self.flipProfit:SetText(FM:PlainMoney(s.minProfit or 0));self.flipCapital:SetText(FM:PlainMoney(s.maxInvestment or 0));self.flipSamples:SetText(tostring(s.minSamples or 2))
    end
    local rows=FM.Flip.candidates or {};local totalProfit,totalCost,best=0,0,0
    for _,d in ipairs(rows) do totalProfit=totalProfit+(d.profit or 0);totalCost=totalCost+(d.cost or 0);best=math.max(best,d.roi or 0) end
    local acct=FM.Flip:BuildAccounting()
    self.flipCardAText:SetText("OPPORTUNITIES\n"..#rows.." ready   |   best ROI "..string.format("%.0f%%",best*100))
    self.flipCardBText:SetText("TRACKED FLIPS\nInvested "..FM:Money(acct.invested).."\nRealized P/L "..signedMoney(acct.realized))
    self.flipCardCText:SetText("CURRENT SET\nCapital "..FM:Money(totalCost).."\nPotential net "..FM:Money(totalProfit))
    for i,r in ipairs(self.flipRows) do local d=rows[i];r.data=d;r:SetShown(d~=nil);if d then
        r.name:SetText(d.name);r.sub:SetText(d.tag.." | x"..d.count.." | "..d.samples.." samples")
        r.buy:SetText(FM:Money(d.cost));r.exit:SetText(FM:Money(d.exitUnit).." /ea");r.profit:SetText("+"..FM:Money(d.profit));r.roi:SetText(string.format("%.0f%%",d.roi*100));r.conf:SetText(d.confidence.."%")
    end end
    local scan=FM.Flip.scan
    if scan then self.flipFoot:SetText("SCANNING WATCHLIST  "..math.min(scan.index,#scan.queue).." / "..#scan.queue.."  |  each candidate is re-checked before purchase.")
    elseif #rows==0 then self.flipFoot:SetText("No opportunities loaded. Search an item in Market and click Analyze loaded, or add items to the watchlist with Shift-click and run Scan watchlist.")
    else self.flipFoot:SetText("Review always refreshes the live auction before buying. Exit price is capped by history and the next competing price; it is a plan, not a guaranteed sale.") end
end
