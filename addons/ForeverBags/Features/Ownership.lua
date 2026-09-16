local _, FB = ...
FB.Ownership = FB.Ownership or {}
local O = FB.Ownership

function O:Get(itemID)
    if not FB.db or not itemID then return 0, {} end
    local key = FB:ItemKey(itemID)
    local total, owners = 0, {}
    for charKey, char in pairs(FB.db.characters or {}) do
        local subtotal = 0
        for _, list in ipairs({char.inventory or {}, char.bank or {}}) do
            for i = 1, #list do
                if FB:ItemKey(list[i].itemID) == key then subtotal = subtotal + (tonumber(list[i].count) or 1) end
            end
        end
        if subtotal > 0 then owners[charKey] = subtotal; total = total + subtotal end
    end
    return total, owners
end

function O:AddTooltip(tooltip, item)
    if not item or not item.itemID then return end
    local total, owners = self:Get(item.itemID)
    if total > 0 then
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(FB.L.OWNED or "Owned", tostring(total), 0.35,0.85,1, 1,0.85,0.25)
        local names = {}
        for name in pairs(owners) do table.insert(names, name) end
        table.sort(names)
        for i = 1, #names do
            tooltip:AddDoubleLine(names[i], tostring(owners[names[i]]), 0.72,0.72,0.72, 0.9,0.9,0.9)
        end
    end
    local tag = FB:GetTag(item.itemID)
    if tag then tooltip:AddDoubleLine("Tag", string.upper(tag), 0.4,0.8,1, 1,0.82,0.25) end
    local d = FB.db.discoveries and FB.db.discoveries[FB:ItemKey(item.itemID)]
    if d then
        tooltip:AddLine(" ")
        if d.firstSeen then tooltip:AddDoubleLine(FB.L.FIRST_SEEN or "First seen", date("%Y-%m-%d %H:%M", d.firstSeen), 0.55,0.8,1, 0.85,0.85,0.85) end
        if d.zone then tooltip:AddDoubleLine("Zone", d.zone, 0.55,0.8,1, 0.85,0.85,0.85) end
        if d.source then tooltip:AddDoubleLine("Source", d.source, 0.55,0.8,1, 0.85,0.85,0.85) end
    end
    tooltip:AddLine(" ")
    tooltip:AddLine(FB.L.TOOLTIP_MIDDLE or "Middle-click: toggle favorite", 0.45,0.75,0.95)
    tooltip:AddLine(FB.L.TOOLTIP_ALT_RIGHT or "Alt + Right-click: cycle tag", 0.45,0.75,0.95)
end
