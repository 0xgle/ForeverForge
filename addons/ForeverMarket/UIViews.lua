local _,FM=...
local U,T,M,S=FM.UI,FM.T,FM.Market,FM.Sell
function U:BuildSell()
    local p=self:NewPanel("Sell","Sell / from your bags","1. Select an item     2. Check price and quantity     3. Confirm your auction")
    T:Text(p,"YOUR BAGS",11,0,66,180,T.gold)
    T:Button(p,"Refresh",96,25,214,58,function() FM.Inventory:Scan() end)
    self.bagSearch=T:Edit(p,310,30,0,91,"")
    T:Tip(self.bagSearch,"Search your bags","Enter part of an item name. The list updates automatically when your bags change.")
    self.bagSearch:SetScript("OnTextChanged",function() U.bagOffset=0;U:RefreshInventory() end)
    self.bagRows={}
    for i=1,9 do
        local r=T:Button(p,"",310,43,0,134+(i-1)*45,function(b) if b.data then FM.Inventory:Select(b.data) end end)
        r.icon=r:CreateTexture(nil,"ARTWORK");r.icon:SetSize(30,30);r.icon:SetPoint("TOPLEFT",7,-6);r.icon:SetTexCoord(.07,.93,.07,.93)
        r.name=T:Text(r,"",12,46,7,213,T.text);r.info=T:Text(r,"",10,46,25,252,T.muted)
        r.qty=T:Text(r,"",11,263,8,40,T.gold);r.qty:SetJustifyH("RIGHT")
        r:HookScript("OnEnter",function(b)
            if b.data then GameTooltip:SetOwner(b,"ANCHOR_RIGHT");GameTooltip:SetHyperlink(b.data.link);GameTooltip:Show() end
        end)
        r:HookScript("OnLeave",function() GameTooltip:Hide() end)
        self.bagRows[i]=r
    end
    self.bagEmpty=T:Text(p,"",12,12,254,286,T.muted);self.bagEmpty:SetWordWrap(true);self.bagEmpty:SetHeight(90);self.bagEmpty:SetJustifyH("CENTER")
    self.bagCount=T:Text(p,"",10,0,556,198,T.muted);self.bagCount:SetWordWrap(true);self.bagCount:SetHeight(44)
    T:Button(p,"<",42,28,214,550,function() U.bagOffset=math.max(0,(U.bagOffset or 0)-9);U:RefreshInventory() end)
    T:Button(p,">",42,28,268,550,function() U.bagOffset=(U.bagOffset or 0)+9;U:RefreshInventory() end)
    local slot=T:Panel(p,552,82,340,66)
    slot.icon=slot:CreateTexture(nil,"ARTWORK");slot.icon:SetSize(48,48);slot.icon:SetPoint("TOPLEFT",16,-17)
    slot.name=T:Text(slot,"Select an item from the list",16,80,21,451,T.gold)
    slot.info=T:Text(slot,"Click an item in your bags on the left",11,80,49,451,T.muted);self.sellSlot=slot
    local stats=T:Panel(p,552,63,340,160)
    self.sellStats=T:Text(stats,"",11,13,12,524,T.text);self.sellStats:SetWordWrap(true);self.sellStats:SetHeight(46)
    local fields={{"Stack size","sellStack",340,108,248,"1"},{"Stacks","sellCount",460,108,248,"1"},{"Price PER ITEM","sellPrice",584,308,248,""},{"Minimum PER ITEM","sellFloor",340,206,320,"0c"}}
    for _,v in ipairs(fields) do
        T:Text(p,v[1],11,v[3],v[5],v[4],T.muted)
        self[v[2]]=T:Edit(p,v[4],32,v[3],v[5]+22,v[6]);self[v[2]]:SetScript("OnTextChanged",function() U:RefreshSellSummary() end)
    end
    self.durationButtons={}
    T:Text(p,"Duration",11,566,320,310,T.muted)
    for i,h in ipairs({12,24,48}) do
        local d=i;local b=T:Button(p,h.." h",102,32,566+(i-1)*112,342,function() S.duration=d;U:RefreshSell() end);self.durationButtons[i]=b
    end
    T:Button(p,"Check market",176,30,340,392,function()
        if S.item then local name=S.item.name;U:SetTab("Market");U.search:SetText(name);U.exact=true;U.exactButton.label:SetText("Exact name: YES");M:Search(name,0,true) end
    end)
    T:Button(p,"Suggest price",176,30,528,392,function() S:Suggest() end)
    T:Button(p,"Save preset",176,30,716,392,function() S:SavePreset() end)
    local sum=T:Panel(p,552,96,340,438)
    T:Text(sum,"AUCTION SUMMARY",10,13,12,526,T.gold)
    self.sellSummary=T:Text(sum,"",12,13,35,526,T.text);self.sellSummary:SetWordWrap(true);self.sellSummary:SetHeight(57)
    self.sellPost=T:Button(p,"Post auction",230,40,662,550,function() S:Post() end,true)
    local hint=T:Text(p,"Price: e.g. 2g 50s or 25000 copper.\nSelecting an item does not post it.",10,340,555,306,T.muted);hint:SetWordWrap(true);hint:SetHeight(36)
end
function U:RefreshInventory()
    if not self.bagRows then return end
    local I=FM.Inventory;local data={};local filter=self.bagSearch:GetText():lower()
    for _,item in ipairs(I.items) do if item.name:lower():find(filter,1,true) then data[#data+1]=item end end
    self.bagOffset=math.min(self.bagOffset or 0,math.max(0,math.floor((#data-1)/9)*9))
    for i,r in ipairs(self.bagRows) do
        local d=data[self.bagOffset+i];r.data=d;r:SetShown(d~=nil)
        if d then
            r.icon:SetTexture(d.texture);r.name:SetText(d.name);r.qty:SetText(d.total)
            local preset=FM.Data.presets[d.key]
            r.info:SetText(not d.available and "Temporarily locked" or preset and ("Preset: "..FM:Money(preset.unit).." / item") or "Click to prepare an auction")
            r.active=I.selectedKey==d.inventoryKey;r:Paint();r:SetEnabled(d.available and M.open and not M.transaction)
        end
    end
    self.bagCount:SetText(#data.." items | page "..(math.floor(self.bagOffset/9)+1).."\n"..(I.skipped or 0).." excluded"..((I.uncached or 0)>0 and (" | "..I.uncached.." loading") or ""))
    self.bagEmpty:SetShown(#data==0)
    self.bagEmpty:SetText(filter~="" and "No items match your filter." or "No eligible items found.\nBound and quest items are excluded.")
end
function U:RefreshSellSummary()
    if not self.sellSummary or not self.sellFloor then return end
    local v,err=S:Values()
    if self.sellPost then self.sellPost:SetEnabled(v~=nil and M.open and not M.transaction) end
    if not v then self.sellSummary:SetText(err or "Select an item from your bags.");return end
    local total=v.buyout*v.count;local net=math.floor(total*(1-FM.DB.settings.cut))
    self.sellSummary:SetText("Stack: "..FM:Money(v.buyout).."  |  Total: "..FM:Money(total).."\nDeposit: "..FM:Money(v.deposit).."  |  After fees: ~"..FM:Money(net).."\n"..v.count.." stacks x "..v.stack.." items  /  "..({12,24,48})[v.duration].." h")
end
function U:RefreshSell()
    if not self.sellSlot then return end
    local item=S.item
    self.sellSlot.name:SetText(item and item.name or "Select an item from the list")
    self.sellSlot.info:SetText(item and ("Available: "..item.total.." | Max stack: "..item.maxStack) or "Click an item in your bags on the left")
    self.sellSlot.icon:SetTexture(item and item.texture or "Interface\\Icons\\INV_Misc_Bag_10")
    local h=item and FM:GetHistoryStats(item.key)
    self.sellStats:SetText(h and ("Median: "..FM:Money(h.median).." / item\nLast minimum: "..FM:Money(h.low).." | "..math.floor((time()-h.t)/60).." min ago") or "No local prices. Enter a price or click Check market.")
    for i,b in ipairs(self.durationButtons) do b.active=i==(S.duration or FM.DB.settings.defaultDuration);b:Paint() end
    self:RefreshInventory();self:RefreshSellSummary()
end
function U:BuildShopping()
    local p=self:NewPanel("Shopping","Shopping lists / watchlist","Save an item name, unit price limit and target quantity. Click Search to look up each item.")
    local fields={{"Item name","shopName",0,320,""},{"List / group","shopGroup",336,168,"Raid"},{"Quantity","shopQty",520,90,"1"},{"Max / item","shopCap",626,150,"0c"}}
    for _,v in ipairs(fields) do T:Text(p,v[1],11,v[3],66,v[4],T.muted);self[v[2]]=T:Edit(p,v[4],32,v[3],87,v[5]) end
    T:Button(p,"Save",102,32,790,87,function()
        local name=U.shopName:GetText():match("^%s*(.-)%s*$");local group=U.shopGroup:GetText():match("^%s*(.-)%s*$")
        local qty=FM:Int(U.shopQty:GetText(),1,10000);local cap=FM:ParseMoney(U.shopCap:GetText())
        if name=="" or #name>63 or not qty or not cap then FM:Status("Enter a name, valid quantity and price limit (0c = no limit).");return end
        if group=="" then group="My list" end
        local key=group:lower().."/"..name:lower()
        if U.shopEditingKey and U.shopEditingKey~=key then FM.Data.shopping[U.shopEditingKey]=nil end
        U.shopEditingKey=nil;FM.Data.shopping[key]={name=name,group=group,quantity=qty,cap=cap};U:RefreshShopping();FM:Status("Shopping list entry saved.")
    end,true)
    self.shopFilter=T:Edit(p,300,28,0,141,"");T:Tip(self.shopFilter,"Filter lists","Enter a group or item name.")
    self.shopFilter:SetScript("OnTextChanged",function() U.shopOffset=0;U:RefreshShopping() end)
    T:Text(p,"Items starred on the Market appear in your Watchlist.",11,322,150,564,T.muted)
    self.shopRows={}
    for i=1,8 do
        local r=T:Panel(p,892,44,0,187+(i-1)*46)
        r.name=T:Text(r,"",12,12,8,314,T.text);r.group=T:Text(r,"",10,12,26,314,T.muted)
        r.qty=T:Text(r,"",11,340,16,70,T.muted);r.cap=T:Text(r,"",11,420,16,172,T.gold)
        T:Button(r,"Search",82,28,608,8,function()
            local d=r.data;if not d then return end
            U:SetTab("Market");U.search:SetText(d.name);U.maxPrice:SetText(d.cap and d.cap>0 and FM:PlainMoney(d.cap) or "");U.filter:SetText("")
            U.exact=true;U.exactButton.label:SetText("Exact name: YES");M:Search(d.name,0,true)
        end,true)
        T:Button(r,"Edit",82,28,702,8,function()
            local d=r.data;if d then U.shopEditingKey=not d.watch and d.key or nil;U.shopName:SetText(d.name);U.shopGroup:SetText(d.group or "My list");U.shopQty:SetText(tostring(d.quantity or 1));U.shopCap:SetText(FM:PlainMoney(d.cap or 0)) end
        end)
        T:Button(r,"Remove",82,28,796,8,function()
            local d=r.data;if d then if d.watch then FM.Data.watchlist[d.key]=nil else FM.Data.shopping[d.key]=nil end;U:RefreshShopping() end
        end)
        self.shopRows[i]=r
    end
    self.shopPage=T:Text(p,"",11,0,578,600,T.muted)
    T:Button(p,"<",52,28,780,568,function() U.shopOffset=math.max(0,(U.shopOffset or 0)-8);U:RefreshShopping() end)
    T:Button(p,">",52,28,840,568,function() U.shopOffset=(U.shopOffset or 0)+8;U:RefreshShopping() end)
end
function U:RefreshShopping()
    if not self.shopRows then return end
    local rows={};local filter=self.shopFilter:GetText():lower()
    for key,d in pairs(FM.Data.shopping) do
        if (d.name.." "..d.group):lower():find(filter,1,true) then rows[#rows+1]={key=key,name=d.name,group=d.group,quantity=d.quantity,cap=d.cap} end
    end
    for key,d in pairs(FM.Data.watchlist) do
        if (d.name.." Watchlist"):lower():find(filter,1,true) then rows[#rows+1]={key=key,name=d.name,group="Watchlist",watch=true,quantity=1,cap=0} end
    end
    table.sort(rows,function(a,b) if a.group==b.group then return a.name<b.name end;return a.group<b.group end)
    local maxOffset=math.max(0,math.floor((#rows-1)/8)*8);self.shopOffset=math.min(self.shopOffset or 0,maxOffset)
    for i,r in ipairs(self.shopRows) do
        local d=rows[self.shopOffset+i];r.data=d;r:SetShown(d~=nil)
        if d then r.name:SetText(d.name);r.group:SetText(d.group);r.qty:SetText("x "..d.quantity);r.cap:SetText(d.cap>0 and FM:Money(d.cap) or "No limit") end
    end
    self.shopPage:SetText(#rows.." entries | page "..(math.floor(self.shopOffset/8)+1).." | quantities are a shopping plan, not automatic orders")
end
function U:BuildHistory()
    local p=self:NewPanel("History","Price history / market memory","Asking prices from your observations. These are not confirmed sale prices.")
    self.historyFilter=T:Edit(p,400,32,0,65,"");self.historyFilter:SetScript("OnTextChanged",function() U.historyOffset=0;U:RefreshHistory() end)
    T:Button(p,"Prices / activity",176,32,716,65,function() U.showLog=not U.showLog;U.historyOffset=0;U:RefreshHistory() end)
    self.historyRows={}
    for i=1,9 do
        local r=T:Button(p,"",892,43,0,117+(i-1)*46,function(b)
            if b.data and b.data.name then U:SetTab("Market");U.search:SetText(b.data.name);M:Search(b.data.name,0,true) end
        end)
        r.name=T:Text(r,"",12,12,8,310,T.text);r.sub=T:Text(r,"",10,12,27,310,T.muted)
        r.median=T:Text(r,"",11,330,15,204,T.gold);r.low=T:Text(r,"",11,548,15,200,T.teal);r.age=T:Text(r,"",10,764,15,120,T.muted)
        self.historyRows[i]=r
    end
    self.historyPage=T:Text(p,"",11,0,574,740,T.muted)
    T:Button(p,"<",52,28,780,565,function() U.historyOffset=math.max(0,(U.historyOffset or 0)-9);U:RefreshHistory() end)
    T:Button(p,">",52,28,840,565,function() U.historyOffset=(U.historyOffset or 0)+9;U:RefreshHistory() end)
end
function U:RefreshHistory()
    if not self.historyRows then return end
    local data={};local filter=self.historyFilter:GetText():lower()
    if self.showLog then
        for i=#FM.Data.log,1,-1 do local d=FM.Data.log[i];if (d.name or ""):lower():find(filter,1,true) then data[#data+1]=d end end
    else
        for key in pairs(FM.Data.history) do
            local c=FM.Data.catalog[key] or {name=key};local h=FM:GetHistoryStats(key)
            if h and c.name:lower():find(filter,1,true) then data[#data+1]={name=c.name,link=c.link,h=h,t=h.t} end
        end
        table.sort(data,function(a,b) return a.t>b.t end)
    end
    self.historyOffset=math.min(self.historyOffset or 0,math.max(0,math.floor((#data-1)/9)*9))
    for i,r in ipairs(self.historyRows) do
        local d=data[self.historyOffset+i];r.data=d;r:SetShown(d~=nil)
        if d then
            r.name:SetText(d.name)
            r.sub:SetText(d.h and (d.h.count.." samples | click to search") or (FM:LogLabel(d.kind).." | "..FM:LogLabel(d.status)))
            r.median:SetText(d.h and ("Median: "..FM:Money(d.h.median)) or ("Amount: "..FM:Money(d.amount)))
            r.low:SetText(d.h and ("Last minimum: "..FM:Money(d.h.low)) or ("Quantity: "..d.quantity))
            r.age:SetText(date("%d.%m %H:%M",d.t))
        end
    end
    self.historyPage:SetText((self.showLog and "Activity log" or "Local history").." | "..#data.." entries | page "..(math.floor(self.historyOffset/9)+1))
end
function U:BuildSettings()
    local p=self:NewPanel("Settings","Settings / ForeverMarket","Adjust your preferences below, then click Save settings.")
    self.autoButton=T:Button(p,"",434,38,0,72,function() FM.DB.settings.openWithAH=not FM.DB.settings.openWithAH;U:RefreshSettings() end)
    self.tooltipButton=T:Button(p,"",434,38,458,72,function() FM.DB.settings.tooltip=not FM.DB.settings.tooltip;U:RefreshSettings() end)
    local fields={{"Undercut amount (e.g. 1c)","settingUndercut",0,160},{"Deals: maximum % of reference price","settingDeal",308,160},{"Auction House fee: % (5 or 15)","settingCut",616,160},{"Window scale: 0.65 - 1.20","settingScale",0,266}}
    for _,v in ipairs(fields) do T:Text(p,v[1],12,v[3],v[4],276,T.muted);self[v[2]]=T:Edit(p,274,34,v[3],v[4]+28) end
    T:Button(p,"Save settings",274,36,308,293,function()
        local under=FM:ParseMoney(U.settingUndercut:GetText());local deal=tonumber(U.settingDeal:GetText());local cut=tonumber(U.settingCut:GetText());local scale=tonumber(U.settingScale:GetText())
        if not under or under<0 or under>100000000 or not deal or deal<1 or deal>100 or not cut or (cut~=5 and cut~=15) or not scale or scale<.65 or scale>1.2 then FM:Status("Check the setting ranges. Fee: 5% for faction AH, 15% for neutral AH.");return end
        local s=FM.DB.settings;s.undercut=under;s.dealThreshold=deal/100;s.cut=cut/100;s.scale=scale
        U:ApplyPosition();FM:Status("Settings saved.");U:Refresh()
    end,true)
    T:Button(p,"Center window",276,36,616,293,function() FM.DB.settings.position=nil;U:ApplyPosition() end)
    local info=T:Panel(p,892,221,0,367)
    T:Text(info,"CLASSIC ERA  /  "..FM.version,13,18,18,854,T.gold)
    local help=T:Text(info,"/fm - toggle window    /fm settings - settings    /fm blizzard - Blizzard interface\n/fm scan - full scan    /fm reset - center window    /fm debug - diagnostics\n\nDeals compare prices against local history or the median of loaded results.\nFull scans depend on server limits. Search scanned items again before buying.\nSet the fee to 15% at a neutral AH; price history is separated by realm and faction.\nDisable other Auction House replacements while testing this version.\n\nAuthor: 0xgle. All rights reserved. ForeverCore is optional.",12,18,48,852,T.muted)
    help:SetWordWrap(true);help:SetHeight(165)
end
function U:RefreshSettings()
    if not self.autoButton then return end
    local s=FM.DB.settings
    self.autoButton.label:SetText("Replace Blizzard interface: "..(s.openWithAH and "YES" or "NO"))
    self.tooltipButton.label:SetText("Show prices in tooltips: "..(s.tooltip and "YES" or "NO"))
    self.settingUndercut:SetText(FM:PlainMoney(s.undercut));self.settingDeal:SetText(tostring(math.floor(s.dealThreshold*100+.5)))
    self.settingCut:SetText(tostring(math.floor(s.cut*100+.5)));self.settingScale:SetText(tostring(s.scale))
end
function U:BuildConfirm()
    local overlay=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");overlay:SetAllPoints();overlay:SetFrameLevel(self.frame:GetFrameLevel()+50)
    overlay:EnableMouse(true);overlay:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});overlay:SetBackdropColor(0,0,0,.82);overlay:Hide();self.confirm=overlay
    local p=T:Panel(overlay,560,242,300,245,{.025,.055,.063,1});p:SetBackdropBorderColor(.58,.49,.32,1)
    self.confirmTitle=T:Text(p,"",20,22,21,516,T.gold)
    self.confirmText=T:Text(p,"",13,22,67,516,T.text);self.confirmText:SetWordWrap(true);self.confirmText:SetHeight(95)
    T:Button(p,"Back",154,34,206,186,function() U:DismissConfirm() end)
    self.confirmAccept=T:Button(p,"Confirm",154,34,376,186,function()
        local fn=U.confirmAction;U:DismissConfirm();if fn then fn() end
    end,true)
end
function U:Confirm(title,row,text,fn)
    self:Build();self.confirmTitle:SetText(title);self.confirmText:SetText(text);self.confirmAction=fn;self.confirm:Show()
end
function U:DismissConfirm() self.confirmAction=nil;if self.confirm then self.confirm:Hide() end end
function U:Refresh()
    if not self.frame or not FM.Data then return end
    self.money:SetText(FM:Money(GetMoney()))
    self.connection:SetText(M.open and "AUCTION HOUSE OPEN" or "OFFLINE MODE")
    local count=0;for _ in pairs(FM.Data.history) do count=count+1 end
    self.sideStats:SetText("Items: "..count.."\nQueries: "..(FM.Data.stats.scans or 0).."\nLast scan: "..(FM.Data.stats.lastFull and date("%d.%m %H:%M",FM.Data.stats.lastFull) or "no full scan"))
    if self.activeTab=="Market" or self.activeTab=="Deals" or self.activeTab=="Owned" then self:RefreshMarket()
    elseif self.activeTab=="Sell" then self:RefreshSell()
    elseif self.activeTab=="Shopping" then self:RefreshShopping()
    elseif self.activeTab=="History" then self:RefreshHistory()
    elseif self.activeTab=="Settings" then self:RefreshSettings() end
    if not FM:Supported() then self:SetStatus("Legacy auction API unavailable. Use the Blizzard interface to trade on this client.")
    else self:SetStatus(FM.lastStatus or "Ready. Enter an item name to search.") end
end
FM:On("PLAYER_MONEY",function() if U.money then U.money:SetText(FM:Money(GetMoney()));U:RefreshSellSummary() end end)
FM:On("DISPLAY_SIZE_CHANGED",function() U:ApplyPosition() end)
FM:On("PLAYER_LOGIN",function()
    if FM:Supported() and GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetItem",function(tip)
            if not FM.DB.settings.tooltip then return end
            local name,link=tip:GetItem();if not link then return end
            local h=FM:GetHistoryStats(FM:ItemKey(link,name))
            if h then tip:AddLine("ForeverMarket | median/item: "..FM:Money(h.median),.6,.84,.78);tip:AddLine("Data age: "..math.floor((time()-h.t)/60).." min | "..h.count.." samples",.6,.66,.67) end
        end)
    end
end)
