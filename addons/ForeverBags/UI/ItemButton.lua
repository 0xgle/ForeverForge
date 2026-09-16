local _, FB = ...
FB.ItemButton = FB.ItemButton or {}
local IB = FB.ItemButton

local function NewBackdropButton(parent)
    return CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
end

function IB:Create(parent)
    local b = NewBackdropButton(parent)
    b:SetSize(FB.settings and FB.settings.iconSize or 42, FB.settings and FB.settings.iconSize or 42)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=2})
    b:SetBackdropColor(0.025,0.035,0.045,1)
    b:SetBackdropBorderColor(0.4,0.4,0.4,1)

    -- IMPORTANT:
    -- slot_frame.tga is a full slot artwork with a non-transparent center.
    -- It must live BELOW the actual item icon, otherwise it covers the icon completely.
    b.frameArt = b:CreateTexture(nil, "BACKGROUND", nil, 1)
    b.frameArt:SetAllPoints()
    b.frameArt:SetTexture(FB.Media:Texture("slot_frame"))
    b.frameArt:SetAlpha(0.96)

    b.icon = b:CreateTexture(nil, "ARTWORK", nil, 1)
    b.icon:SetPoint("TOPLEFT", 7, -7)
    b.icon:SetPoint("BOTTOMRIGHT", -7, 7)
    b.icon:SetTexCoord(0.07,0.93,0.07,0.93)

    b.hover = b:CreateTexture(nil, "OVERLAY")
    b.hover:SetAllPoints()
    b.hover:SetTexture(FB.Media:Texture("slot_hover"))
    b.hover:SetAlpha(0)

    b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.count:SetPoint("BOTTOMRIGHT", -4, 4)
    b.count:SetJustifyH("RIGHT")
    b.count:SetTextColor(1,1,1)

    b.itemLevel = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.itemLevel:SetPoint("TOPLEFT", 4, -3)
    b.itemLevel:SetTextColor(1,0.82,0.3)

    b.badge = b:CreateTexture(nil, "OVERLAY")
    b.badge:SetSize(18,18)
    b.badge:SetPoint("TOPRIGHT", 4, 4)
    b.badge:Hide()

    b.favorite = b:CreateTexture(nil, "OVERLAY")
    b.favorite:SetSize(16,16)
    b.favorite:SetPoint("BOTTOMLEFT", -2, -1)
    b.favorite:SetTexture(FB.Media:Icon("favorite"))
    b.favorite:Hide()

    b.newGlow = b:CreateTexture(nil, "BACKGROUND")
    b.newGlow:SetPoint("TOPLEFT", -5, 5)
    b.newGlow:SetPoint("BOTTOMRIGHT", 5, -5)
    b.newGlow:SetTexture(FB.Media:Icon("selected"))
    b.newGlow:SetBlendMode("ADD")
    b.newGlow:SetAlpha(0.75)
    b.newGlow:Hide()

    b:SetScript("OnEnter", function(self)
        self.hover:SetAlpha(0.85)
        IB:OnEnter(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hover:SetAlpha(0)
        GameTooltip:Hide()
    end)
    b:SetScript("OnMouseUp", function(self, button) IB:OnClick(self, button) end)
    b:SetScript("OnMouseDown", function(self)
        if self.item and self.item.live then
            FB.API:RemoveNewItem(self.item.bag, self.item.slot)
        end
    end)
    b:RegisterForClicks("AnyUp")
    return b
end

function IB:SetItem(button, item)
    button.item = item
    button.icon:SetTexture(item.icon or 134400)
    button.count:SetText((item.count and item.count > 1) and tostring(item.count) or "")
    button.itemLevel:SetText((item.itemLevel and item.itemLevel > 1 and item.category == "equipment") and tostring(item.itemLevel) or "")
    local c = FB.Media.quality[item.quality or 1] or FB.Media.quality[1]
    button:SetBackdropBorderColor(c[1],c[2],c[3],1)
    button.favorite:SetShown(item.favorite and true or false)
    button.newGlow:SetShown(item.isNew and true or false)
    button.badge:Hide()
    if item.tag == "keep" then
        button.badge:SetTexture(FB.Media:Icon("keep"))
        button.badge:Show()
    elseif item.tag == "sell" then
        button.badge:SetTexture(FB.Media:Icon("sell"))
        button.badge:Show()
    elseif item.tag == "bank" then
        button.badge:SetTexture(FB.Media:Icon("bank_badge"))
        button.badge:Show()
    end
    button.icon:SetDesaturated(item.locked and true or false)
    button:SetAlpha(item.locked and 0.6 or 1)
end

function IB:OnEnter(button)
    local item = button.item
    if not item then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local shown = false
    if item.live and item.bag ~= nil and item.slot and GameTooltip.SetBagItem then
        local ok = pcall(GameTooltip.SetBagItem, GameTooltip, item.bag, item.slot)
        shown = ok
    end
    if not shown and item.link then pcall(GameTooltip.SetHyperlink, GameTooltip, item.link) end
    if not item.link then GameTooltip:AddLine(item.name or ("Item "..tostring(item.itemID or "?"))) end
    if FB.Ownership then FB.Ownership:AddTooltip(GameTooltip, item) end
    GameTooltip:Show()
end

function IB:OnClick(button, mouseButton)
    local item = button.item
    if not item then return end
    if mouseButton == "MiddleButton" then
        FB:ToggleFavorite(item.itemID)
        return
    end
    if mouseButton == "RightButton" and IsAltKeyDown() then
        local tag = FB:CycleTag(item.itemID)
        FB:Print((item.name or "Item") .. " → " .. (tag or "none"))
        return
    end
    if not item.live then return end
    if IsShiftKeyDown() and item.link and HandleModifiedItemClick then
        if HandleModifiedItemClick(item.link) then return end
    end
    if mouseButton == "RightButton" then
        FB.API:UseItem(item.bag, item.slot)
    elseif mouseButton == "LeftButton" then
        FB.API:PickupItem(item.bag, item.slot)
    end
end
