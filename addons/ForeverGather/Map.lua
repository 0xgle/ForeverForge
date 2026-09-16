local ADDON,FG=...
local miniPins,miniLines={},{}
local worldLines={}
local nextMini
local function fgAtan2(y,x)
 if math.atan2 then return math.atan2(y,x) end
 if x>0 then return math.atan(y/x) end
 if x<0 and y>=0 then return math.atan(y/x)+math.pi end
 if x<0 and y<0 then return math.atan(y/x)-math.pi end
 if x==0 and y>0 then return math.pi/2 end
 if x==0 and y<0 then return -math.pi/2 end
 return 0
end
local function acquirePin(pool,parent)
 for _,p in ipairs(pool) do if not p.used then p.used=true; p:SetParent(parent); p:SetSize(15,15); p.tex:SetSize(12,12); p:Show(); return p end end
 local p=CreateFrame("Button",nil,parent); p:SetSize(15,15); p.tex=p:CreateTexture(nil,"ARTWORK"); p.tex:SetSize(12,12); p.tex:SetPoint("CENTER"); p.glow=p:CreateTexture(nil,"BACKGROUND"); p.glow:SetTexture(FG.MEDIA.."Glow.tga"); p.glow:SetPoint("CENTER"); p.glow:SetSize(18,18)
 p:SetScript("OnEnter",function(s)
  local r=s.rec; if not r then return end; local _,label=FG:Confidence(r)
  GameTooltip:SetOwner(s,"ANCHOR_LEFT"); GameTooltip:AddLine(r.name,FG.C.gold[1],FG.C.gold[2],FG.C.gold[3]); GameTooltip:AddLine(FG.KINDS[s.kind].label.."  •  "..label,FG.C.cyan[1],FG.C.cyan[2],FG.C.cyan[3])
  GameTooltip:AddDoubleLine("Observations",r.count or 1,1,1,1,.9,.8,.5); GameTooltip:AddDoubleLine("Respawn model",FG:RespawnText(r),1,1,1,.7,.85,.85); GameTooltip:AddDoubleLine("Coordinates",string.format("%.1f, %.1f",r.x*100,r.y*100),1,1,1,.7,.8,.8)
  if r.npcID then GameTooltip:AddDoubleLine("NPC ID",r.npcID,1,1,1,.7,.8,.8) end; if r.source then GameTooltip:AddDoubleLine("Source",r.source,1,1,1,.6,.7,.7) end
  if _G.TomTom then GameTooltip:AddLine("Right-click: TomTom waypoint",.65,.9,.92) end; GameTooltip:AddLine("Shift + Right-click: delete learned point",.9,.55,.35); GameTooltip:Show()
 end)
 p:SetScript("OnLeave",GameTooltip_Hide); p:RegisterForClicks("LeftButtonUp","RightButtonUp")
 p:SetScript("OnClick",function(s,button)
  if button=="RightButton" and s.rec then
   if IsShiftKeyDown and IsShiftKeyDown() then if FG:DeleteRecord(s.mapID,s.kind,s.rec.id) then FG:Print("Deleted "..s.rec.name..".") end
   else FG:AddTomTomWaypoint(s.mapID,s.rec.x,s.rec.y,s.rec.name) end
  end
 end)
 pool[#pool+1]=p; p.used=true; return p
end
local function clearPool(pool) for _,p in ipairs(pool) do p.used=false; p:Hide() end end
local function acquireLine(pool,parent)
 for _,l in ipairs(pool) do if not l.used then l.used=true; l:Show(); return l end end
 local l=parent:CreateLine(nil,"ARTWORK"); l:SetColorTexture(FG.C.cyan[1],FG.C.cyan[2],FG.C.cyan[3],.34); l:SetThickness(1.25); pool[#pool+1]=l; l.used=true; return l
end
local function clearLines(pool) for _,l in ipairs(pool) do l.used=false; l:Hide() end end
local function acquireWorldLine(parent)
 for _,l in ipairs(worldLines) do if not l.used then l.used=true; l:SetParent(parent); l:Show(); return l end end
 local l=parent:CreateLine(nil,"ARTWORK")
 l:SetColorTexture(FG.C.cyan[1],FG.C.cyan[2],FG.C.cyan[3],.30)
 l:SetThickness(FG.db and FG.db.profile and FG.db.profile.routeThickness or 1.25)
 worldLines[#worldLines+1]=l
 l.used=true
 return l
end
local function clearWorldLines() for _,l in ipairs(worldLines) do l.used=false; l:Hide() end end
local function nextPin(parent)
 local p=CreateFrame("Frame",nil,parent)
 p:SetSize(16,16)
 p.tex=p:CreateTexture(nil,"ARTWORK")
 p.tex:SetTexture(FG.MEDIA.."Pin_Next.tga")
 p.tex:SetAllPoints()
 p.isEdge=false
 p:Hide()
 return p
end
ForeverGatherWorldMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function ForeverGatherWorldMapPinMixin:OnLoad()
 if self.UseFrameLevelType then self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI") end
 if self.SetScalingLimits then self:SetScalingLimits(1,1.0,1.15) end
 self:RegisterForClicks("LeftButtonUp","RightButtonUp")
 self:SetScript("OnEnter",function(pin) pin:FG_OnEnter() end)
 self:SetScript("OnLeave",function() GameTooltip:Hide() end)
 self:SetScript("OnClick",function(pin,button) pin:FG_OnClick(button) end)
end

function ForeverGatherWorldMapPinMixin:OnAcquired(kind,rec,mapID,mode,alpha,size)
 self.kind=kind; self.rec=rec; self.mapID=mapID; self.mode=mode
 self:SetPosition(rec.x,rec.y)
 self:SetSize(size or 12,size or 12)
 self:SetAlpha(alpha or 1)
 self.texture:SetTexture(mode=="heat" and (FG.MEDIA.."Heat.tga") or mode=="next" and (FG.MEDIA.."Pin_Next.tga") or FG.KINDS[kind].pin)
 self.texture:SetTexCoord(0,1,0,1)
 if self.glow then
  self.glow:SetTexture(FG.MEDIA.."Glow.tga")
  self.glow:SetShown(mode~="heat")
  self.glow:SetAlpha(mode=="next" and .18 or .04)
 end
 self:EnableMouse(mode=="node" or mode=="next")
 self:Show()
end

function ForeverGatherWorldMapPinMixin:OnReleased()
 self.kind=nil; self.rec=nil; self.mapID=nil; self.mode=nil
 self:Hide()
end

function ForeverGatherWorldMapPinMixin:FG_OnEnter()
 local r=self.rec
 if not r or self.mode=="heat" then return end
 GameTooltip:SetOwner(self,"ANCHOR_LEFT")
 if self.mode=="next" then
  GameTooltip:AddLine("NEXT ROUTE STOP",FG.C.gold[1],FG.C.gold[2],FG.C.gold[3])
  GameTooltip:AddLine(r.name or "Route stop",FG.C.cyan[1],FG.C.cyan[2],FG.C.cyan[3])
 else
  local _,label=FG:Confidence(r)
  GameTooltip:AddLine(r.name,FG.C.gold[1],FG.C.gold[2],FG.C.gold[3])
  GameTooltip:AddLine(FG.KINDS[self.kind].label.."  •  "..label,FG.C.cyan[1],FG.C.cyan[2],FG.C.cyan[3])
  GameTooltip:AddDoubleLine("Observations",r.count or 1,1,1,1,.9,.8,.5)
  GameTooltip:AddDoubleLine("Respawn model",FG:RespawnText(r),1,1,1,.7,.85,.85)
  GameTooltip:AddDoubleLine("Coordinates",string.format("%.1f, %.1f",r.x*100,r.y*100),1,1,1,.7,.8,.8)
  if r.npcID then GameTooltip:AddDoubleLine("NPC ID",r.npcID,1,1,1,.7,.8,.8) end
  if r.source then GameTooltip:AddDoubleLine("Source",r.source,1,1,1,.6,.7,.7) end
  if _G.TomTom then GameTooltip:AddLine("Right-click: TomTom waypoint",.65,.9,.92) end
  GameTooltip:AddLine("Shift + Right-click: delete learned point",.9,.55,.35)
 end
 GameTooltip:Show()
end

function ForeverGatherWorldMapPinMixin:FG_OnClick(button)
 if button~="RightButton" or not self.rec or self.mode=="heat" or self.mode=="next" then return end
 if IsShiftKeyDown and IsShiftKeyDown() then
  if FG:DeleteRecord(self.mapID,self.kind,self.rec.id) then FG:Print("Deleted "..self.rec.name..".") end
 else
  FG:AddTomTomWaypoint(self.mapID,self.rec.x,self.rec.y,self.rec.name)
 end
end

local WorldProvider=CreateFromMixins(MapCanvasDataProviderMixin)

function WorldProvider:RemoveAllData()
 clearWorldLines()
 FG.worldRouteAnchors=nil
 FG.worldPlayerAnchor=nil
 if self:GetMap() then self:GetMap():RemoveAllPinsByTemplate("ForeverGatherWorldMapPinTemplate") end
end

function WorldProvider:RefreshAllData()
 self:RemoveAllData()
 if not FG.db or not FG.db.profile.showWorldMap then return end
 local map=self:GetMap(); if not map then return end
 local mapID=map:GetMapID(); if not mapID then return end

 local heat,maxHeat={},0
 for _,a in ipairs(FG:GetVisibleRecords(mapID)) do
  local kind,r=a.kind,a.r
  if kind=="skinning" and FG.db.profile.showSkinHeat then
   local gx,gy=math.floor(r.x*20),math.floor(r.y*20)
   local key=gx..":"..gy; local wt=r.count or 1
   local e=heat[key] or {x=0,y=0,n=0}
   e.n=e.n+wt; e.x=e.x+r.x*wt; e.y=e.y+r.y*wt; heat[key]=e
   maxHeat=math.max(maxHeat,e.n)
  else
   map:AcquirePin("ForeverGatherWorldMapPinTemplate",kind,r,mapID,"node",math.min(FG.db.profile.pinAlpha or .78,.82),12)
  end
 end

 if FG.db.profile.showSkinHeat and maxHeat>0 then
  for _,e in pairs(heat) do
   local r={x=e.x/e.n,y=e.y/e.n,name="Skinning density"}
   local alpha=.18+.62*math.sqrt(e.n/maxHeat)
   map:AcquirePin("ForeverGatherWorldMapPinTemplate","skinning",r,mapID,"heat",alpha*.72,36)
  end
 end

 FG.worldRouteAnchors={}
 local route=FG.db.route
 if FG.db.profile.showRoute and route and route.mapID==mapID then
  for i,p in ipairs(route.points or {}) do
   FG.worldRouteAnchors[i]=map:AcquirePin("ForeverGatherWorldMapPinTemplate",p.kind or "mining",p,mapID,"routeanchor",0,1)
  end
  local pm,px,py=FG:GetPos()
  if pm==mapID and px and py then
   FG.worldPlayerAnchor=map:AcquirePin("ForeverGatherWorldMapPinTemplate","mining",{x=px,y=py,name="Player"},mapID,"routeanchor",0,1)
  end
 end

 local np=FG:GetNextRoutePoint()
 if np and FG.db.route and FG.db.route.mapID==mapID then
  map:AcquirePin("ForeverGatherWorldMapPinTemplate",np.kind or "mining",np,mapID,"next",.95,18)
 end
end

function FG:DrawWorldRoute(mapID)
 clearWorldLines()
 if not self.db.profile.showRoute then return end
 local r=self.db.route
 if not r or r.mapID~=mapID then return end
 local canvas=(WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()) or (WorldMapFrame and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child)
 if not canvas then return end
 local anchors=self.worldRouteAnchors or {}
 local pts=r.points or {}
 local current=math.max(1,math.min(r.current or 1,#pts))

 for i=2,#pts do
  local a,b=anchors[i-1],anchors[i]
  if a and b then
   local l=acquireWorldLine(canvas)
   local isNext=(i==current or (current==1 and i==2))
   if isNext then
    l:SetColorTexture(self.C.gold[1],self.C.gold[2],self.C.gold[3],.62)
    l:SetThickness(2.0)
   else
    l:SetColorTexture(self.C.cyan[1],self.C.cyan[2],self.C.cyan[3],.26)
    l:SetThickness(self.db.profile.routeThickness or 1.25)
   end
   l:SetStartPoint("CENTER",a,"CENTER",0,0)
   l:SetEndPoint("CENTER",b,"CENTER",0,0)
  end
 end

 if r.loop and #pts>2 and anchors[#pts] and anchors[1] then
  local l=acquireWorldLine(canvas)
  l:SetColorTexture(self.C.cyan[1],self.C.cyan[2],self.C.cyan[3],.20)
  l:SetThickness(self.db.profile.routeThickness or 1.25)
  l:SetStartPoint("CENTER",anchors[#pts],"CENTER",0,0)
  l:SetEndPoint("CENTER",anchors[1],"CENTER",0,0)
 end

 local nextIndex=math.max(1,math.min(r.current or 1,#anchors))
 local nextAnchor=anchors[nextIndex]
 if self.worldPlayerAnchor and nextAnchor then
  local l=acquireWorldLine(canvas)
  l:SetColorTexture(self.C.gold[1],self.C.gold[2],self.C.gold[3],.74)
  l:SetThickness(2.15)
  l:SetStartPoint("CENTER",self.worldPlayerAnchor,"CENTER",0,0)
  l:SetEndPoint("CENTER",nextAnchor,"CENTER",0,0)
 end
end

function FG:InitMap()
 if not WorldMapFrame then
  pcall(function()
   if C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_WorldMap")
   elseif LoadAddOn then LoadAddOn("Blizzard_WorldMap") end
  end)
 end
 self.minimapLayer=CreateFrame("Frame",nil,Minimap)
 self.minimapLayer:SetAllPoints()
 self.minimapLayer:SetFrameLevel(Minimap:GetFrameLevel()+7)
 nextMini=nextPin(self.minimapLayer)

 if WorldMapFrame and WorldMapFrame.AddDataProvider then
  self.worldProvider=WorldProvider
  WorldMapFrame:AddDataProvider(WorldProvider)
 end
 self.mapTicker=C_Timer.NewTicker(.12,function()
  if FG.db then
   FG:UpdateMinimapPins(false)
   if WorldMapFrame and WorldMapFrame:IsShown() then FG:UpdateWorldPins(false) end
  end
 end)
end
function FG:GetVisibleRecords(mapID)
 self.visibleCache=self.visibleCache or {}; local c=self.visibleCache[mapID]
 if c and c.revision==self.dataRevision then return c.records end
 local out={}; for kind,b in pairs(self.db.nodes[mapID] or {}) do for _,r in pairs(b) do if self:ShouldShow(kind,r) then out[#out+1]={kind=kind,r=r} end end end
 self.visibleCache[mapID]={revision=self.dataRevision,records=out}; return out
end
function FG:RefreshPins()
 self.worldState=nil; self.miniState=nil
 self:UpdateMinimapPins(true)
 self:UpdateWorldPins(true)
end

function FG:UpdateWorldPins(force)
 if not self.worldProvider or not WorldMapFrame or not WorldMapFrame:IsShown() then clearWorldLines(); return end
 local mapID=WorldMapFrame:GetMapID(); if not mapID then clearWorldLines(); return end
 local state=table.concat({mapID,self.dataRevision or 0,self.routeRevision or 0,self.db.profile.showWorldMap and 1 or 0,self.db.profile.showSkinHeat and 1 or 0},":")
 if not force and self.worldState==state then self:DrawWorldRoute(mapID); return end
 self.worldState=state
 self.worldProvider:RefreshAllData()
 self:DrawWorldRoute(mapID)
end

function FG:ProjectToMinimapRaw(mapID,px,py,x,y,viewRadius,halfW,halfH)
 local pInstance,pwx,pwy=self:GetPlayerWorldPos()
 local nInstance,nwx,nwy=self:WorldPos(mapID,x,y)
 local xDist,yDist
 if pInstance and nInstance and pInstance==nInstance and pwx and nwx then
  xDist,yDist=pwx-nwx,pwy-nwy
 else
  xDist,yDist=(px-x)*1000,(py-y)*1000
 end
 local d=math.sqrt(xDist*xDist+yDist*yDist)
 local rotate=(C_CVar and C_CVar.GetCVarBool and C_CVar.GetCVarBool("rotateMinimap")) or (GetCVarBool and GetCVarBool("rotateMinimap"))
 if rotate then
  local f=GetPlayerFacing() or 0
  local c,s=math.cos(f),math.sin(f)
  local dx,dy=xDist,yDist
  xDist=dx*c-dy*s
  yDist=dx*s+dy*c
 end
 local diffX,diffY=xDist/viewRadius,yDist/viewRadius
 local dist=math.sqrt(diffX*diffX+diffY*diffY)
 return diffX*halfW,-diffY*halfH,d,dist
end

function FG:ProjectToMinimap(mapID,px,py,x,y,viewRadius,halfW,halfH)
 local sx,sy,d,dist=self:ProjectToMinimapRaw(mapID,px,py,x,y,viewRadius,halfW,halfH)
 if not sx or dist>.90 then return nil,nil,d,0 end
 return sx,sy,d,1
end

function FG:ProjectNextToMinimap(mapID,px,py,x,y,viewRadius,halfW,halfH)
 local sx,sy,d,dist=self:ProjectToMinimapRaw(mapID,px,py,x,y,viewRadius,halfW,halfH)
 if not sx then return end
 if dist<=.86 then return sx,sy,d,false,0 end
 local len=math.sqrt(sx*sx+sy*sy)
 if len<=0 then return 0,0,d,false,0 end
 local edgeX,edgeY=sx/len*(halfW*.84),sy/len*(halfH*.84)
 local angle=fgAtan2(edgeY,edgeX)
 return edgeX,edgeY,d,true,angle
end
function FG:ShouldMiniUpdate(force,mapID,px,py)
 if force or not self.miniState then return true end
 local st=self.miniState; if st.mapID~=mapID or st.data~=(self.dataRevision or 0) or st.route~=(self.routeRevision or 0) or st.zoom~=(Minimap.GetZoom and Minimap:GetZoom() or 0) then return true end
 local f=GetPlayerFacing and GetPlayerFacing() or 0; if math.abs((st.facing or 0)-f)>.01 then return true end
 return self:Distance(mapID,px,py,st.x,st.y)>.8
end
function FG:UpdateMinimapPins(force)
 local pr=self.db.profile; if not pr.showMinimap or not Minimap:IsShown() then clearPool(miniPins); clearLines(miniLines); if nextMini then nextMini:Hide() end; return end
 local mapID,px,py=self:GetPos(); if not mapID or not self:ShouldMiniUpdate(force,mapID,px,py) then return end
 local viewRadius=(C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()) or 220; if not viewRadius or viewRadius<=0 then viewRadius=220 end
 local halfW,halfH=math.max(20,Minimap:GetWidth()/2-7),math.max(20,Minimap:GetHeight()/2-7); local cap=math.min(pr.minimapRange or 1000,viewRadius*1.65)
 self.miniState={mapID=mapID,x=px,y=py,data=self.dataRevision or 0,route=self.routeRevision or 0,zoom=Minimap.GetZoom and Minimap:GetZoom() or 0,facing=GetPlayerFacing and GetPlayerFacing() or 0}
 clearPool(miniPins); clearLines(miniLines); if nextMini then nextMini:Hide() end
 local candidates={}
 for _,a in ipairs(self:GetVisibleRecords(mapID)) do local sx,sy,d,edge=self:ProjectToMinimap(mapID,px,py,a.r.x,a.r.y,viewRadius,halfW,halfH); if sx and d<=cap then candidates[#candidates+1]={kind=a.kind,r=a.r,sx=sx,sy=sy,d=d,edge=edge} end end
 table.sort(candidates,function(a,b)return a.d<b.d end); local max=math.min(#candidates,pr.maxMinimapPins or 48)
 for i=1,max do local a=candidates[i]
  if pr.fadeVisited and a.d<12 then self.visited[a.r.id]=self.visited[a.r.id] or GetTime() end
  local p=acquirePin(miniPins,self.minimapLayer); p.kind=a.kind;p.rec=a.r;p.mapID=mapID;p.tex:SetTexture(self.KINDS[a.kind].pin); local cf=self:Confidence(a.r); p.glow:SetAlpha(.015+.035*cf)
  local alpha=math.min(pr.pinAlpha or .78,.82)*(.68+.32*math.max(0,1-a.d/math.max(1,cap)))*(a.edge or 1); local v=self.visited[a.r.id]; if v and GetTime()-v<(pr.fadeVisitedSeconds or 90) then alpha=alpha*.22 end
  p:SetAlpha(alpha); p:SetScale(math.min(pr.pinScale or .78,.82)*(.94+.08*cf)); p:ClearAllPoints(); p:SetPoint("CENTER",Minimap,"CENTER",a.sx,a.sy)
 end
 self:UpdateRouteProgress(); self:DrawMinimapRoute(mapID,px,py,viewRadius,halfW,halfH)
 local np=self:GetNextRoutePoint()
 if np and nextMini then
  local sx,sy,_,isEdge,angle=self:ProjectNextToMinimap(mapID,px,py,np.x,np.y,viewRadius,halfW,halfH)
  if sx then
   nextMini:ClearAllPoints()
   nextMini:SetPoint("CENTER",Minimap,"CENTER",sx,sy)
   nextMini.isEdge=isEdge and true or false
   if nextMini.tex then
    nextMini.tex:SetTexture(isEdge and (self.MEDIA.."EdgeArrow.tga") or (self.MEDIA.."Pin_Next.tga"))
    nextMini.tex:SetRotation(isEdge and (angle or 0) or 0)
   end
   nextMini:SetSize(isEdge and 13 or 16,isEdge and 13 or 16)
   nextMini:SetAlpha(isEdge and .90 or .95)
   nextMini:Show()
  end
 end
 if self.UpdateFieldBar then self:UpdateFieldBar(#candidates) end
end
function FG:DrawMinimapRoute(mapID,px,py,viewRadius,halfW,halfH)
 local r=self.db.route; if not self.db.profile.showRoute or not r or r.mapID~=mapID then return end
 local pts=r.points or {}; local projected={}
 for i,p in ipairs(pts) do local x,y=self:ProjectToMinimap(mapID,px,py,p.x,p.y,viewRadius,halfW,halfH); if x then projected[i]={x=x,y=y} end end
 local current=math.max(1,math.min(r.current or 1,#pts))
 for i=2,#pts do
  local a,b=projected[i-1],projected[i]
  if a and b then
   local l=acquireLine(miniLines,self.minimapLayer)
   local isNext=(i==current or (current==1 and i==2))
   if isNext then l:SetColorTexture(self.C.gold[1],self.C.gold[2],self.C.gold[3],.60); l:SetThickness(1.8)
   else l:SetColorTexture(self.C.cyan[1],self.C.cyan[2],self.C.cyan[3],.25); l:SetThickness(self.db.profile.routeThickness or 1.25) end
   l:SetStartPoint("CENTER",Minimap,a.x,a.y); l:SetEndPoint("CENTER",Minimap,b.x,b.y)
  end
 end
 if r.loop and #pts>2 then local a,b=projected[#pts],projected[1]; if a and b then local l=acquireLine(miniLines,self.minimapLayer); l:SetColorTexture(self.C.cyan[1],self.C.cyan[2],self.C.cyan[3],.18); l:SetThickness(self.db.profile.routeThickness or 1.25); l:SetStartPoint("CENTER",Minimap,a.x,a.y); l:SetEndPoint("CENTER",Minimap,b.x,b.y) end end
 local np=self:GetNextRoutePoint()
 if np then
  local nx,ny,_,isEdge=self:ProjectNextToMinimap(mapID,px,py,np.x,np.y,viewRadius,halfW,halfH)
  if nx then
   local l=acquireLine(miniLines,self.minimapLayer)
   l:SetColorTexture(self.C.gold[1],self.C.gold[2],self.C.gold[3],isEdge and .66 or .76)
   l:SetThickness(isEdge and 1.65 or 1.9)
   l:SetStartPoint("CENTER",Minimap,0,0)
   l:SetEndPoint("CENTER",Minimap,nx,ny)
  end
 end
end
