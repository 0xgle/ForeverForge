local _,F=...
local T={}
F.T=T
T.gold={.83,.68,.42}; T.teal={.34,.85,.77}; T.text={.89,.9,.86}; T.muted={.58,.67,.67}
function T:Panel(parent,w,h,x,y,color)
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    f:SetSize(w,h); f:SetPoint("TOPLEFT",parent,"TOPLEFT",x or 0,-(y or 0))
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(unpack(color or {.035,.065,.071,.98})); f:SetBackdropBorderColor(.22,.28,.27,1)
    return f
end
function T:Text(parent,text,size,x,y,width,color,font)
    local s=parent:CreateFontString(nil,"OVERLAY")
    s:SetFont(font or STANDARD_TEXT_FONT,size or 13,"")
    s:SetPoint("TOPLEFT",parent,"TOPLEFT",x or 0,-(y or 0))
    s:SetTextColor(unpack(color or self.text)); s:SetJustifyH("LEFT"); s:SetJustifyV("TOP")
    if width then s:SetWidth(width) end
    s:SetText(text or ""); return s
end
function T:Icon(parent,index,size,x,y)
    local t=parent:CreateTexture(nil,"ARTWORK")
    t:SetTexture(F.media.."Icons.tga"); t:SetSize(size,size)
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x or 0,-(y or 0))
    index=(index or 1)-1; local col,row=index%4,math.floor(index/4)
    t:SetTexCoord(col/4+.008,(col+1)/4-.008,row/4+.008,(row+1)/4-.008)
    return t
end
function T:Tip(f,title,body)
    f:HookScript("OnEnter",function()
        GameTooltip:SetOwner(f,"ANCHOR_RIGHT"); GameTooltip:SetText(title,unpack(T.gold))
        GameTooltip:AddLine(body,.8,.87,.85,true); GameTooltip:Show()
    end)
    f:HookScript("OnLeave",function() GameTooltip:Hide() end)
end
function T:Button(parent,text,w,h,x,y,fn,primary)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetSize(w,h or 30); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x or 0,-(y or 0))
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    local function paint(hover)
        if primary then
            b:SetBackdropColor(hover and .13 or .07,hover and .30 or .22,.22,1)
            b:SetBackdropBorderColor(.3,.62,.54,1)
        else
            b:SetBackdropColor(hover and .13 or .06,hover and .17 or .10,hover and .17 or .11,1)
            b:SetBackdropBorderColor(hover and .63 or .27,hover and .53 or .32,.29,1)
        end
    end
    paint(false)
    b.label=b:CreateFontString(nil,"OVERLAY"); b.label:SetFont(STANDARD_TEXT_FONT,12,"")
    b.label:SetPoint("CENTER"); b.label:SetWidth(w-10); b.label:SetTextColor(unpack(primary and T.teal or T.text)); b.label:SetText(text)
    b:SetScript("OnEnter",function() paint(true) end); b:SetScript("OnLeave",function() paint(false) end)
    b:SetScript("OnClick",fn); return b
end

function T:Check(parent,text,w,h,x,y,fn)
    local b=CreateFrame("Button",nil,parent)
    b:SetSize(w or 92,h or 26); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x or 0,-(y or 0))
    local box=self:Panel(b,20,20,0,3,{.02,.045,.049,1})
    box:ClearAllPoints(); box:SetPoint("LEFT",b,"LEFT",0,0)
    local mark=box:CreateTexture(nil,"OVERLAY")
    mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    mark:SetSize(26,26); mark:SetPoint("CENTER",box,"CENTER",0,0)
    local label=b:CreateFontString(nil,"OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT,11,""); label:SetPoint("LEFT",box,"RIGHT",6,0)
    label:SetTextColor(unpack(self.text)); label:SetText(text or "")
    b.box=box; b.mark=mark; b.label=label; b.value=false
    function b:SetValue(v)
        self.value=not not v
        self.mark:SetShown(self.value)
        if self.value then self.box:SetBackdropBorderColor(unpack(T.teal)) else self.box:SetBackdropBorderColor(.27,.32,.29,1) end
    end
    function b:GetValue() return self.value end
    b:SetScript("OnEnter",function() box:SetBackdropBorderColor(unpack(T.gold)) end)
    b:SetScript("OnLeave",function()
        if b.value then box:SetBackdropBorderColor(unpack(T.teal)) else box:SetBackdropBorderColor(.27,.32,.29,1) end
    end)
    b:SetScript("OnClick",function()
        b:SetValue(not b.value)
        if fn then fn(b.value) end
    end)
    b:SetValue(false)
    return b
end

function T:Edit(parent,w,h,x,y,multi)
    local bg=self:Panel(parent,w,h,x,y,{.02,.045,.049,1})
    local e=CreateFrame("EditBox",nil,bg)
    e:SetPoint("TOPLEFT",8,-8); e:SetPoint("BOTTOMRIGHT",-8,8)
    e:SetFontObject(ChatFontNormal); e:SetAutoFocus(false); e:SetMultiLine(not not multi)
    e:SetMaxLetters(multi and 64000 or 80)
    e:SetScript("OnEscapePressed",function(s) s:ClearFocus() end)
    return e,bg
end
