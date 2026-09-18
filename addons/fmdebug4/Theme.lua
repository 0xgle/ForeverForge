local _,FM=...
local T={gold={.83,.68,.42},teal={.39,.84,.76},text={.89,.91,.88},muted={.58,.67,.68}}
FM.T=T
function T:Panel(parent,w,h,x,y,color)
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    f:SetSize(w,h); f:SetPoint("TOPLEFT",x or 0,-(y or 0))
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(unpack(color or {.025,.045,.051,.94})); f:SetBackdropBorderColor(.20,.27,.28,1)
    return f
end
function T:Text(p,text,size,x,y,w,color)
    local t=p:CreateFontString(nil,"OVERLAY")
    t:SetFont(STANDARD_TEXT_FONT,size or 12,""); t:SetPoint("TOPLEFT",x or 0,-(y or 0))
    t:SetTextColor(unpack(color or self.text)); t:SetJustifyH("LEFT"); t:SetJustifyV("TOP")
    if w then t:SetWidth(w); t:SetWordWrap(false) end
    t:SetText(text or ""); return t
end
function T:Icon(p,name,size,x,y)
    local t=p:CreateTexture(nil,"ARTWORK");t:SetTexture(FM.media.."Icons\\"..name..".tga")
    t:SetSize(size,size);t:SetPoint("TOPLEFT",x,-y);return t
end
function T:Button(p,label,w,h,x,y,fn,primary)
    local b=CreateFrame("Button",nil,p,"BackdropTemplate")
    b:SetSize(w,h); b:SetPoint("TOPLEFT",x,-y)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b.label=self:Text(b,label,12,0,0,w-12,primary and self.teal or self.text)
    b.label:ClearAllPoints();b.label:SetPoint("CENTER");b.label:SetJustifyH("CENTER")
    function b:Paint(hover)
        local a=self.active or primary
        self:SetBackdropColor(hover and .10 or .045,a and .16 or .075,a and .16 or .085,1)
        self:SetBackdropBorderColor(a and .44 or .25,a and .56 or .31,a and .45 or .30,1)
    end
    b:SetScript("OnEnter",function(s) s:Paint(true) end);b:SetScript("OnLeave",function(s) s:Paint(false) end)
    b:SetScript("OnEnable",function(s) s:SetAlpha(1) end); b:SetScript("OnDisable",function(s) s:SetAlpha(.4) end)
    b:SetScript("OnClick",fn);b:Paint();return b
end
function T:Edit(p,w,h,x,y,text)
    local e=CreateFrame("EditBox",nil,p,"BackdropTemplate")
    e:SetSize(w,h);e:SetPoint("TOPLEFT",x,-y);e:SetAutoFocus(false);e:SetFontObject(ChatFontNormal)
    e:SetTextInsets(9,9,0,0);e:SetMaxLetters(100)
    e:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    e:SetBackdropColor(.02,.035,.041,1);e:SetBackdropBorderColor(.25,.33,.34,1)
    e:SetText(text or "");e:SetScript("OnEscapePressed",function(s) s:ClearFocus() end);return e
end
function T:Tip(f,title,body)
    f:HookScript("OnEnter",function() GameTooltip:SetOwner(f,"ANCHOR_RIGHT");GameTooltip:SetText(title);GameTooltip:AddLine(body,.75,.84,.82,true);GameTooltip:Show() end)
    f:HookScript("OnLeave",function() GameTooltip:Hide() end)
end
