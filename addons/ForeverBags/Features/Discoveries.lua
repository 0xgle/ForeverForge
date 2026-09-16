local _, FB = ...
FB.Discoveries = FB.Discoveries or {}
local D = FB.Discoveries

function D:Observe(item)
    if not FB.db or not item or not item.itemID then return end
    local key = FB:ItemKey(item.itemID)
    local now = FB:Now()
    local rec = FB.db.discoveries[key]
    if not rec then
        local source
        if FB.state.lastLootSource and (now - (FB.state.lastLootAt or 0)) <= 5 then source = FB.state.lastLootSource end
        rec = {
            itemID = item.itemID,
            firstSeen = now,
            lastSeen = now,
            zone = (GetZoneText and GetZoneText()) or nil,
            source = source,
        }
        FB.db.discoveries[key] = rec
        FB:Fire("DISCOVERY_NEW", rec)
    end
    rec.lastSeen = now
    rec.link = item.link or rec.link
    rec.icon = item.icon or rec.icon
    rec.name = item.name or rec.name
    rec.quality = item.quality or rec.quality
    rec.lastCount = item.count or rec.lastCount
end
