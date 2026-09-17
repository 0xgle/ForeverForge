local ADDON, FG = ...
local T = {}; FG.Theme = T
local C = FG.C
T.font = STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF'
function T.Skin(f, bg, border)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 f:SetBackdropColor(unpack(bg or C.panel)); f:SetBackdropBorderColor(unpack(border or C.border))
end
function T.Box(parent,x,y,w,h,material)
 local f=CreateFrame('Frame',nil,parent,'BackdropTemplate');f:SetSize(w,h);f:SetPoint('TOPLEFT',x,-y);T.Skin(f)
 if material then local a=f:CreateTexture(nil,'BACKGROUND',nil,1);a:SetTexture(FG.MEDIA..'Material.tga');a:SetPoint('TOPLEFT',1,-1);a:SetPoint('BOTTOMRIGHT',-1,1);a:SetAlpha(.55) end
 return f
end
function T.Text(p,text,x,y,w,h,size,color)
 local f=p:CreateFontString(nil,'OVERLAY');f:SetFont(T.font,size or 12,'');f:SetTextColor(unpack(color or C.text));f:SetPoint('TOPLEFT',x,-y);f:SetSize(w,h or 20);f:SetJustifyH('LEFT');f:SetJustifyV('MIDDLE');f:SetWordWrap(false);f:SetText(text or '');return f
end
function T.Paragraph(p,text,x,y,w,h,size,color)
 local f=T.Text(p,text,x,y,w,h,size,color);f:SetWordWrap(true);f:SetJustifyV('TOP');f:SetSpacing(4);return f
end
function T.Art(p,name,x,y,w,h,layer)
 local a=p:CreateTexture(nil,layer or 'ARTWORK');a:SetTexture(FG.MEDIA..name..'.tga');a:SetPoint('TOPLEFT',x,-y);a:SetSize(w,h or w);return a
end
function T.Rule(p,x,y,w,color)
 local a=p:CreateTexture(nil,'ARTWORK');a:SetColorTexture(unpack(color or C.border));a:SetPoint('TOPLEFT',x,-y);a:SetSize(w,1);return a
end
function T.Button(p,text,x,y,w,h,fn,primary)
 local b=CreateFrame('Button',nil,p,'BackdropTemplate');b:SetPoint('TOPLEFT',x,-y);b:SetSize(w,h or 32)
 b.primary=primary; b.label=T.Text(b,text,8,0,w-16,h or 32,12,primary and C.bg or C.text);b.label:SetJustifyH('CENTER')
 function b:Refresh(active)
  if active~=nil then self.active=active end
  T.Skin(self,(self.primary or self.active) and C.gold or C.panel2,(self.primary or self.active) and C.gold or C.border)
  self.label:SetTextColor(unpack((self.primary or self.active) and C.bg or C.text))
 end
 b:Refresh(false);b:SetScript('OnClick',fn)
 b:SetScript('OnEnter',function(s)s:SetBackdropBorderColor(unpack(C.cyan)) end)
 b:SetScript('OnLeave',function(s)s:Refresh() end)
 return b
end
function T.Toggle(p,text,key,x,y,w)
 local b=CreateFrame('Button',nil,p);b:SetPoint('TOPLEFT',x,-y);b:SetSize(w or 220,28)
 local box=T.Box(b,0,5,18,18);local mark=T.Text(box,'',1,0,16,18,13,C.gold);mark:SetJustifyH('CENTER')
 b.label=T.Text(b,text,28,0,(w or 220)-28,28,12,C.text)
 function b:Refresh()mark:SetText(FG.db.profile[key] and '+' or '');box:SetBackdropBorderColor(unpack(FG.db.profile[key] and C.gold or C.border)) end
 b:SetScript('OnClick',function()
  FG.db.profile[key]=not FG.db.profile[key];b:Refresh();FG:InvalidateCaches()
  if key=='showFieldBar' then FG:ToggleFieldBar(FG.db.profile[key]) end
  if key=='minimapButton' and FG.minimapButton then FG.minimapButton:SetShown(FG.db.profile[key]) end
  if key=='routeLoop' and FG.db.route then FG.db.route.loop=FG.db.profile[key] end
  if FG.RefreshPins then FG:RefreshPins() end
 end)
 b:Refresh();return b
end
function T.Edit(p,x,y,w,placeholder,changed)
 local box=T.Box(p,x,y,w,34);local e=CreateFrame('EditBox',nil,box)
 e:SetPoint('TOPLEFT',10,-1);e:SetPoint('BOTTOMRIGHT',-10,1);e:SetFont(T.font,12,'');e:SetTextColor(unpack(C.text));e:SetAutoFocus(false);e:SetMaxLetters(120)
 local hint=T.Text(box,placeholder,10,0,w-20,34,12,C.muted)
 local function update()hint:SetShown(e:GetText()=='' and not e:HasFocus()) end
 e:SetScript('OnEditFocusGained',update);e:SetScript('OnEditFocusLost',update)
 e:SetScript('OnTextChanged',function(self,user)update();if user and changed then changed(self:GetText()) end end)
 e:SetScript('OnEscapePressed',function(s)s:ClearFocus()end);e:SetScript('OnEnterPressed',function(s)s:ClearFocus();if changed then changed(s:GetText()) end end)
 return e
end
function T.List(p,x,y,w,h,rowHeight)
 local s=CreateFrame('ScrollFrame',nil,p);s:SetPoint('TOPLEFT',x,-y);s:SetSize(w,h);s:SetClipsChildren(true)
 local child=CreateFrame('Frame',nil,s);child:SetSize(w,h);s:SetScrollChild(child);s.child=child;s.rows={};s.offset=0;s.rowHeight=rowHeight or 44
 s:EnableMouseWheel(true)
 s:SetScript('OnMouseWheel',function(self,d)self.offset=math.max(0,math.min(math.max(0,self.child:GetHeight()-h),self.offset-d*self.rowHeight));self:SetVerticalScroll(self.offset)end)
 function s:Clear()for _,r in ipairs(self.rows)do r:Hide()end end
 function s:Row(i)
  local r=self.rows[i]
  if not r then
   r=CreateFrame('Button',nil,self.child,'BackdropTemplate');r:SetSize(w,self.rowHeight-3);T.Skin(r,C.panel2)
   r.icon=T.Art(r,'Icon_Route',8,6,30,30);r.title=T.Text(r,'',48,3,w-138,20,12,C.text);r.meta=T.Text(r,'',48,23,w-138,14,10,C.muted)
   r.count=T.Text(r,'',w-88,0,78,self.rowHeight-3,12,C.gold);r.count:SetJustifyH('RIGHT')
   r:SetScript('OnEnter',function(self)self:SetBackdropBorderColor(unpack(C.cyan));if self.fullName then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:AddLine(self.fullName,1,1,1,true);GameTooltip:Show()end end)
   r:SetScript('OnLeave',function(self)self:SetBackdropBorderColor(unpack(C.border));GameTooltip:Hide()end)
   self.rows[i]=r
  end
  r:ClearAllPoints();r:SetPoint('TOPLEFT',0,-(i-1)*self.rowHeight);r:Show();return r
 end
 function s:Finish(n)
  self.child:SetHeight(math.max(h,n*self.rowHeight));self.offset=math.min(self.offset,math.max(0,self.child:GetHeight()-h));self:SetVerticalScroll(self.offset)
 end
 return s
end
function T.Fit(f,w,h,preference)
 local fit=math.min((UIParent:GetWidth()-32)/w,(UIParent:GetHeight()-32)/h)
 f:SetScale(math.min(preference or 1,fit));f:SetClampedToScreen(true)
end
function T.Movable(f,key,handle)
 f:SetMovable(true);f:SetClampedToScreen(true);handle=handle or f;handle:EnableMouse(true);handle:RegisterForDrag('LeftButton')
 handle:SetScript('OnDragStart',function()f:StartMoving()end)
 handle:SetScript('OnDragStop',function()
  f:StopMovingOrSizing();local point,_,relative,x,y=f:GetPoint(1);FG.db.profile[key]={point=point,relative=relative,x=x,y=y}
 end)
 local pos=FG.db.profile[key]
 if type(pos)=='table' and pos.point and pos.relative and type(pos.x)=='number' and type(pos.y)=='number' then f:ClearAllPoints();f:SetPoint(pos.point,UIParent,pos.relative,pos.x,pos.y)end
end
function FG:IconFor(kind)
 return self.MEDIA..(kind=='herbalism' and 'Icon_Herb' or kind=='skinning' and 'Icon_Skin' or kind=='mining' and 'Icon_Mining' or 'Icon_Route')..'.tga'
end
function FG:OpenGatherMap(mapID)
 if not WorldMapFrame then return end
 if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
 if mapID and WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(mapID) end
end
