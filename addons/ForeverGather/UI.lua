local ADDON,FG=...
local T,C=FG.Theme,FG.C
local kinds={'mining','herbalism','skinning'}
local function page(f)
 local p=CreateFrame('Frame',nil,f);p:SetSize(912,434);p:SetPoint('TOPLEFT',24,-158);return p
end
local function section(p,title,x,y,w)
 local b=T.Box(p,x,y,w,434,true);T.Text(b,title,16,12,w-32,24,13,C.gold);return b
end
function FG:BuildExpeditionPage(f)
 local p=page(f);f.routePage=p
 local left=section(p,'FIELD JOURNAL',0,0,252);p.stats={}
 for i,k in ipairs(kinds)do
  local card=T.Box(left,12,48+(i-1)*64,228,56)
  T.Art(card,k=='mining' and 'Icon_Mining' or k=='herbalism' and 'Icon_Herb' or 'Icon_Skin',8,7,42)
  T.Text(card,self.KINDS[k].label,60,7,110,20,12,C.text)
  T.Text(card,'known locations',60,29,124,14,10,C.muted)
  local v=T.Text(card,'0',180,9,38,32,23,C.gold);v:SetJustifyH('RIGHT');p.stats[k]=v
 end
 T.Rule(left,16,246,220)
 T.Text(left,'THIS SESSION',16,258,220,18,10,C.muted)
 p.session=T.Text(left,'0',16,284,106,38,30,C.text)
 p.rate=T.Text(left,'0 /h',126,284,108,38,24,C.cyan)
 T.Text(left,'gathers',16,324,106,18,11,C.muted);T.Text(left,'gathering rate',126,324,110,18,11,C.muted)
 p.elapsed=T.Text(left,'00:00',16,360,220,18,12,C.muted)
 T.Button(left,'New session',16,390,220,30,function()FG:ResetSession()end)
 local right=T.Box(p,272,0,640,434,true)
 T.Text(right,'NEXT DISCOVERY',18,12,430,18,10,C.cyan)
 p.nextIcon=T.Art(right,'Icon_Route',16,39,66)
 p.nextName=T.Text(right,'Your next expedition starts here',96,39,342,28,19,C.text)
 p.nextMeta=T.Text(right,'Learn two locations, then build a route.',96,74,342,22,11,C.muted)
 p.distance=T.Text(right,'--',466,38,152,32,28,C.gold);p.distance:SetJustifyH('RIGHT')
 p.progress=T.Text(right,'NO ACTIVE ROUTE',466,79,152,18,10,C.muted);p.progress:SetJustifyH('RIGHT')
 T.Rule(right,18,119,604)
 p.search=T.Edit(right,18,136,430,'Filter a resource, e.g. Copper Vein',function(value)FG:SetFocus(FG.db.profile.focusKind,value)end)
 p.search:SetText(self.db.profile.focusResource or '')
 T.Button(right,'Build route',462,136,160,34,function()FG:BuildRoute()end,true)
 p.filters={}
 local labels={'All','Mining','Herbs','Skinning'};local keys={'','mining','herbalism','skinning'}
 for i,k in ipairs(keys)do p.filters[i]=T.Button(right,labels[i],18+(i-1)*110,181,100,28,function()FG:SetFocus(k,p.search:GetText())end);p.filters[i].kind=k end
 T.Button(right,'Clear route',462,181,160,28,function()FG:ClearRoute()end)
 T.Text(right,'ROUTE STOPS',18,226,204,20,10,C.muted)
 p.queueMeta=T.Text(right,'',242,226,380,20,10,C.muted);p.queueMeta:SetJustifyH('RIGHT')
 p.queue=T.List(right,18,252,604,124,41)
 p.empty=T.Paragraph(right,'No route yet. Gather resources normally to save their locations.\nThen choose a profession and build your route.',36,275,568,62,12,C.muted)
 T.Button(right,'World map',18,389,194,30,function()FG:OpenGatherMap(FG.db.route and FG.db.route.mapID)end)
 T.Button(right,'TomTom waypoint',222,389,194,30,function()FG:WaypointNextRoute()end)
 T.Button(right,'Next stop',426,389,196,30,function()FG:AdvanceRoute()end)
end
function FG:BuildLedgerPage(f)
 local p=page(f);f.atlasPage=p;p.mode='maps'
 local left=section(p,'RESOURCE ATLAS',0,0,350)
 p.search=T.Edit(left,14,48,322,'Search maps or resources',function()FG:RefreshAtlas()end)
 p.filters={};local modes={'maps','mining','herbalism','skinning'};local labels={'Maps','Mining','Herbs','Skins'}
 for i,mode in ipairs(modes)do p.filters[i]=T.Button(left,labels[i],14+(i-1)*82,94,76,28,function()p.mode=mode;p.selected=nil;p.list.offset=0;FG:RefreshAtlas()end);p.filters[i].mode=mode end
 p.list=T.List(left,14,137,322,277,46)
 local right=section(p,'DISCOVERY DETAILS',370,0,542)
 p.title=T.Text(right,'Your world, remembered',18,50,506,30,21,C.text)
 p.meta=T.Text(right,'Choose a map or resource on the left.',18,87,506,20,12,C.muted)
 p.details=T.List(right,18,130,506,235,46)
 p.empty=T.Paragraph(right,'Every successful gather adds knowledge to your atlas.\nMine ore, pick herbs or skin creatures to get started.',20,172,500,76,13,C.muted)
 T.Button(right,'Open map',18,389,160,30,function()local id=p.selected and p.selected.mapID;FG:OpenGatherMap(id)end)
 T.Button(right,'Import',190,389,160,30,function()FG:ShowImport()end)
 T.Button(right,'Export all',362,389,162,30,function()FG:ShowExport(nil)end)
end
function FG:RefreshAtlas()
 local p=self.ui and self.ui.atlasPage;if not p or not p:IsShown()then return end
 p.list:Clear();p.details:Clear();for _,b in ipairs(p.filters)do b:Refresh(b.mode==p.mode)end
 local data=p.mode=='maps' and self:GetKnownMaps() or self:GetResourceCatalog(p.mode)
 local needle=string.lower(p.search:GetText()or '');local n=0
 for _,entry in ipairs(data)do
  if needle=='' or string.find(string.lower(entry.name),needle,1,true)then
   n=n+1;local row=p.list:Row(n);row.title:SetText(entry.name);row.fullName=entry.name;row.count:SetText(entry.total or entry.nodes)
   row.meta:SetText(p.mode=='maps' and 'locations in this zone' or string.format('%d maps',entry.mapCount));row.icon:SetTexture(self:IconFor(entry.kind))
   row:SetScript('OnClick',function()p.selected=entry;p.details.offset=0;FG:RefreshAtlas()end)
  end
 end
 p.list:Finish(n)
 local e=p.selected;local detail={}
 if e then
  p.title:SetText(e.name)
  if e.mapID then detail=self:GetResourcesOnMap(e.mapID);p.meta:SetText(string.format('%d locations  •  %d observations',e.total or self:Count(nil,e.mapID),self:GetMapObservationTotal(e.mapID)))
  else detail=self:GetMapsForResource(e.kind,e.name);p.meta:SetText(string.format('%d locations across %d maps',e.nodes,e.mapCount)) end
 else p.title:SetText(n==0 and 'The unexplored world awaits' or 'Your world, remembered');p.meta:SetText('Choose a map or resource on the left.')end
 for i,d in ipairs(detail)do local row=p.details:Row(i);row.title:SetText(d.name);row.fullName=d.name;row.meta:SetText(string.format('%d observations',d.observations or 0));row.count:SetText(d.nodes);row.icon:SetTexture(self:IconFor(d.kind))
  row:SetScript('OnClick',function()if d.mapID then FG:OpenGatherMap(d.mapID)elseif e and e.mapID then FG:OpenGatherMap(e.mapID)end end)
 end
 p.details:Finish(#detail);p.empty:SetShown(#detail==0)
end
function FG:BuildSettingsPage(f)
 local p=page(f);f.settingsPage=p;p.toggles={}
 local a=section(p,'MAP & TRACKING',0,0,286)
 local b=section(p,'ROUTE & DISPLAY',306,0,286)
 local c=section(p,'YOUR EXPEDITION',612,0,300)
 local defs={{'Minimap markers','showMinimap'},{'World map markers','showWorldMap'},{'Mining locations','showMining'},{'Herbalism locations','showHerbs'},{'Skinning locations','showSkinning'},{'Skinning heatmap','showSkinHeat'},{'Fade visited nodes','fadeVisited'},{'Hide unusable nodes','hideUnusable'}}
 for i,d in ipairs(defs)do p.toggles[#p.toggles+1]=T.Toggle(a,d[1],d[2],18,46+(i-1)*37,250)end
 local opts={{'Loop route','routeLoop'},{'Prefer confirmed nodes','routePreferConfirmed'},{'Advance on arrival','autoAdvanceRoute'},{'Show route lines','showRoute'},{'Compact HUD','showFieldBar'},{'Minimap button','minimapButton'},{'Gather notifications','toasts'},{'New session on login','autoSession'}}
 for i,d in ipairs(opts)do p.toggles[#p.toggles+1]=T.Toggle(b,d[1],d[2],18,46+(i-1)*37,250)end
 T.Text(c,'Interface size',18,50,262,20,12,C.text)
 for i,v in ipairs({.85,1,1.1})do T.Button(c,math.floor(v*100)..'%',18+(i-1)*90,80,82,30,function()FG.db.profile.expeditionScale=v;T.Fit(f,960,646,v)end)end
 T.Text(c,'Map marker size',18,128,262,20,12,C.text)
 for i,v in ipairs({.60,.78,1})do T.Button(c,({'Small','Normal','Large'})[i],18+(i-1)*90,158,82,30,function()FG.db.profile.pinScale=v;FG:RefreshPins()end)end
 T.Button(c,'Reset window positions',18,212,264,32,function()
  FG.db.profile.expeditionPosition=nil;FG.db.profile.expeditionHUDPosition=nil
  f:ClearAllPoints();f:SetPoint('CENTER');FG.fieldBar:ClearAllPoints();FG.fieldBar:SetPoint('RIGHT',UIParent,'RIGHT',-36,80)
 end)
 T.Button(c,'Diagnostics',18,258,264,32,function()FG:ShowDiagnostics()end)
 T.Button(c,'Export backup',18,304,264,32,function()FG:ShowExport(nil)end)
 T.Text(c,'Forever Gatherer',18,360,264,22,16,C.gold)
 T.Text(c,'by 0xgle  /  '..FG.VERSION,18,390,264,18,10,C.muted)
end
function FG:InitUI()
 local f=CreateFrame('Frame','ForeverGatherMain',UIParent,'BackdropTemplate');self.ui=f
 f:SetSize(960,646);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');T.Skin(f,C.bg);f:Hide();f:EnableMouse(true)
 T.Art(f,'Header',1,1,958,114,'BACKGROUND'):SetTexCoord(0,1,.18,.85)
 T.Art(f,'Emblem',23,22,74)
 T.Text(f,'FOREVER GATHERER',114,28,590,32,25,C.text)
 T.Text(f,'E X P E D I T I O N',115,66,350,22,11,C.gold)
 local drag=CreateFrame('Frame',nil,f);drag:SetPoint('TOPLEFT');drag:SetSize(890,114);T.Movable(f,'expeditionPosition',drag)
 T.Button(f,'x',912,16,30,30,function()f:Hide()end)
 f.zoneHeader=T.Text(f,'',594,70,340,20,12,C.text);f.zoneHeader:SetJustifyH('RIGHT')
 T.Rule(f,24,114,912,C.border)
 self:BuildExpeditionPage(f);self:BuildLedgerPage(f);self:BuildSettingsPage(f)
 f.tabs={}
 local labels={'Expedition','Resource atlas','Settings'}
 for i,view in ipairs({'route','atlas','settings'})do f.tabs[i]=T.Button(f,labels[i],24+(i-1)*166,123,154,27,function()f:SetMainView(view)end);f.tabs[i].view=view end
 function f:SetMainView(view)
  self.mainView=view;self.routePage:SetShown(view=='route');self.atlasPage:SetShown(view=='atlas');self.settingsPage:SetShown(view=='settings')
  for _,b in ipairs(self.tabs)do b:Refresh(b.view==view)end
  FG:UIRefresh();if view=='atlas'then FG:RefreshAtlas()end
 end
 T.Rule(f,24,608,912)
 T.Text(f,'by 0xgle',24,618,160,18,11,C.gold)
 f.footer=T.Text(f,'',240,618,696,18,10,C.muted);f.footer:SetJustifyH('RIGHT')
 T.Fit(f,960,646,self.db.profile.expeditionScale or 1)
 f:SetScript('OnShow',function()T.Fit(f,960,646,FG.db.profile.expeditionScale or 1);FG:UIRefresh();FG:RefreshAtlas()end)
 f:RegisterEvent('UI_SCALE_CHANGED');f:RegisterEvent('DISPLAY_SIZE_CHANGED');f:SetScript('OnEvent',function()T.Fit(f,960,646,FG.db.profile.expeditionScale or 1)end)
 UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,'ForeverGatherMain')
 f:SetMainView('route');self:CreateMinimapButton()
 self.uiTicker=C_Timer.NewTicker(1,function()if FG.ui:IsShown()then FG:UIRefresh()end;FG:UpdateFieldBar()end)
 if self.db.meta.expeditionWelcome~=3 then self.db.meta.expeditionWelcome=3;self:Print('Expedition by 0xgle ready. /fg opens the journal; /fg hud toggles the compact HUD.')end
end
function FG:UIRefresh()
 local f=self.ui;if not f then return end
 local mapID=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player');f.zoneHeader:SetText(self:GetZoneName(mapID))
 local p=f.routePage;if not p then return end
 for _,k in ipairs(kinds)do p.stats[k]:SetText(self:Count(k,mapID))end
 p.session:SetText(self:GetSessionTotal());p.rate:SetText(string.format('%.0f /h',self:GetSessionRate()))
 local e=self:SessionElapsed();p.elapsed:SetText(string.format('%02d:%02d elapsed',math.floor(e/60),e%60))
 for _,b in ipairs(p.filters)do b:Refresh(b.kind==(self.db.profile.focusKind or ''))end
 if not p.search:HasFocus()then p.search:SetText(self.db.profile.focusResource or '')end
 local r=self.db.route;local nextPoint,d,idx=self:GetNextRoutePoint()
 if nextPoint then
  p.nextName:SetText(nextPoint.name);p.nextIcon:SetTexture(self:IconFor(nextPoint.kind));p.distance:SetText(string.format('%.0f yd',d or 0))
  p.nextMeta:SetText(string.format('%.1f, %.1f  •  %s',nextPoint.x*100,nextPoint.y*100,self:GetZoneName(r.mapID)));p.progress:SetText(string.format('STOP %02d / %02d',idx,#r.points))
 else
  p.nextName:SetText(r and (r.finished and 'Expedition complete' or 'Your route is waiting') or 'Your next expedition starts here')
  p.nextMeta:SetText(r and self:GetZoneName(r.mapID) or 'Learn two locations, then build a route.');p.distance:SetText('--');p.progress:SetText(r and (r.finished and 'ROUTE COMPLETE' or 'ANOTHER ZONE') or 'NO ACTIVE ROUTE');p.nextIcon:SetTexture(self:IconFor())
 end
 p.queue:Clear();local n=r and #(r.points or {})or 0;p.empty:SetShown(n==0)
 p.queueMeta:SetText(n>0 and string.format('%d stops  •  %.0f yd  •  scroll to explore',n,r.distance or 0)or 'No route selected')
 for i,pt in ipairs(r and r.points or {})do local row=p.queue:Row(i);row.title:SetText(string.format('%02d   %s',i,pt.name or 'Route stop'));row.fullName=pt.name;row.meta:SetText(string.format('%.1f, %.1f',pt.x*100,pt.y*100));row.icon:SetTexture(self:IconFor(pt.kind));row.count:SetText(i==(r.current or 1) and not r.finished and 'NEXT' or '')
  row:SetScript('OnClick',function()r.current=i;r.finished=nil;r.arrivalLatch=nil;FG.routeRevision=(FG.routeRevision or 0)+1;FG:RefreshPins();FG:UIRefresh()end)
 end
 p.queue:Finish(n)
 local current=r and r.current or 0
 if p.lastCurrent~=current or p.lastRouteCreated~=(r and r.created) then
  p.lastCurrent=current;p.lastRouteCreated=r and r.created
  p.queue.offset=math.max(0,math.min(math.max(0,p.queue.child:GetHeight()-124),(current-1)*41))
  p.queue:SetVerticalScroll(p.queue.offset)
 end
 for _,b in ipairs(f.settingsPage.toggles)do b:Refresh()end
 local last=self.db.session.last
 f.footer:SetText(last and ('Last gather: '..(last.name or 'Resource'))or 'Explore. Gather. Remember.')
 if f.mainView=='atlas' and f.atlasRevision~=self.dataRevision then self:RefreshAtlas();f.atlasRevision=self.dataRevision end
end
function FG:ToggleUI()
 if not self.ui then return end;self.ui:SetShown(not self.ui:IsShown())
end
function FG:CreateMinimapButton()
 local b=CreateFrame('Button','ForeverGatherMinimapButton',Minimap);self.minimapButton=b
 b:SetSize(34,34);b:SetFrameLevel(Minimap:GetFrameLevel()+30);T.Art(b,'Emblem',0,0,34)
 local function position()local a=math.rad(FG.db.profile.minimapButtonAngle or 225);b:ClearAllPoints();b:SetPoint('CENTER',Minimap,'CENTER',math.cos(a)*80,math.sin(a)*80)end
 position();b:SetShown(self.db.profile.minimapButton)
 b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:RegisterForDrag('LeftButton')
 b:SetScript('OnClick',function(_,btn)if btn=='RightButton'then FG:ToggleFieldBar()else FG:ToggleUI()end end)
 b:SetScript('OnDragStart',function(s)s:SetScript('OnUpdate',function()
  local x,y=GetCursorPosition();local scale=Minimap:GetEffectiveScale();local cx,cy=Minimap:GetCenter()
  FG.db.profile.minimapButtonAngle=math.deg(math.atan2(y/scale-cy,x/scale-cx));position()
 end)end)
 b:SetScript('OnDragStop',function(s)s:SetScript('OnUpdate',nil)end)
 b:SetScript('OnEnter',function(s)GameTooltip:SetOwner(s,'ANCHOR_LEFT');GameTooltip:AddLine('Forever Gatherer',unpack(C.gold));GameTooltip:AddLine('Left: Expedition  /  Right: HUD',1,1,1);GameTooltip:AddLine('Drag to move  /  by 0xgle',.7,.75,.78);GameTooltip:Show()end)
 b:SetScript('OnLeave',function()GameTooltip:Hide()end)
end
function FG:Toast(kind,name,record,isNew)
 if not self.toast then
  local f=CreateFrame('Frame',nil,UIParent,'BackdropTemplate');self.toast=f;f:SetSize(360,72);f:SetPoint('TOP',0,-126);f:SetFrameStrata('DIALOG');T.Skin(f,C.bg)
  f.icon=T.Art(f,'Icon_Route',12,12,48);f.title=T.Text(f,'',74,12,274,18,10,C.gold);f.name=T.Text(f,'',74,35,274,24,14,C.text)
 end
 local f=self.toast;f.icon:SetTexture(self:IconFor(kind));f.title:SetText(isNew and 'NEW DISCOVERY' or 'LOCATION CONFIRMED');f.name:SetText(name);f:Show()
 if f.timer then f.timer:Cancel()end;f.timer=C_Timer.NewTimer(2.5,function()f:Hide()end)
end
