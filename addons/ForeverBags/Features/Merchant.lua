local _, FB = ...
FB.Merchant = FB.Merchant or {}
local M = FB.Merchant

function M:CollectJunk(includeTagged)
    local queue, total = {}, 0
    local items = FB.Data:ScanBags(FB.API:GetBagRange(), "bags")
    for i = 1, #items do
        local it = items[i]
        local tag = FB:GetTag(it.itemID)
        local junk = it.quality == 0 and not it.noValue
        local tagged = includeTagged and tag == "sell"
        if (junk or tagged) and not FB:IsFavorite(it.itemID) and tag ~= "keep" and it.sellPrice and it.sellPrice > 0 then
            table.insert(queue, {bag=it.bag, slot=it.slot, value=it.sellPrice * (it.count or 1)})
            total = total + it.sellPrice * (it.count or 1)
        end
    end
    return queue, total
end

function M:GetJunkValue()
    local _, total = self:CollectJunk(false)
    return total
end

function M:SellJunk(includeTagged)
    if not FB.state.merchantOpen then
        FB:Print("Open a merchant first.")
        return
    end
    if self.selling then return end
    local queue, estimated = self:CollectJunk(includeTagged)
    if #queue == 0 then
        FB:Print("No sellable junk found.")
        return
    end
    self.selling = true
    local before = GetMoney and GetMoney() or 0
    local index = 1
    local ticker
    ticker = C_Timer.NewTicker(0.12, function()
        local entry = queue[index]
        if not entry then
            ticker:Cancel(); M.selling = false
            C_Timer.After(0.25, function()
                local after = GetMoney and GetMoney() or before
                FB:Print((FB.L.SOLD or "Sold junk for") .. " " .. FB:FormatMoney(math.max(0, after - before)) .. ".")
                FB:Fire("DATA_CHANGED")
            end)
            return
        end
        local info = FB.API:GetItemInfo(entry.bag, entry.slot)
        if info and not info.locked then pcall(FB.API.UseItem, FB.API, entry.bag, entry.slot) end
        index = index + 1
    end)
end
