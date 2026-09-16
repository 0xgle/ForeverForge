local ADDON,FG=...
local C=FG.C

local FONT_TITLE="Fonts\\MORPHEUS.TTF"
local FONT_UI="Fonts\\ARIALN.TTF"

local function setFont(obj,size,color,title)
 local ok=obj:SetFont(title and FONT_TITLE or FONT_UI,size,title and "" or "")
 if not ok then obj:SetFontObject(title and _G.GameFontNormalLarge or _G.GameFontHighlightSmall) end
 if color then obj:SetTextColor(unpack(color)) end
end

local function skin(f,bg,border,edge)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=edge or 1})
 f:SetBackdropColor(unpack(bg))
 f:SetBackdropBorderColor(unpack(border))
end

local function fs(p,text,size,color,title)
 local x=p:CreateFontString(nil,"OVERLAY")
 setFont(x,size or 12,color or C.text,title)
 x:SetText(text or "")
 return x
end

local function thinLine(parent,vertical,color,alpha)
 local t=parent:CreateTexture(nil,"ARTWORK")
 t:SetColorTexture((color or C.cyan)[1],(color or C.cyan)[2],(color or C.cyan)[3],alpha or .18)
 if vertical then t:SetWidth(1) else t:SetHeight(1) end
 return t
end

local function iconTex(parent,path,size,point,relative,relativePoint,x,y)
 local i=parent:CreateTexture(nil,"ARTWORK")
 i:SetTexture(path)
 i:SetSize(size,size)
 i:SetPoint(point or "CENTER",relative or parent,relativePoint or point or "CENTER",x or 0,y or 0)
 return i
end

local function panel(parent,w,h,title,subtitle,icon)
 local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 f:SetSize(w,h)
 skin(f,{.010,.037,.043,.94},{.14,.34,.35,.48},1)
 local inner=CreateFrame("Frame",nil,f,"BackdropTemplate")
 inner:SetPoint("TOPLEFT",3,-3);inner:SetPoint("BOTTOMRIGHT",-3,3)
 skin(inner,{0,0,0,0},{.53,.38,.14,.16},1)
 inner:EnableMouse(false)
 local sheen=f:CreateTexture(nil,"ARTWORK")
 sheen:SetColorTexture(C.cyan[1],C.cyan[2],C.cyan[3],.035)
 sheen:SetPoint("TOPLEFT",2,-2);sheen:SetPoint("TOPRIGHT",-2,-2);sheen:SetHeight(34)
 if icon then
  f.headerIcon=iconTex(f,icon,26,"TOPLEFT",f,"TOPLEFT",14,-12)
 end
 if title then
  local tx=fs(f,title,20,C.gold,true)
  tx:SetPoint("TOPLEFT",icon and 48 or 16,-12)
  f.title=tx
 end
 if subtitle then
  local st=fs(f,subtitle,11,C.muted,false)
  st:SetPoint("TOPLEFT",icon and 48 or 16,-39)
  f.subtitle=st
 end
 return f
end

local function button(parent,text,w,h,primary,icon)
 local b=CreateFrame("Button",nil,parent)
 b:SetSize(w,h)
 local bg=b:CreateTexture(nil,"BACKGROUND")
 bg:SetTexture(FG.MEDIA..(primary and "Button_Primary.tga" or "Button_Secondary.tga"))
 bg:SetAllPoints(); b.bg=bg
 local glow=b:CreateTexture(nil,"ARTWORK")
 glow:SetColorTexture(primary and C.gold[1] or C.cyan[1],primary and C.gold[2] or C.cyan[2],primary and C.gold[3] or C.cyan[3],0)
 glow:SetPoint("BOTTOMLEFT",4,1);glow:SetPoint("BOTTOMRIGHT",-4,1);glow:SetHeight(2);b.glow=glow
 local label=fs(b,text,12,primary and C.gold or C.text,false)
 if icon then
  local it=iconTex(b,icon,20,"CENTER",b,"CENTER",-(label:GetStringWidth()/2+15),0)
  label:SetPoint("CENTER",10,0); b.icon=it
 else label:SetPoint("CENTER") end
 b.label=label
 b:SetScript("OnEnter",function(self) self.bg:SetVertexColor(1.12,1.12,1.12);self.glow:SetAlpha(.75);self.label:SetTextColor(unpack(C.gold)) end)
 b:SetScript("OnLeave",function(self) self.bg:SetVertexColor(1,1,1);self.glow:SetAlpha(0);self.label:SetTextColor(unpack(primary and C.gold or C.text)) end)
 return b
end

local function tinyButton(parent,w,h,icon,tooltip)
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
 b:SetSize(w,h); skin(b,{.008,.035,.041,.88},{.12,.34,.36,.52},1)
 local i=iconTex(b,icon,20);b.icon=i
 b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(C.cyan[1],C.cyan[2],C.cyan[3],.85);if tooltip then GameTooltip:SetOwner(self,"ANCHOR_BOTTOM");GameTooltip:AddLine(tooltip,unpack(C.gold));GameTooltip:Show() end end)
 b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(.12,.34,.36,.52);GameTooltip:Hide() end)
 return b
end

local function customToggle(parent,label,key,x,y)
 local b=CreateFrame("Button",nil,parent)
 b:SetSize(102,24); b:SetPoint("TOPLEFT",x,y)
 local check=b:CreateTexture(nil,"ARTWORK");check:SetSize(22,22);check:SetPoint("LEFT",0,0);b.check=check
 local t=fs(b,label,11,C.text);t:SetPoint("LEFT",check,"RIGHT",5,0);b.label=t
 function b:Refresh()
  local on=FG.db.profile[key] and true or false
  check:SetTexture(FG.MEDIA..(on and "Check_On.tga" or "Check_Off.tga"))
  t:SetTextColor(unpack(on and C.text or C.muted))
 end
 b:SetScript("OnClick",function(self)
  FG.db.profile[key]=not FG.db.profile[key]
  self:Refresh(); FG:InvalidateCaches()
  if FG.RefreshPins then FG:RefreshPins() end
  if key=="showFieldBar" and FG.ToggleFieldBar then FG:ToggleFieldBar(FG.db.profile[key]) end
 end)
 b:SetScript("OnEnter",function()t:SetTextColor(unpack(C.gold))end)
 b:SetScript("OnLeave",function()b:Refresh()end)
 b:Refresh()
 return b
end

local function resourceCard(parent,label,kind,icon,x)
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
 b:SetSize(105,144);b:SetPoint("TOPLEFT",x,-68)
 skin(b,{.008,.045,.052,.96},{.10,.30,.31,.48},1)
 local orb=iconTex(b,icon,72,"TOP",b,"TOP",0,-12)
 local lab=fs(b,label,11,C.text);lab:SetPoint("TOP",orb,"BOTTOM",0,-2)
 local val=fs(b,"0",27,C.text);val:SetPoint("TOP",lab,"BOTTOM",0,-6);b.value=val
 local sub=fs(b,"gathers",10,C.muted);sub:SetPoint("TOP",val,"BOTTOM",0,-2)
 b:SetScript("OnClick",function() FG:SetFocus(kind,FG.ui and FG.ui.focusEdit and FG.ui.focusEdit:GetText() or ""); if FG.ui and FG.ui.RefreshFocusButtons then FG.ui:RefreshFocusButtons() end end)
 b:SetScript("OnEnter",function(self)self:SetBackdropBorderColor(C.cyan[1],C.cyan[2],C.cyan[3],.76);orb:SetScale(1.06)end)
 b:SetScript("OnLeave",function(self)self:SetBackdropBorderColor(.10,.30,.31,.48);orb:SetScale(1)end)
 return b
end

local function segment(parent,label,kind,icon,x)
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
 b:SetSize(122,38); b:SetPoint("TOPLEFT",x,-120)
 local ic=iconTex(b,icon,23,"LEFT",b,"LEFT",13,0)
 local tx=fs(b,label,11,C.text);tx:SetPoint("LEFT",ic,"RIGHT",7,0);b.label=tx;b.kind=kind
 function b:Refresh()
  local active=FG.db.profile.focusKind==kind
  skin(self,active and {.22,.16,.05,.98} or {.008,.043,.050,.95},active and {C.gold[1],C.gold[2],C.gold[3],.88} or {.12,.34,.36,.56},1)
  self.label:SetTextColor(unpack(active and C.gold or C.text)); self:SetAlpha(active and 1 or .90)
 end
 b:SetScript("OnClick",function(self) FG:SetFocus(kind,FG.ui.focusEdit:GetText());FG.ui:RefreshFocusButtons() end)
 b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(C.gold[1],C.gold[2],C.gold[3],.75) end)
 b:SetScript("OnLeave",function(self) self:Refresh() end)
 return b
end

local function metricStrip(parent)
 local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 f:SetSize(338,72);skin(f,{.008,.050,.057,.93},{.12,.30,.31,.36},1)
 local clock=iconTex(f,FG.MEDIA.."Icon_Clock.tga",28,"LEFT",f,"LEFT",12,0)
 local l1=fs(f,"SESSION NOW",10,C.cyan);l1:SetPoint("TOPLEFT",48,-13)
 local v1=fs(f,"00:00 elapsed",14,C.text);v1:SetPoint("TOPLEFT",48,-31);f.elapsed=v1
 local sep=thinLine(f,true,C.cyan,.22);sep:SetPoint("TOP",f,"TOP",0,-10);sep:SetPoint("BOTTOM",f,"BOTTOM",0,10)
 local live=iconTex(f,FG.MEDIA.."Icon_Live.tga",28,"CENTER",f,"CENTER",38,0)
 local v2=fs(f,"0.0/h",20,C.text);v2:SetPoint("LEFT",live,"RIGHT",10,5);f.rate=v2
 local l2=fs(f,"Session rate",10,C.muted);l2:SetPoint("TOPLEFT",v2,"BOTTOMLEFT",0,-2)
 return f
end

local function intelCard(parent,title,h,icon)
 local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 f:SetSize(222,h);skin(f,{.006,.035,.041,.96},{.12,.31,.32,.45},1)
 if icon then iconTex(f,icon,24,"TOPLEFT",f,"TOPLEFT",12,-12) end
 local t=fs(f,title,16,C.gold,true);t:SetPoint("TOPLEFT",icon and 44 or 14,-12);f.title=t
 return f
end

function FG:Toast(k,n,r,isNew)
 if not self.toast then
  local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
  f:SetSize(430,76);f:SetPoint("TOP",0,-145);f:SetFrameStrata("DIALOG")
  skin(f,{.004,.024,.029,.97},{C.gold[1],C.gold[2],C.gold[3],.44},1)
  local bar=f:CreateTexture(nil,"ARTWORK");bar:SetColorTexture(unpack(C.cyan));bar:SetPoint("TOPLEFT",1,-1);bar:SetPoint("BOTTOMLEFT",1,1);bar:SetWidth(3)
  f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetSize(48,48);f.icon:SetPoint("LEFT",15,0)
  f.a=fs(f,"",15,C.gold,true);f.a:SetPoint("TOPLEFT",76,-13)
  f.b=fs(f,"",11,C.text);f.b:SetPoint("TOPLEFT",76,-43)
  self.toast=f
 end
 local f=self.toast
 f.icon:SetTexture(k=="mining" and self.MEDIA.."Icon_Mining.tga" or k=="herbalism" and self.MEDIA.."Icon_Herb.tga" or self.MEDIA.."Icon_Skin.tga")
 f.a:SetText((isNew and "NEW LOCATION" or "LOCATION CONFIRMED").."  //  "..n)
 local _,lab=self:Confidence(r)
 f.b:SetText(self.KINDS[k].label.."  •  "..lab.."  •  observations "..(r.count or 1))
 f:Show(); if f.timer then f.timer:Cancel() end; f.timer=C_Timer.NewTimer(2.7,function()f:Hide()end)
end

function FG:CreateRoutePreview(parent)
 local p=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 p:SetSize(392,128);skin(p,{.006,.027,.031,.92},{.16,.35,.31,.30},1)
 local bg=p:CreateTexture(nil,"BACKGROUND");bg:SetTexture(self.MEDIA.."RoutePreview.tga");bg:SetAllPoints();bg:SetAlpha(.85)
 p.lines={};p.dots={}
 function p:ClearPreview()
  for _,l in ipairs(self.lines) do l:Hide() end
  for _,d in ipairs(self.dots) do d:Hide() end
 end
 function p:Line()
  for _,l in ipairs(self.lines) do if not l.used then l.used=true;l:Show();return l end end
  local l=self:CreateLine(nil,"ARTWORK");l:SetThickness(2);l:SetColorTexture(C.cyan[1],C.cyan[2],C.cyan[3],.72);l.used=true;self.lines[#self.lines+1]=l;return l
 end
 function p:Dot()
  for _,d in ipairs(self.dots) do if not d.used then d.used=true;d:Show();return d end end
  local d=CreateFrame("Frame",nil,self);d:SetSize(15,15);d.tex=d:CreateTexture(nil,"ARTWORK");d.tex:SetAllPoints();d.used=true;self.dots[#self.dots+1]=d;return d
 end
 function p:Refresh()
  for _,l in ipairs(self.lines) do l.used=false;l:Hide() end
  for _,d in ipairs(self.dots) do d.used=false;d:Hide() end
  local r=FG.db.route;if not r or not r.points or #r.points<1 then
   if not self.empty then self.empty=fs(self,"Build a route to preview its flow",11,C.muted);self.empty:SetPoint("CENTER") end
   self.empty:Show();return
  end
  if self.empty then self.empty:Hide() end
  local pts=r.points;local minx,maxx,miny,maxy=1,0,1,0
  for _,pt in ipairs(pts) do minx=math.min(minx,pt.x);maxx=math.max(maxx,pt.x);miny=math.min(miny,pt.y);maxy=math.max(maxy,pt.y) end
  local dx=math.max(.02,maxx-minx);local dy=math.max(.02,maxy-miny);local coords={}
  local maxShow=math.min(#pts,12)
  for i=1,maxShow do local pt=pts[i];local x=16+((pt.x-minx)/dx)*360;local y=-14-((pt.y-miny)/dy)*96;coords[i]={x=x,y=y,pt=pt} end
  for i=2,#coords do local l=self:Line();l:SetStartPoint("TOPLEFT",self,coords[i-1].x,coords[i-1].y);l:SetEndPoint("TOPLEFT",self,coords[i].x,coords[i].y); if i==(r.current or 1) then l:SetColorTexture(C.gold[1],C.gold[2],C.gold[3],.95);l:SetThickness(3) else l:SetColorTexture(C.cyan[1],C.cyan[2],C.cyan[3],.56);l:SetThickness(2) end end
  for i,c in ipairs(coords) do local d=self:Dot();d:ClearAllPoints();d:SetPoint("CENTER",self,"TOPLEFT",c.x,c.y);d.tex:SetTexture(i==(r.current or 1) and FG.MEDIA.."Pin_Next.tga" or FG.MEDIA.."Pin_Mining.tga");d:SetSize(i==(r.current or 1) and 18 or 13,i==(r.current or 1) and 18 or 13) end
 end
 return p
end

function FG:InitUI()
 local f=CreateFrame("Frame","ForeverGatherMain",UIParent,"BackdropTemplate")
 f:SetSize(1120,700);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
 skin(f,{.003,.014,.018,.985},{C.gold[1],C.gold[2],C.gold[3],.50},1);f:Hide();self.ui=f
 local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetTexture(self.MEDIA.."Panel.tga");bg:SetAllPoints();bg:SetAlpha(.93)
 local inner=CreateFrame("Frame",nil,f,"BackdropTemplate");inner:SetPoint("TOPLEFT",4,-4);inner:SetPoint("BOTTOMRIGHT",-4,4);skin(inner,{0,0,0,0},{C.cyan[1],C.cyan[2],C.cyan[3],.16},1);inner:EnableMouse(false)
 local topGlow=f:CreateTexture(nil,"ARTWORK");topGlow:SetColorTexture(C.gold[1],C.gold[2],C.gold[3],.62);topGlow:SetPoint("TOPLEFT",18,-2);topGlow:SetPoint("TOPRIGHT",-18,-2);topGlow:SetHeight(1)

 local logo=iconTex(f,self.MEDIA.."FG_Logo.tga",76,"TOPLEFT",f,"TOPLEFT",20,-10)
 local title=fs(f,"FOREVER GATHER",30,C.gold,true);title:SetPoint("TOPLEFT",102,-19)
 local sub=fs(f,"ROUTE ATLAS  //  MAP & ROUTE HELPER",12,C.cyan);sub:SetPoint("TOPLEFT",105,-54)

 local zoneBox=CreateFrame("Frame",nil,f,"BackdropTemplate");zoneBox:SetSize(178,48);zoneBox:SetPoint("TOPRIGHT",-88,-16);skin(zoneBox,{.007,.036,.042,.94},{.13,.37,.38,.54},1)
 local zlab=fs(zoneBox,"ZONE",9,C.muted);zlab:SetPoint("TOPLEFT",12,-8)
 f.zoneHeader=fs(zoneBox,"—",12,C.text);f.zoneHeader:SetPoint("TOPLEFT",50,-7)
 local ver=fs(zoneBox,self.VERSION,9,C.muted);ver:SetPoint("TOPLEFT",12,-24)
 local author=fs(zoneBox,"by 0xgle",9,C.muted);author:SetPoint("TOPLEFT",92,-24)
 local settings=tinyButton(f,34,34,self.MEDIA.."Icon_Options.tga","Quick display settings");settings:SetPoint("TOPRIGHT",-48,-22)
 local quick=CreateFrame("Frame",nil,f,"BackdropTemplate");quick:SetSize(226,176);quick:SetPoint("TOPRIGHT",-48,-60);quick:SetFrameLevel(f:GetFrameLevel()+20);skin(quick,{.004,.024,.029,.985},{C.gold[1],C.gold[2],C.gold[3],.42},1);quick:Hide();f.quickSettings=quick
 local qt=fs(quick,"QUICK DISPLAY",15,C.gold,true);qt:SetPoint("TOPLEFT",14,-12)
 local qs=fs(quick,"Map overlays & route presentation",9,C.muted);qs:SetPoint("TOPLEFT",14,-36)
 customToggle(quick,"Minimap pins","showMinimap",14,-63);customToggle(quick,"World pins","showWorldMap",116,-63);customToggle(quick,"Heatmap","showSkinHeat",14,-96);customToggle(quick,"Field Bar","showFieldBar",116,-96)
 local small=button(quick,"SMALL PINS",92,28,false);small:SetPoint("BOTTOMLEFT",14,12);small:SetScript("OnClick",function()FG.db.profile.pinScale=.62;FG:RefreshPins()end)
 local normal=button(quick,"DEFAULT",92,28,false);normal:SetPoint("LEFT",small,"RIGHT",10,0);normal:SetScript("OnClick",function()FG.db.profile.pinScale=.76;FG:RefreshPins()end)
 settings:SetScript("OnClick",function()quick:SetShown(not quick:IsShown())end)
 local close=tinyButton(f,34,34,self.MEDIA.."Icon_Next.tga","Close");close:SetPoint("TOPRIGHT",-10,-22);if close.icon then close.icon:Hide() end;local x=fs(close,"×",20,C.muted);x:SetPoint("CENTER",0,1);close:SetScript("OnClick",function()quick:Hide();f:Hide()end)
 local headLine=thinLine(f,false,C.cyan,.16);headLine:SetPoint("TOPLEFT",102,-78);headLine:SetPoint("TOPRIGHT",-16,-78)

 -- LEFT COLUMN
 local left=panel(f,360,514,"LIVE FIELD","Current zone performance and learned locations",self.MEDIA.."Icon_Live.tga");left:SetPoint("TOPLEFT",18,-94);f.left=left
 local liveDot=left:CreateTexture(nil,"ARTWORK");liveDot:SetColorTexture(.27,.95,.52,.95);liveDot:SetSize(6,6);liveDot:SetPoint("TOPRIGHT",-49,-18)
 local liveTxt=fs(left,"LIVE",9,{.32,.92,.54,1});liveTxt:SetPoint("LEFT",liveDot,"RIGHT",5,0)
 f.cardMining=resourceCard(left,"MINING","mining",self.MEDIA.."Icon_Mining.tga",12)
 f.cardHerb=resourceCard(left,"HERBALISM","herbalism",self.MEDIA.."Icon_Herb.tga",126)
 f.cardSkin=resourceCard(left,"SKINNING","skinning",self.MEDIA.."Icon_Skin.tga",240)
 f.metric=metricStrip(left);f.metric:SetPoint("TOPLEFT",11,-222)
 f.sessionSub=fs(left,"0 mined  •  0 herbs  •  0 skinned",11,C.cyan);f.sessionSub:SetPoint("TOPLEFT",14,-305)
 f.lastLine=fs(left,"No previous session",10,C.muted);f.lastLine:SetPoint("TOPLEFT",14,-326)
 local mapVis=panel(left,338,145,"MAP VISIBILITY","Show learned locations on your maps",self.MEDIA.."Icon_Eye.tga");mapVis:SetPoint("BOTTOMLEFT",11,12)
 f.visToggles={
  customToggle(mapVis,"Mining","showMining",12,-54),customToggle(mapVis,"Herbalism","showHerbs",118,-54),customToggle(mapVis,"Skinning","showSkinning",224,-54),
  customToggle(mapVis,"Heatmap","showSkinHeat",12,-88),customToggle(mapVis,"Fade visited","fadeVisited",118,-88),customToggle(mapVis,"World pins","showWorldMap",224,-88)
 }

 -- CENTER COLUMN
 local center=panel(f,430,514,"SMART ROUTE","Build a route directly from learned nodes",self.MEDIA.."Icon_Route.tga");center:SetPoint("TOPLEFT",390,-94);f.center=center
 local focusLabel=fs(center,"RESOURCE FOCUS",9,C.muted);focusLabel:SetPoint("TOPLEFT",16,-67)
 local searchFrame=CreateFrame("Frame",nil,center,"BackdropTemplate");searchFrame:SetSize(398,38);searchFrame:SetPoint("TOPLEFT",16,-84);skin(searchFrame,{.004,.019,.023,.98},{.23,.39,.40,.56},1)
 iconTex(searchFrame,self.MEDIA.."Icon_Search.tga",20,"LEFT",searchFrame,"LEFT",10,0)
 local edit=CreateFrame("EditBox",nil,searchFrame);edit:SetPoint("TOPLEFT",38,-2);edit:SetPoint("BOTTOMRIGHT",-10,2);edit:SetAutoFocus(false);edit:SetTextInsets(0,0,0,0);setFont(edit,12,C.text,false);f.focusEdit=edit
 local hint=fs(searchFrame,"Search resource — Copper Vein, Peacebloom…",11,C.muted);hint:SetPoint("LEFT",38,0);f.focusHint=hint
 edit:SetScript("OnTextChanged",function(self)hint:SetShown(self:GetText()=="")end);edit:SetText(self.db.profile.focusResource or "")
 f.segMine=segment(center,"MINING","mining",self.MEDIA.."Icon_Mining.tga",16)
 f.segHerb=segment(center,"HERBS","herbalism",self.MEDIA.."Icon_Herb.tga",152)
 f.segSkin=segment(center,"SKINNING","skinning",self.MEDIA.."Icon_Skin.tga",288)
 function f:RefreshFocusButtons() self.segMine:Refresh();self.segHerb:Refresh();self.segSkin:Refresh() end;f:RefreshFocusButtons()
 local build=button(center,"BUILD SMART ROUTE",398,44,true,self.MEDIA.."Icon_Route.tga");build:SetPoint("TOPLEFT",16,-169);build:SetScript("OnClick",function()local txt=edit:GetText();if txt and txt~="" then FG.db.profile.focusResource=txt end;FG:BuildRoute()end)
 local openMap=button(center,"OPEN WORLD MAP",193,34,false,self.MEDIA.."Icon_Map.tga");openMap:SetPoint("TOPLEFT",16,-222);openMap:SetScript("OnClick",function()if ToggleWorldMap then ToggleWorldMap() elseif WorldMapFrame then WorldMapFrame:Show() end end)
 local next=button(center,"NEXT NODE",193,34,false,self.MEDIA.."Icon_Next.tga");next:SetPoint("LEFT",openMap,"RIGHT",12,0);next:SetScript("OnClick",function()FG:WaypointNextRoute()end)
 local helperStrip=CreateFrame("Frame",nil,center,"BackdropTemplate")
 helperStrip:SetSize(398,64);helperStrip:SetPoint("TOPLEFT",16,-274)
 skin(helperStrip,{.006,.028,.032,.84},{.12,.31,.32,.30},1)
 local helperLine=thinLine(helperStrip,false,C.cyan,.10);helperLine:SetPoint("TOPLEFT",10,-10);helperLine:SetPoint("TOPRIGHT",-10,-10)
 f.helperHint=fs(helperStrip,"Routes are shown directly on the Minimap and World Map",10,C.muted);f.helperHint:SetPoint("TOPLEFT",16,-18)
 f.helperFocus=fs(helperStrip,"No active route",12,C.cyan);f.helperFocus:SetPoint("TOPLEFT",16,-38)

 -- RIGHT COLUMN
 local right=panel(f,264,514,"FIELD INTEL","Context for the current zone",self.MEDIA.."Icon_Intel.tga");right:SetPoint("TOPRIGHT",-18,-94);f.right=right
 f.nextCard=intelCard(right,"NEXT NODE",140,self.MEDIA.."Icon_Pin.tga");f.nextCard:SetPoint("TOPLEFT",21,-66)
 f.nextValue=fs(f.nextCard,"—",28,C.gold,true);f.nextValue:SetPoint("TOPLEFT",16,-45)
 f.nextName=fs(f.nextCard,"No active route",12,C.text);f.nextName:SetPoint("TOPLEFT",16,-83);f.nextName:SetWidth(132);f.nextName:SetJustifyH("LEFT")
 f.nextResource=iconTex(f.nextCard,self.MEDIA.."Icon_Mining.tga",62,"RIGHT",f.nextCard,"RIGHT",-10,-7)
 f.lastCard=intelCard(right,"LAST GATHER",112,self.MEDIA.."Icon_Clock.tga");f.lastCard:SetPoint("TOPLEFT",21,-218)
 f.lastValue=fs(f.lastCard,"Nothing yet",12,C.text);f.lastValue:SetPoint("TOPLEFT",16,-47);f.lastValue:SetWidth(142);f.lastValue:SetJustifyH("LEFT")
 f.lastMeta=fs(f.lastCard,"",10,C.muted);f.lastMeta:SetPoint("TOPLEFT",16,-71)
 f.lastResource=iconTex(f.lastCard,self.MEDIA.."Icon_Mining.tga",46,"RIGHT",f.lastCard,"RIGHT",-12,-7);f.lastResource:SetAlpha(.82)
 local opts=panel(right,222,142,"ROUTE OPTIONS",nil,self.MEDIA.."Icon_Options.tga");opts:SetPoint("TOPLEFT",21,-342)
 f.optionToggles={customToggle(opts,"Loop route","routeLoop",12,-45),customToggle(opts,"Confirmed only","routePreferConfirmed",12,-76),customToggle(opts,"Auto advance","autoAdvanceRoute",12,-107)}
 local diag=button(right,"DIAGNOSTICS",106,30,false,self.MEDIA.."Icon_Diagnostics.tga");diag:SetPoint("BOTTOMLEFT",21,14);diag:SetScript("OnClick",function()FG:ShowDiagnostics()end)
 local doctor=button(right,"DATA DOCTOR",106,30,false,self.MEDIA.."Icon_Doctor.tga");doctor:SetPoint("LEFT",diag,"RIGHT",10,0);doctor:SetScript("OnClick",function()local n=FG:PruneInvalid();FG:Print("Data Doctor removed "..n.." invalid records.")end)

 -- FOOTER
 local footer=thinLine(f,false,C.gold,.18);footer:SetPoint("BOTTOMLEFT",18,63);footer:SetPoint("BOTTOMRIGHT",-18,63)
 local reset=button(f,"NEW SESSION",120,32,false,self.MEDIA.."Icon_Reset.tga");reset:SetPoint("BOTTOMLEFT",18,18);reset:SetScript("OnClick",function()FG:ResetSession()end)
 local imp=button(f,"IMPORT GATHERMATE2",176,32,false,self.MEDIA.."Icon_Import.tga");imp:SetPoint("LEFT",reset,"RIGHT",10,0);imp:SetScript("OnClick",function()FG:ImportGatherMate2()end)
 local exp=button(f,"EXPORT ZONE",132,32,false,self.MEDIA.."Icon_Export.tga");exp:SetPoint("LEFT",imp,"RIGHT",10,0);exp:SetScript("OnClick",function()FG:ShowExport()end)
 local foot=fs(f,"by 0xgle   •   LOCAL-FIRST   •   OPEN SOURCE   •   NO AUTOMATION",9,C.muted);foot:SetPoint("BOTTOMRIGHT",-18,29)

 self:CreateMinimapButton();self:UIRefresh();C_Timer.NewTicker(1,function()if FG.ui and FG.ui:IsShown()then FG:UIRefresh()end end)
 if self.db.meta.firstRun then C_Timer.After(.8,function()FG:ShowOnboarding()end);self.db.meta.firstRun=false end
end

function FG:UIRefresh()
 if not self.ui then return end
 local f=self.ui;local mapID=C_Map.GetBestMapForUnit("player");local zoneName=self:GetZoneName(mapID);f.zoneHeader:SetText(zoneName)
 f.cardMining.value:SetText(self:Count("mining",mapID));f.cardHerb.value:SetText(self:Count("herbalism",mapID));f.cardSkin.value:SetText(self:Count("skinning",mapID))
 local s=self.db.session;local e=self:SessionElapsed();f.metric.elapsed:SetText(string.format("%02d:%02d elapsed",math.floor(e/60),math.floor(e%60)));f.metric.rate:SetText(string.format("%.1f/h",self:GetSessionRate()))
 f.sessionSub:SetText(string.format("%d mined  •  %d herbs  •  %d skinned",s.mining or 0,s.herbalism or 0,s.skinning or 0))
 local prev=self:GetRecentSession();f.lastLine:SetText(prev and string.format("Previous session: %d gathers",(prev.mining or 0)+(prev.herbalism or 0)+(prev.skinning or 0)) or "No archived session yet")
 f:RefreshFocusButtons()
 local rp=self.db.route
 local np,nd=self:GetNextRoutePoint()
 if rp then
  local focus=(rp.resource and rp.resource~="" and rp.resource) or "All visible"
  if np then f.helperFocus:SetText(string.format("Focus: %s   •   Next: %.0f yd",focus,nd or 0)) else f.helperFocus:SetText("Focus: "..focus) end
 else
  f.helperFocus:SetText("No active route")
 end
 if np then
  f.nextValue:SetText(string.format("%.0f yd",nd or 0));f.nextName:SetText(np.name or "Route node")
  local path=(np.kind=="herbalism" and self.MEDIA.."Icon_Herb.tga") or (np.kind=="skinning" and self.MEDIA.."Icon_Skin.tga") or self.MEDIA.."Icon_Mining.tga";f.nextResource:SetTexture(path)
 else f.nextValue:SetText("—");f.nextName:SetText("No active route");f.nextResource:SetTexture(self.MEDIA.."Icon_Route.tga") end
 local last=s.last
 if last then
  f.lastValue:SetText(last.name or "Gather");local kl=self.KINDS[last.kind] and self.KINDS[last.kind].label or last.kind or "";f.lastMeta:SetText(kl.."  •  just now")
  local path=(last.kind=="herbalism" and self.MEDIA.."Icon_Herb.tga") or (last.kind=="skinning" and self.MEDIA.."Icon_Skin.tga") or self.MEDIA.."Icon_Mining.tga";f.lastResource:SetTexture(path)
 else f.lastValue:SetText("Nothing yet");f.lastMeta:SetText("");f.lastResource:SetTexture(self.MEDIA.."Icon_Clock.tga") end

end

function FG:ToggleUI() if not self.ui then return end;if self.ui:IsShown() then self.ui:Hide() else self:UIRefresh();self.ui:Show() end end

function FG:CreateMinimapButton()
 local b=CreateFrame("Button","ForeverGatherMinimapButton",Minimap)
 b:SetSize(38,38);b:SetPoint("TOPLEFT",-5,-5);b:SetFrameLevel(Minimap:GetFrameLevel()+30)
 local shadow=b:CreateTexture(nil,"BACKGROUND");shadow:SetTexture(self.MEDIA.."Glow.tga");shadow:SetSize(50,50);shadow:SetPoint("CENTER");shadow:SetAlpha(.28)
 local i=b:CreateTexture(nil,"ARTWORK");i:SetTexture(self.MEDIA.."MinimapButton.tga");i:SetAllPoints();b.icon=i
 b:RegisterForClicks("LeftButtonUp","RightButtonUp")
 b:SetScript("OnClick",function(_,button)if button=="RightButton" then FG:ToggleFieldBar() else FG:ToggleUI() end end)
 b:SetScript("OnEnter",function(self)self.icon:SetScale(1.08);shadow:SetAlpha(.48);GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:AddLine("Forever Gather",unpack(C.gold));GameTooltip:AddLine("Left-click: Route Atlas",1,1,1);GameTooltip:AddLine("Right-click: Field Bar",1,1,1);GameTooltip:Show()end)
 b:SetScript("OnLeave",function(self)self.icon:SetScale(1);shadow:SetAlpha(.28);GameTooltip:Hide()end)
 self.minimapButton=b
end

function FG:ShowOnboarding()
 local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");f:SetSize(560,360);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");skin(f,{.004,.020,.025,.985},{C.gold[1],C.gold[2],C.gold[3],.52},1)
 local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetTexture(self.MEDIA.."Panel.tga");bg:SetAllPoints();bg:SetAlpha(.95)
 iconTex(f,self.MEDIA.."FG_Logo.tga",86,"TOP",f,"TOP",0,-15)
 local t=fs(f,"FOREVER GATHER",26,C.gold,true);t:SetPoint("TOP",0,-105)
 local st=fs(f,"ROUTE ATLAS  //  MAP & ROUTE HELPER",10,C.cyan);st:SetPoint("TOP",0,-137)
 local body=fs(f,"Your maps are the navigation layer. Forever Gather learns where resources exist, builds routes through confirmed locations, and keeps the real Blizzard tracking dot visible inside our hollow markers.\n\n1  Gather normally — locations are learned automatically.\n2  Open /fg and choose Mining, Herbs or Skinning.\n3  Build Smart Route.\n4  Follow the route on the Minimap and World Map.",12,C.text)
 body:SetPoint("TOPLEFT",46,-175);body:SetWidth(468);body:SetJustifyH("LEFT");body:SetSpacing(3)
 local ok=button(f,"ENTER THE FIELD",190,38,true,self.MEDIA.."Icon_Route.tga");ok:SetPoint("BOTTOM",0,20);ok:SetScript("OnClick",function()f:Hide();FG:ToggleUI()end)
end
