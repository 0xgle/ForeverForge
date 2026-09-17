local _,FM=...
local S={};FM.Sell=S
function S:ReadSlot()
    if not GetAuctionSellItemInfo then return end
    local name,texture,count,quality,usable,price,unit,maxStack,total,id=GetAuctionSellItemInfo()
    if not name then self.item=nil;if FM.Inventory then FM.Inventory.selectedKey=nil end;FM:Refresh();return end
    local link=self.cursorLink
    if not link or (tonumber(link:match("item:(%d+)"))~=id and id) then link=select(2,GetItemInfo(id or name)) end
    local nextItem={name=name,texture=texture,count=count or 1,quality=quality,key=FM:ItemKey(link,name),link=link,itemID=id,
        maxStack=maxStack or count or 1,total=total or count or 1}
    if self.item and self.item.link==nextItem.link and self.item.total==nextItem.total and self.item.count==nextItem.count then
        for k,v in pairs(nextItem) do self.item[k]=v end
    else
        self.item=nextItem
        if FM.UI then FM.UI:DismissConfirm() end
    end
    FM:Refresh()
end
function S:AcceptCursor()
    if not FM.Market:Ready() then return end
    local kind,id,link=GetCursorInfo();if kind~="item" then FM:Status("Select an item from your bags.");return end
    self.cursorLink=link or select(2,GetItemInfo(id))
    local ok,err=pcall(ClickAuctionSellItemButton)
    if not ok then self.cursorLink=nil;FM:Status(tostring(err));return end
    self:ReadSlot()
    if GetCursorInfo() or not self.item or (id and self.item.itemID and id~=self.item.itemID) then
        self.item=nil;self.cursorLink=nil;FM:Status("The Auction House did not accept this item.");FM:Refresh();return
    end
    local item=self.item
    if item then
        local p=FM.Data.presets[item.key]
        FM.UI.sellStack:SetText(tostring(p and math.min(p.stack,item.maxStack,item.total) or math.min(item.count,item.maxStack)))
        FM.UI.sellCount:SetText("1");FM.UI.sellPrice:SetText(p and FM:PlainMoney(p.unit) or "")
        FM.UI.sellFloor:SetText(p and FM:PlainMoney(p.floor or 0) or "0c")
        self.duration=p and p.duration or FM.DB.settings.defaultDuration
        FM.UI:RefreshSell();FM:Status("Item ready. The price field is per item, not per stack.")
    end
end
function S:Suggest(silent)
    if not self.item then return end
    local best,source
    for _,r in ipairs(FM.Market.results) do
        if r.key==self.item.key and r.unit>0 and not FM.Market:IsMine(r.owner) and time()-r.seen<300 then best=math.min(best or r.unit,r.unit);source="current results" end
    end
    if not best then
        local h=FM:GetHistoryStats(self.item.key)
        if h then best=h.low;source="history ("..math.floor((time()-h.t)/60).." min ago)" end
    end
    if not best then if not silent then FM:Status("No price data. Click Check market and run a search.") end;return end
    local floor=FM:ParseMoney(FM.UI.sellFloor:GetText()) or 0
    local unit=math.max(1,floor,math.floor(best-FM.DB.settings.undercut))
    FM.UI.sellPrice:SetText(FM:PlainMoney(unit));FM:Status("Suggested from "..source.."; your minimum price has been applied.")
end
function S:Values()
    local U=FM.UI
    local stack=FM:Int(U.sellStack:GetText(),1,1000);local count=FM:Int(U.sellCount:GetText(),1,1000)
    local unit=FM:ParseMoney(U.sellPrice:GetText());local floor=FM:ParseMoney(U.sellFloor:GetText())
    if not self.item then return nil,"Select an item from your bags." end
    if not stack or not count or not unit or unit<1 or floor==nil then return nil,"Check quantities and price (e.g. 2g 50s or 25000 copper)." end
    if stack>self.item.maxStack or stack*count>self.item.total then return nil,"Not enough items, or the stack size is too large." end
    if unit<floor then return nil,"The price is below your configured minimum." end
    local total=unit*stack;local max=MAXIMUM_BID_PRICE or 2147483647
    if total>max then return nil,"The price exceeds the client limit." end
    local duration=self.duration or FM.DB.settings.defaultDuration
    local deposit=GetAuctionDeposit and GetAuctionDeposit(duration,total,total,stack,count) or 0
    return {stack=stack,count=count,unit=unit,floor=floor,buyout=total,bid=total,duration=duration,deposit=deposit or 0}
end
function S:SavePreset()
    local v,err=self:Values();if not v then FM:Status(err);return end
    FM.Data.presets[self.item.key]=v;FM:Status("Saved this item's price, stack size, minimum and duration preset.")
end
function S:Post()
    if not FM.Market:Ready() then return end
    self:ReadSlot()
    local v,err=self:Values();if not v then FM:Status(err);return end
    local item=self.item
    if GetMoney()<v.deposit then FM:Status("You do not have enough gold for the deposit.");return end
    FM.UI:Confirm("Post auction",item,(item.link or item.name).."\n"..v.count.." stacks x "..v.stack.." items | Stack price: "..FM:Money(v.buyout).."\nDeposit: "..FM:Money(v.deposit).." | Duration: "..({12,24,48})[v.duration].."h",function()
        if not FM.Market:Ready() then return end
        local now=S:Values()
        if not now or S.item~=item or now.stack~=v.stack or now.count~=v.count or now.unit~=v.unit or now.duration~=v.duration then FM:Status("The form has changed. Please confirm again.");return end
        local name,_,_,_,_,_,_,_,total,id=GetAuctionSellItemInfo()
        if name~=item.name or (id and item.itemID and id~=item.itemID) or (total and total<v.stack*v.count) or GetMoney()<now.deposit then FM:Status("The item or deposit has changed.");return end
        local row={name=item.name,link=item.link,count=v.stack*v.count}
        FM.Market:BeginTransaction("Posting",row,v.buyout*v.count)
        local ok,errorText
        if PostAuction and AuctionsCreateAuctionButton and AuctionsCreateAuctionButton.StartPost then
            -- Native mixin retains Blizzard's extra server warning/confirmation flow.
            ok,errorText=pcall(AuctionsCreateAuctionButton.StartPost,AuctionsCreateAuctionButton,v.bid,v.buyout,v.duration,v.stack,v.count,false)
        elseif StartAuction then ok,errorText=pcall(StartAuction,v.bid,v.buyout,v.duration,v.stack,v.count)
        else ok=false;errorText="Posting is not supported in this client." end
        if not ok then FM.Market:FailTransaction(errorText) else FM:Status("Auction submitted. Check for an additional Blizzard confirmation.") end
    end)
end
FM:On("NEW_AUCTION_UPDATE",function() S:ReadSlot() end)
FM:On("AUCTION_HOUSE_CLOSED",function() S.item=nil;S.cursorLink=nil end)
