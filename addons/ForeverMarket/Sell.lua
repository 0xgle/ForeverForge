local _,FM=...
local S={};FM.Sell=S

local function modern()
    return FM:IsModernAH()
end

local function makeLocation(bag,slot)
    if not ItemLocation or type(ItemLocation.CreateFromBagAndSlot)~="function" then return nil end
    local ok,loc=pcall(ItemLocation.CreateFromBagAndSlot,ItemLocation,bag,slot)
    if ok then return loc end
end

local function clearNativeSellFrames()
    if not AuctionHouseFrame then return end
    local itemFrame=AuctionHouseFrame.ItemSellFrame
    local commodityFrame=AuctionHouseFrame.CommoditiesSellFrame
    if itemFrame and type(itemFrame.SetItem)=="function" then pcall(itemFrame.SetItem,itemFrame,nil,nil,false) end
    if commodityFrame and type(commodityFrame.SetItem)=="function" then pcall(commodityFrame.SetItem,commodityFrame,nil,nil,false) end
end

local function supportsCopper()
    -- WoW Forever 1.60.1 reports WOW_PROJECT_MAINLINE. On this project the
    -- modern Auction House silently rejects new listings whose price contains
    -- copper. Match the working modern-AH posting contract: prices must be at
    -- least 1 silver and use whole-silver increments. Do not trust
    -- SupportsCopperValues() for posting eligibility on this client.
    if WOW_PROJECT_ID==WOW_PROJECT_MAINLINE then return false end
    if C_AuctionHouse and type(C_AuctionHouse.SupportsCopperValues)=="function" then
        local ok,v=pcall(C_AuctionHouse.SupportsCopperValues)
        if ok then return v==true end
    end
    return true
end

local function normalizeModernPrice(value)
    local price=math.max(0,math.floor((tonumber(value) or 0)+0.5))
    if supportsCopper() then return math.max(1,price) end
    if price<100 then return 100 end
    local copper=price%100
    if copper~=0 then price=price+(100-copper) end
    return price
end

function S:IsAHReadyForPost()
    local A=FM.AuctionService
    return A and A:IsModern() and A:IsThrottleReady()
end

function S:IsPostReady()
    if not modern() then return self.item~=nil end
    if not self.item or self.item.resolvingCommodity then return false end
    if not self.item.location or not (C_Item and C_Item.DoesItemExist and C_Item.DoesItemExist(self.item.location)) then return false end
    return self:IsAHReadyForPost()
end

function S:ResolveCommodity(item)
    if not item or self.item~=item then return end
    local status
    if C_AuctionHouse.GetItemCommodityStatus and Enum and Enum.ItemCommodityStatus then
        local ok,v=pcall(C_AuctionHouse.GetItemCommodityStatus,item.location)
        if ok then status=v end
        if status==Enum.ItemCommodityStatus.Commodity then
            item.isCommodity=true;item.resolvingCommodity=false;FM:Refresh();return
        end
        if Enum.ItemCommodityStatus.Item and status==Enum.ItemCommodityStatus.Item then
            item.isCommodity=false;item.resolvingCommodity=false;FM:Refresh();return
        end
    end

    local key=item.itemKey
    if not key and C_AuctionHouse.MakeItemKey then
        local ok,v=pcall(C_AuctionHouse.MakeItemKey,item.itemID);if ok then key=v end
    end
    if key and C_AuctionHouse.GetItemKeyInfo then
        local ok,info=pcall(C_AuctionHouse.GetItemKeyInfo,key)
        if ok and info then
            item.itemKey=key;item.isCommodity=not not info.isCommodity;item.resolvingCommodity=false;FM:Refresh();return
        end
    end

    item.resolveAttempts=(item.resolveAttempts or 0)+1
    if item.resolveAttempts<40 then
        FM:After(.05,function() if S.item==item then S:ResolveCommodity(item) end end)
    else
        item.resolvingCommodity=false
        FM:Status("Could not determine this item's Auction House type. Select it again.")
        FM:Refresh()
    end
end

function S:ClearSelection()
    if modern() and self.item and self.item.location and C_Item and type(C_Item.UnlockItem)=="function" then
        pcall(C_Item.UnlockItem,self.item.location)
    end
    self.item=nil
    self.cursorLink=nil
    self.pendingCheck=nil
    if FM.Inventory then FM.Inventory.selectedKey=nil end
    if FM.UI then FM.UI:DismissConfirm() end
    FM:Refresh()
end

function S:AfterModernPostSubmitted(item,values)
    local row={name=item.name,link=item.link,key=item.key,count=values.quantity}
    FM:Log("Posting",row,values.unit*values.quantity,"submitted")
    self:ClearSelection()
    FM:Status("Auction submitted.")
    FM:After(.20,function() if FM.Inventory and FM.Inventory.Scan then FM.Inventory:Scan() end end)
end

function S:OnModernPostAccepted()
    local p=self.pendingPost
    if not p then
        if FM.Native and FM.Native.FinishNativePostConfirmation then FM.Native:FinishNativePostConfirmation() end
        return
    end
    self.pendingPost=nil
    self:AfterModernPostSubmitted(p.item,p.values)
    if FM.Native and FM.Native.FinishNativePostConfirmation then FM.Native:FinishNativePostConfirmation() end
end

function S:SelectLocation(bag,slot,source)
    if not modern() then return false end
    if not FM.Market:Ready() then return true end
    local location=makeLocation(bag,slot)
    if not location then FM:Status("Item location API is unavailable.");return true end
    if C_AuctionHouse.IsSellItemValid then
        local ok,valid=pcall(C_AuctionHouse.IsSellItemValid,location)
        if ok and not valid then FM:Status("This item cannot be sold on the Auction House.");return true end
    end

    local info=C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag,slot)
    if not info or not info.hyperlink then FM:Status("The selected item is no longer in your bags.");return true end
    local name,link,quality,_,_,_,_,maxStack,_,texture=FM:GetItemInfo(info.hyperlink)
    if not name then FM:Status("Item data is still loading. Try again.");return true end

    clearNativeSellFrames()

    local itemKey
    if C_AuctionHouse.GetItemKeyFromItem then
        local ok,v=pcall(C_AuctionHouse.GetItemKeyFromItem,location);if ok then itemKey=v end
    end
    if not itemKey and C_AuctionHouse.MakeItemKey then
        local ok,v=pcall(C_AuctionHouse.MakeItemKey,info.itemID);if ok then itemKey=v end
    end
    self.item={
        name=name,link=info.hyperlink or link,itemID=info.itemID,texture=info.iconFileID or texture,quality=quality or info.quality or 1,
        count=info.stackCount or 1,total=info.stackCount or 1,maxStack=maxStack or info.stackCount or 1,
        key=FM:ItemKey(info.hyperlink,name),bag=bag,slot=slot,location=location,itemKey=itemKey,isCommodity=false,modern=true,
        resolvingCommodity=true,
    }
    if C_Item and type(C_Item.LockItem)=="function" then
        pcall(C_Item.LockItem,self.item.location)
    end
    self:ResolveCommodity(self.item)
    self.cursorLink=nil
    if FM.UI then FM.UI:DismissConfirm() end

    local preset=FM.Data.presets[self.item.key]
    FM.UI.sellStack:SetText(tostring(preset and math.min(preset.stack or 1,self.item.total) or self.item.total))
    FM.UI.sellCount:SetText("1")
    FM.UI.sellPrice:SetText(preset and FM:PlainMoney(preset.unit) or "")
    FM.UI.sellFloor:SetText(preset and FM:PlainMoney(preset.floor or 0) or "0c")
    self.duration=preset and preset.duration or FM.DB.settings.defaultDuration
    FM:Status("Selected "..name..". Preparing Auction House data...")
    FM.UI:RefreshSell()
    if not preset then
        local selected=self.item
        FM:After(.05,function() if S.item==selected and FM.Market.open and not selected.resolvingCommodity then S:CheckMarket() end end)
    end
    return true
end

function S:ReadModernSlot()
    if not self.item or not self.item.modern then return end
    local item=self.item
    local info=C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(item.bag,item.slot)
    if not info or not info.hyperlink or info.itemID~=item.itemID then
        self.item=nil
        if FM.Inventory then FM.Inventory.selectedKey=nil end
        FM:Refresh()
        return
    end
    item.total=info.stackCount or item.total
    item.count=info.stackCount or item.count
    item.texture=info.iconFileID or item.texture
    item.link=info.hyperlink or item.link
    -- Keep the exact ItemLocation selected and locked for the whole posting flow,
    -- matching the native modern-AH/Auctionator contract. Recreate only if it
    -- genuinely became invalid.
    if not item.location or not (C_Item and C_Item.DoesItemExist and C_Item.DoesItemExist(item.location)) then
        item.location=makeLocation(item.bag,item.slot) or item.location
        if item.location and C_Item and type(C_Item.LockItem)=="function" then pcall(C_Item.LockItem,item.location) end
    end
    FM:Refresh()
end
function S:ReadSlot()
    if modern() then return self:ReadModernSlot() end
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
    if modern() then
        FM:Status("Select an item from the ForeverMarket bag list on this client.")
        return
    end
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
function S:Snapshot()
    if not self.item then return nil,0 end
    local best,count=nil,0
    for _,r in ipairs(FM.Market.results or {}) do
        if r.key==self.item.key and r.unit>0 and (modern() or not FM.Market:IsMine(r.owner)) and time()-r.seen<300 then
            count=count+1;best=math.min(best or r.unit,r.unit)
        end
    end
    return best,count
end
function S:CheckMarket()
    if not self.item then FM:Status("Select an item from your bags first.");return end
    if not FM.Market:Ready() then return end
    if FM.Market.purchasePending or FM.Market.commodityPurchase then FM:Status("Finish the current purchase first.");return end

    if modern() then
        local A=FM.AuctionService
        if not A then FM:Status("Auction House service is unavailable.");return end
        local item=self.item
        local itemKey=item.itemKey
        if not itemKey and C_AuctionHouse.MakeItemKey then itemKey=C_AuctionHouse.MakeItemKey(item.itemID) end
        if not itemKey then FM:Status("Could not build an Auction House key for this item.");return end

        self.pendingCheck={key=item.key,name=item.name,item=item}
        FM:Status("Checking live offers for "..item.name.."...")
        A:SearchItem(itemKey,{
            owner="sell",commodity=item.isCommodity,
            sorts={{sortOrder=item.isCommodity and A.CommoditySort.sortOrder or A.ItemSort.sortOrder,reverseSort=false}},
            sellQuery=(not item.isCommodity and type(C_AuctionHouse.SendSellSearchQuery)=="function"),
            splitOwned=true,timeout=10,onCancel=function()
                if S.pendingCheck and S.pendingCheck.item==item then S.pendingCheck=nil end
            end,
        },function(key)
            if not S.pendingCheck or S.pendingCheck.item~=item or S.item~=item then return end
            S.pendingCheck=nil
            S:ApplyModernMarketPrice(key)
        end,function(err)
            if S.pendingCheck and S.pendingCheck.item==item then S.pendingCheck=nil end
            FM:Status("Live price check failed: "..tostring(err))
        end)
        return
    end

    if FM.Market.request or FM.Market.queued then FM:Status("Wait for the current market query to finish.");return end
    self.pendingCheck={key=self.item.key,name=self.item.name}
    FM:Status("Checking the market for "..self.item.name.."...")
    FM.Market:Search(self.item.name,0,true)
end

function S:ApplyModernMarketPrice(itemKey)
    if not self.item then return end
    local best,containsOwn,count
    count=0
    if self.item.isCommodity then
        local itemID=itemKey.itemID
        local n=tonumber(C_AuctionHouse.GetNumCommoditySearchResults(itemID)) or 0
        for i=1,n do
            local r=C_AuctionHouse.GetCommoditySearchResultInfo(itemID,i)
            if r and tonumber(r.unitPrice) and r.unitPrice>0 then
                count=count+(tonumber(r.quantity) or 0)
                if not best or r.unitPrice<best then
                    best=r.unitPrice
                    containsOwn=not not r.containsOwnerItem or (r.owners and r.owners[1]=="player")
                end
            end
        end
    else
        local n=tonumber(C_AuctionHouse.GetNumItemSearchResults(itemKey)) or 0
        for i=1,n do
            local r=C_AuctionHouse.GetItemSearchResultInfo(itemKey,i)
            local price=r and (tonumber(r.buyoutAmount) or tonumber(r.bidAmount))
            if price and price>0 then
                count=count+(tonumber(r.quantity) or 1)
                if not best or price<best then best=price;containsOwn=not not r.containsOwnerItem end
            end
        end
    end

    if not best then
        self:Suggest(true)
        FM:Status("No live competing price found. Using local history when available.")
        FM:Refresh()
        return
    end

    local floor=FM:ParseMoney(FM.UI.sellFloor:GetText()) or 0
    local unit
    if containsOwn then
        unit=normalizeModernPrice(math.max(1,floor,math.floor(best)))
        FM:Status("Your auction is already at the current lowest price. Matching "..FM:Money(unit).." / item.")
    else
        unit=normalizeModernPrice(math.max(1,floor,math.floor(best-(FM.DB.settings.undercut or 0))))
        FM:Status("Live market checked: lowest "..FM:Money(best).." / item. Suggested "..FM:Money(unit)..".")
    end
    FM.UI.sellPrice:SetText(FM:PlainMoney(unit))
    FM:Refresh()
end
function S:OnMarketResults()
    local pending=self.pendingCheck;if not pending then return end
    self.pendingCheck=nil
    if not self.item or self.item.key~=pending.key then FM:Status("Market check finished, but the selected sell item changed.");return end
    local best,count=self:Snapshot()
    if best then
        self:Suggest(true)
        FM:Status("Market checked: "..count.." competing auctions, lowest "..FM:Money(best).." / item. Suggested price applied.")
    else
        self:Suggest(true)
        FM:Status("Market checked: no competing buyout found on the loaded page. History is used when available.")
    end
    FM:Refresh()
end
function S:Suggest(silent)
    if not self.item then return end
    local best,source
    for _,r in ipairs(FM.Market.results) do
        if r.key==self.item.key and r.unit>0 and (modern() or not FM.Market:IsMine(r.owner)) and time()-r.seen<300 then best=math.min(best or r.unit,r.unit);source="current results" end
    end
    if not best then
        local h=FM:GetHistoryStats(self.item.key)
        if h then best=h.low;source="history ("..math.floor((time()-h.t)/60).." min ago)" end
    end
    if not best then if not silent then FM:Status("No price data. Click Check + suggest to run a live comparison.") end;return end
    local floor=FM:ParseMoney(FM.UI.sellFloor:GetText()) or 0
    local unit=math.max(1,floor,math.floor(best-FM.DB.settings.undercut))
    if modern() then unit=normalizeModernPrice(unit) end
    FM.UI.sellPrice:SetText(FM:PlainMoney(unit));FM:Status("Suggested from "..source.."; your minimum price has been applied.")
end
function S:Values()
    local U=FM.UI
    local stack=FM:Int(U.sellStack:GetText(),1,1000);local count=FM:Int(U.sellCount:GetText(),1,1000)
    local unit=FM:ParseMoney(U.sellPrice:GetText());local floor=FM:ParseMoney(U.sellFloor:GetText())
    if not self.item then return nil,"Select an item from your bags." end
    if modern() and self.item.resolvingCommodity then return nil,"Preparing item data..." end
    if not stack or not count or not unit or unit<1 or floor==nil then return nil,"Check quantities and price (e.g. 2g 50s or 25000 copper)." end
    if stack>self.item.maxStack or stack*count>self.item.total then return nil,"Not enough items, or the stack size is too large." end
    if unit<floor then return nil,"The price is below your configured minimum." end
    local duration=self.duration or FM.DB.settings.defaultDuration

    if modern() then
        unit=normalizeModernPrice(unit)
        floor=normalizeModernPrice(floor)
        if unit<floor then return nil,"The price is below your configured minimum." end
        local quantity=stack*count
        if C_AuctionHouse.GetAvailablePostCount and self.item.location then
            local ok,limit=pcall(C_AuctionHouse.GetAvailablePostCount,self.item.location)
            if ok and limit and quantity>limit then return nil,"This client allows posting at most "..tostring(limit).." of this item right now." end
        end
        local deposit=0
        if self.item.isCommodity and C_AuctionHouse.CalculateCommodityDeposit then
            local ok,v=pcall(C_AuctionHouse.CalculateCommodityDeposit,self.item.itemID,duration,quantity);if ok then deposit=v or 0 end
        elseif C_AuctionHouse.CalculateItemDeposit and self.item.location then
            local ok,v=pcall(C_AuctionHouse.CalculateItemDeposit,self.item.location,duration,quantity);if ok then deposit=v or 0 end
        end
        return {stack=stack,count=count,quantity=quantity,unit=unit,floor=floor,buyout=unit,bid=unit,duration=duration,deposit=deposit or 0}
    end

    local total=unit*stack;local max=MAXIMUM_BID_PRICE or 2147483647
    if total>max then return nil,"The price exceeds the client limit." end
    local deposit=GetAuctionDeposit and GetAuctionDeposit(duration,total,total,stack,count) or 0
    return {stack=stack,count=count,unit=unit,floor=floor,buyout=total,bid=total,duration=duration,deposit=deposit or 0}
end
function S:SavePreset()
    local v,err=self:Values();if not v then FM:Status(err);return end
    FM.Data.presets[self.item.key]=v;FM:Status("Saved this item's price, stack size, minimum and duration preset.")
end
function S:PostModernDirect(v,item)
    if FM.Debug then FM.Debug:SnapshotSell("DIRECT_POST_CLICK") end
    if not self:IsAHReadyForPost() then
        FM:Status("Auction House became busy. Wait for SERVER READY and click Post again.")
        FM:Refresh();return
    end
    if not item or self.item~=item then FM:Status("Select the item again.");return end
    local location=item.location
    if not location or not C_Item.DoesItemExist(location) then FM:Status("The selected item moved or no longer exists.");return end
    if C_AuctionHouse.IsSellItemValid and not C_AuctionHouse.IsSellItemValid(location,false) then
        FM:Status("This item cannot be posted on the Auction House.");return
    end
    local available=tonumber(C_AuctionHouse.GetAvailablePostCount and C_AuctionHouse.GetAvailablePostCount(location)) or 0
    if available<=0 then FM:Status("No postable quantity is available for this item.");return end
    if v.quantity>available then FM:Status("Only "..tostring(available).." of this item can be posted right now.");return end

    local commodity=item.isCommodity==true
    local key=item.itemKey
    if key and C_AuctionHouse.GetItemKeyInfo then
        local info=C_AuctionHouse.GetItemKeyInfo(key)
        if info and info.isCommodity~=nil then commodity=info.isCommodity==true end
    end
    item.isCommodity=commodity

    local slotInfo=C_Container.GetContainerItemInfo(item.bag,item.slot)
    local beforeCount=(slotInfo and slotInfo.stackCount) or item.total or 0
    local beforeItemID=slotInfo and slotInfo.itemID or item.itemID
    local params,needsNativeConfirm

    if FM.Debug then
        local securePath=(type(issecure)=="function" and issecure()) or nil
        local secureVar=nil
        if type(issecurevariable)=="function" then
            local ok,val=pcall(issecurevariable,C_AuctionHouse,commodity and "PostCommodity" or "PostItem")
            if ok then secureVar=val end
        end
        FM.Debug:Log("DIRECT_POST_CONTEXT","securePath="..tostring(securePath),"secureVar="..tostring(secureVar),"mouse="..tostring(type(GetMouseButtonClicked)=="function" and GetMouseButtonClicked() or nil))
    end

    if commodity then
        params={location,v.duration,v.quantity,v.unit}
        if FM.Debug then FM.Debug:Log("DIRECT_POST_COMMODITY","duration="..tostring(v.duration),"quantity="..tostring(v.quantity),"unit="..tostring(v.unit)) end
        needsNativeConfirm=C_AuctionHouse.PostCommodity(unpack(params))
        if FM.Debug then FM.Debug:Log("DIRECT_POST_RETURN","commodity=true","needsNativeConfirm="..tostring(needsNativeConfirm)) end
        if needsNativeConfirm and AuctionHouseFrame and AuctionHouseFrame.CommoditiesSellFrame and AuctionHouseFrame.CommoditiesSellFrame.CachePendingPost then
            AuctionHouseFrame.CommoditiesSellFrame:CachePendingPost(unpack(params))
        end
    else
        local bid=(v.bid and v.bid>0) and v.bid or nil
        local buyout=(v.unit and v.unit>0) and v.unit or nil
        params={location,v.duration,v.quantity,bid,buyout}
        if FM.Debug then FM.Debug:Log("DIRECT_POST_ITEM","duration="..tostring(v.duration),"quantity="..tostring(v.quantity),"bid="..tostring(bid),"buyout="..tostring(buyout)) end
        needsNativeConfirm=C_AuctionHouse.PostItem(unpack(params))
        if FM.Debug then FM.Debug:Log("DIRECT_POST_RETURN","commodity=false","needsNativeConfirm="..tostring(needsNativeConfirm)) end
        if needsNativeConfirm and AuctionHouseFrame and AuctionHouseFrame.ItemSellFrame and AuctionHouseFrame.ItemSellFrame.CachePendingPost then
            AuctionHouseFrame.ItemSellFrame:CachePendingPost(unpack(params))
        end
    end

    self.pendingPost={item=item,values=v,started=GetTime(),beforeCount=beforeCount,beforeItemID=beforeItemID,native=needsNativeConfirm==true}
    if needsNativeConfirm==true then
        if FM.Native and FM.Native.BeginNativePostConfirmation then FM.Native:BeginNativePostConfirmation("Sell") end
        return
    end
    FM:Status("Posting auction... waiting for server acceptance.")
    local pending=self.pendingPost
    FM:After(3.0,function()
        if S.pendingPost~=pending then return end
        local info=C_Container.GetContainerItemInfo(item.bag,item.slot)
        local afterCount=(info and info.stackCount) or 0
        local changed=(not info) or (pending.beforeItemID and info.itemID~=pending.beforeItemID) or afterCount<(pending.beforeCount or 0)
        if changed then
            S.pendingPost=nil;S:AfterModernPostSubmitted(item,v)
        else
            if FM.Debug then FM.Debug:SnapshotSell("DIRECT_POST_TIMEOUT") end
            S.pendingPost=nil
            FM:Status("No server acceptance received. Open /fmdebug and copy the log.")
            FM:Refresh()
        end
    end)
end

function S:Post()
    if not FM.Market:Ready() then return end
    self:ReadSlot()
    if modern() and not self:IsAHReadyForPost() then
        FM:Status("Auction House is busy. Wait for the server-ready indicator, then click Post again.")
        FM:Refresh();return
    end
    local v,err=self:Values();if not v then FM:Status(err);return end
    if FM.Debug then FM.Debug:SnapshotSell("POST_BUTTON") end
    local item=self.item
    if GetMoney()<v.deposit then FM:Status("You do not have enough gold for the deposit.");return end

    if modern() then
        return self:PostModernDirect(v,self.item)
    end

    local description
    if modern() then
        description=(item.link or item.name).."\nQuantity: "..v.quantity.." | Unit price: "..FM:Money(v.unit).."\nDeposit: "..FM:Money(v.deposit).." | Duration: "..({12,24,48})[v.duration].."h"
    else
        description=(item.link or item.name).."\n"..v.count.." stacks x "..v.stack.." items | Stack price: "..FM:Money(v.buyout).."\nDeposit: "..FM:Money(v.deposit).." | Duration: "..({12,24,48})[v.duration].."h"
    end

    FM.UI:Confirm("Post auction",item,description,function()
        if not FM.Market:Ready() then return end
        local nowValues=S:Values()
        if not nowValues or S.item~=item or nowValues.stack~=v.stack or nowValues.count~=v.count or nowValues.unit~=v.unit or nowValues.duration~=v.duration then
            FM:Status("The form changed. Review it and click Post again.")
            return
        end
        if GetMoney()<nowValues.deposit then FM:Status("You no longer have enough gold for the deposit.");return end

        if modern() then
            if FM.Debug then FM.Debug:SnapshotSell("CONFIRM_CLICK") end
            -- Match the native modern-AH posting contract as closely as possible:
            -- current bag ItemLocation, available-post limit, live commodity type,
            -- then a direct protected PostItem/PostCommodity call from this click.
            if not S:IsAHReadyForPost() then
                FM:Status("Auction House became busy. Wait for SERVER READY and click Post again.")
                FM:Refresh();return
            end

            local location=item.location
            if not location or not C_Item.DoesItemExist(location) then
                FM:Status("The selected item moved or no longer exists.");return
            end
            if C_AuctionHouse.IsSellItemValid and not C_AuctionHouse.IsSellItemValid(location,false) then
                FM:Status("This item cannot be posted on the Auction House.");return
            end

            local available=C_AuctionHouse.GetAvailablePostCount and C_AuctionHouse.GetAvailablePostCount(location) or item.total or 0
            available=tonumber(available) or 0
            if available<=0 then FM:Status("No postable quantity is available for this item.");return end
            if nowValues.quantity>available then
                FM:Status("Only "..tostring(available).." of this item can be posted right now.");return
            end

            local commodity=false
            if C_AuctionHouse.GetItemCommodityStatus and Enum and Enum.ItemCommodityStatus then
                local status=C_AuctionHouse.GetItemCommodityStatus(location)
                commodity=status==Enum.ItemCommodityStatus.Commodity
            else
                commodity=item.isCommodity==true
            end
            item.isCommodity=commodity
            item.location=location
            if FM.Debug then
                FM.Debug:Log("POST_ROUTE", "commodity="..tostring(commodity), "duration="..tostring(nowValues.duration), "quantity="..tostring(nowValues.quantity), "unit="..tostring(nowValues.unit), "available="..tostring(available))
            end

            local slotInfoBefore=C_Container.GetContainerItemInfo(item.bag,item.slot)
            local beforeCount=(slotInfoBefore and slotInfoBefore.stackCount) or item.total or 0
            local beforeItemID=slotInfoBefore and slotInfoBefore.itemID or item.itemID

            local params
            local needsNativeConfirm
            if commodity then
                params={location,nowValues.duration,nowValues.quantity,nowValues.unit}
                if FM.Debug then FM.Debug:Log("CALL_POST_COMMODITY", "duration="..tostring(nowValues.duration), "quantity="..tostring(nowValues.quantity), "unit="..tostring(nowValues.unit)) end
                needsNativeConfirm=C_AuctionHouse.PostCommodity(unpack(params))
                if FM.Debug then FM.Debug:Log("RETURN_POST_COMMODITY", "needsNativeConfirm="..tostring(needsNativeConfirm)) end
                if needsNativeConfirm and AuctionHouseFrame and AuctionHouseFrame.CommoditiesSellFrame and AuctionHouseFrame.CommoditiesSellFrame.CachePendingPost then
                    if FM.Debug then FM.Debug:Log("CACHE_PENDING_COMMODITY", "calling native CachePendingPost") end
                    AuctionHouseFrame.CommoditiesSellFrame:CachePendingPost(unpack(params))
                end
            else
                params={location,nowValues.duration,nowValues.quantity,nil,nowValues.unit}
                if FM.Debug then FM.Debug:Log("CALL_POST_ITEM", "duration="..tostring(nowValues.duration), "quantity="..tostring(nowValues.quantity), "bid=nil", "buyout="..tostring(nowValues.unit)) end
                needsNativeConfirm=C_AuctionHouse.PostItem(unpack(params))
                if FM.Debug then FM.Debug:Log("RETURN_POST_ITEM", "needsNativeConfirm="..tostring(needsNativeConfirm)) end
                if needsNativeConfirm and AuctionHouseFrame and AuctionHouseFrame.ItemSellFrame and AuctionHouseFrame.ItemSellFrame.CachePendingPost then
                    if FM.Debug then FM.Debug:Log("CACHE_PENDING_ITEM", "calling native CachePendingPost") end
                    AuctionHouseFrame.ItemSellFrame:CachePendingPost(unpack(params))
                end
            end

            -- Do not report success merely because the Lua call returned. Modern
            -- AH posting can fail silently. Confirm acceptance by watching the
            -- selected bag slot/quantity for a short period.
            S.pendingPost={item=item,values=nowValues,started=GetTime(),beforeCount=beforeCount,beforeItemID=beforeItemID,native=needsNativeConfirm==true}

            if needsNativeConfirm==true then
                if FM.Native and FM.Native.BeginNativePostConfirmation then
                    FM.Native:BeginNativePostConfirmation("Sell")
                else
                    FM:Status("Confirm the auction in the Blizzard Auction House window.")
                end
            else
                FM:Status("Posting auction... waiting for server acceptance.")
                local pending=S.pendingPost
                FM:After(2.0,function()
                    if S.pendingPost~=pending then return end
                    local info=C_Container.GetContainerItemInfo(item.bag,item.slot)
                    local afterCount=(info and info.stackCount) or 0
                    local changed=(not info) or (pending.beforeItemID and info.itemID~=pending.beforeItemID) or afterCount < (pending.beforeCount or 0)
                    if changed then
                        S.pendingPost=nil
                        S:AfterModernPostSubmitted(item,nowValues)
                    else
                        if FM.Debug then FM.Debug:SnapshotSell("POST_TIMEOUT_NO_BAG_CHANGE") end
                        S.pendingPost=nil
                        FM:Status("The server did not accept the auction. Recheck price/quantity and try again when SERVER READY.")
                        FM:Refresh()
                    end
                end)
            end
            return
        end

        local name,_,_,_,_,_,_,_,total,id=GetAuctionSellItemInfo()
        if name~=item.name or (id and item.itemID and id~=item.itemID) or (total and total<v.stack*v.count) then FM:Status("The item changed.");return end
        local ok,errorText
        if PostAuction and AuctionsCreateAuctionButton and AuctionsCreateAuctionButton.StartPost then
            ok,errorText=pcall(AuctionsCreateAuctionButton.StartPost,AuctionsCreateAuctionButton,v.bid,v.buyout,v.duration,v.stack,v.count,false)
        elseif StartAuction then ok,errorText=pcall(StartAuction,v.bid,v.buyout,v.duration,v.stack,v.count)
        else ok=false;errorText="Posting is not supported in this client." end
        if not ok then FM.Market:FailTransaction(errorText) else FM:Status("Auction submitted. Check for an additional Blizzard confirmation.") end
    end)
end
FM:On("NEW_AUCTION_UPDATE",function() S:ReadSlot() end)
FM:On("BAG_UPDATE_DELAYED",function()
    if modern() and S.pendingPost and S.pendingPost.item then
        local p=S.pendingPost
        local it=p.item
        local info=C_Container.GetContainerItemInfo(it.bag,it.slot)
        local afterCount=(info and info.stackCount) or 0
        local changed=(not info) or (p.beforeItemID and info.itemID~=p.beforeItemID) or afterCount < (p.beforeCount or 0)
        if changed then
            S.pendingPost=nil
            S:AfterModernPostSubmitted(it,p.values)
            if FM.Native and FM.Native.FinishNativePostConfirmation then FM.Native:FinishNativePostConfirmation() end
            return
        end
    end
    if FM.Market.open and S.item then FM:After(.05,function() S:ReadSlot() end) end
end)
FM:On("AUCTION_HOUSE_CLOSED",function() S.item=nil;S.cursorLink=nil;S.pendingPost=nil end)

FM:On("AUCTION_HOUSE_POST_ERROR",function(_,msg)
    if not modern() then return end
    if S.pendingPost then S.pendingPost=nil end
    FM:Status("Posting failed: "..tostring(msg or "Auction House rejected the post."))
end)
FM:On("AUCTION_MULTISELL_FAILURE",function()
    if not modern() then return end
    if S.pendingPost then S.pendingPost=nil end
    FM:Status("Posting failed before all selected items could be listed.")
end)
