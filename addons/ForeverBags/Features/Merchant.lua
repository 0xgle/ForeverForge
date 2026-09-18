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
            queue[#queue + 1] = {
                bag = it.bag,
                slot = it.slot,
                value = it.sellPrice * (it.count or 1),
                junk = junk,
                tagged = tagged,
            }
            total = total + it.sellPrice * (it.count or 1)
        end
    end
    return queue, total
end

function M:GetJunkValue()
    local _, total = self:CollectJunk(false)
    return total
end

local function finishSale(before)
    C_Timer.After(0.35, function()
        local after = GetMoney and GetMoney() or before
        FB:Print((FB.L.SOLD or "Sold junk for") .. " " .. FB:FormatMoney(math.max(0, after - before)) .. ".")
        FB:Fire("DATA_CHANGED")
    end)
end

function M:SellJunk(includeTagged)
    if not FB.state.merchantOpen then
        FB:Print("Open a merchant first.")
        return
    end
    if self.selling then return end

    local queue = self:CollectJunk(includeTagged)
    if #queue == 0 then
        FB:Print("No sellable junk found.")
        return
    end

    -- Direct UseContainerItem is protected on current WoW branches. Use only the
    -- dedicated Blizzard merchant action; never fall back to insecure item use.
    if not (C_MerchantFrame and C_MerchantFrame.SellAllJunkItems) then
        FB:Print("Use the merchant's native Sell Junk button on this client.")
        return
    end

    self.selling = true
    local before = GetMoney and GetMoney() or 0
    local ok = pcall(C_MerchantFrame.SellAllJunkItems)
    self.selling = false

    if not ok then
        FB:Print("The client blocked junk selling. Use the merchant's native Sell Junk button.")
        return
    end

    if includeTagged then
        FB:Print("Safety: only native junk is auto-sold; custom Sell tags are never force-used.")
    end
    finishSale(before)
end
