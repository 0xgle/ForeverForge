unpack=table.unpack
loadstring=load
math.atan2=math.atan
STANDARD_TEXT_FONT='Fonts/FRIZQT__.TTF'; ChatFontNormal={}; UISpecialFrames={}; SlashCmdList={}; WOW_PROJECT_ID=2
local frames={}; local methods={}; local nextid=0
local function new(kind,name,parent)
 nextid=nextid+1
 local f=setmetatable({uid=nextid,id=nextid,kind=kind,name=name,parent=parent,shown=true,scripts={},points={},w=0,h=0,scale=1,level=parent and (parent.level+1) or 0}, {__index=methods})
 frames[#frames+1]=f; if name then _G[name]=f end; return f
end
function CreateFrame(kind,name,parent,template) return new(kind,name,parent or UIParent) end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:GetWidth() return self.w end
function methods:GetHeight() return self.h end
function methods:ClearAllPoints() self.points={};self.all=nil end
function methods:SetAllPoints(target) self.all=target or self.parent end
function methods:SetPoint(point,a,b,c,d)
 local rel,rp,x,y
 if type(a)=='table' then rel=a;rp=b or point;x=c or 0;y=d or 0
 elseif type(a)=='number' then rel=self.parent;rp=point;x=a;y=b or 0
 else rel=self.parent;rp=point;x=0;y=0 end
 self.points[#self.points+1]={point=point,rel=rel,rp=rp,x=x,y=y}
end
function methods:SetBackdrop(b) self.backdrop=b end
function methods:SetBackdropColor(...) self.bg={...} end
function methods:SetBackdropBorderColor(...) self.border={...} end
function methods:SetTextColor(...) self.color={...} end
function methods:SetColorTexture(...) self.colorTexture={...} end
function methods:SetTexture(t) self.texture=t end
function methods:SetTexCoord(...) self.texcoord={...} end
function methods:SetFont(font,size,flags) self.font=font;self.fontsize=size end
function methods:SetFontObject() self.fontsize=12 end
function methods:SetText(s) self.text=tostring(s); if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end end
function methods:GetText() return self.text or '' end
function methods:GetNumLines() local _,n=(self.text or ''):gsub('\n','');return n+1 end
function methods:SetJustifyH(s) self.justify=s end
function methods:SetJustifyV(s) self.justifyV=s end
function methods:SetMaxLines(n) self.maxlines=n end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:HookScript(name,fn) local old=self.scripts[name];self.scripts[name]=function(...) if old then old(...) end;fn(...) end end
function methods:Hide() self.shown=false end
function methods:Show() local before=self.shown;self.shown=true;if not before and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:SetScale(s) self.scale=s end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale end
function methods:SetFrameLevel(n) self.level=n end
function methods:GetFrameLevel() return self.level end
function methods:GetCenter() return self.w/2,self.h/2 end
function methods:GetName() return self.name end
function methods:GetObjectType() return self.kind end
function methods:GetChildren()
 local out={};for _,f in ipairs(frames) do if f.parent==self then out[#out+1]=f end end
 return table.unpack(out)
end
function methods:CreateTexture(name,layer) local x=new('Texture',name,self);x.layer=layer;return x end
function methods:CreateFontString(name,layer) local x=new('FontString',name,self);x.layer=layer;return x end
function methods:SetScrollChild(f) self.scrollchild=f;f.parent=self end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
function methods:SetEnabled(v) self.enabled=v end
function methods:SetNormalTexture(t) self.normalTexture=t end
function methods:AddMessage(msg) print('CHAT '..msg) end
function methods:AddLine() end
for _,n in ipairs({'SetFrameStrata','SetMovable','SetClampedToScreen','EnableMouse','EnableMouseWheel','RegisterForDrag','RegisterForClicks','SetHighlightTexture','SetAutoFocus','SetMultiLine','SetMaxLetters','SetCursorPosition','SetFocus','ClearFocus','HighlightText','SetOwner','StartMoving','StopMovingOrSizing'}) do methods[n]=function() end end
UIParent=new('Frame','UIParent',nil); UIParent:SetSize(1440,900)
Minimap=new('Frame','Minimap',UIParent); Minimap:SetSize(140,140)
GameTooltip=new('Frame','GameTooltip',UIParent); DEFAULT_CHAT_FRAME={AddMessage=methods.AddMessage}
function UnitName() return 'TestCharacter' end
function GetRealmName() return 'TestRealm' end
function GetBuildInfo() return '1.15.9','69722','Sep 2026',11509 end
function GetLocale() return 'enUS' end
local combat=false
function InCombatLockdown() return combat end
function ReloadUI() _G.reloaded=true end
function date(fmt) return os.date(fmt) end
local data={
 {id='ForeverCore',enabled=true,loaded=true,deps={}},
 {id='ForeverBags',enabled=true,loaded=true,deps={}},
 {id='ForeverGather',enabled=true,loaded=true,deps={}},
 {id='ForeverChat',enabled=true,loaded=true,deps={}},
 {id='ForeverDependent',enabled=false,loaded=false,deps={'TestLibrary'}},
 {id='TestLibrary',enabled=false,loaded=false,deps={}},
 {id='OrdinaryAddon',enabled=true,loaded=true,deps={}},
 {id='ForeverMissing',enabled=false,loaded=false,deps={'AbsentLibrary'}},
}
local function get(id) for i,a in ipairs(data) do if a.id==id or i==id then return a end end end
C_AddOns={
 GetNumAddOns=function() return #data end,
 GetAddOnInfo=function(id) local a=get(id); if a then return a.id,a.id,'Description',true,nil end end,
 GetAddOnMetadata=function(id,k) return k=='Version' and '1.0.0' or nil end,
 IsAddOnLoaded=function(id) return get(id).loaded end,
 IsAddOnLoadOnDemand=function(id) return false end,
 GetAddOnDependencies=function(id) return unpack(get(id).deps) end,
 GetAddOnEnableState=function(id,character) assert(character=='TestCharacter');return get(id).enabled and 2 or 0 end,
 EnableAddOn=function(id,character) assert(character=='TestCharacter');get(id).enabled=true end,
 DisableAddOn=function(id,character) assert(character=='TestCharacter');get(id).enabled=false end,
 LoadAddOn=function(id) get(id).loaded=true;return true end,
 UpdateAddOnMemoryUsage=function() end,
 GetAddOnMemoryUsage=function(id) return id*44 end,
}
local F={}
local files={'Core','Manager','Profiles','Integrations','Theme','UI','Boot'}
for _,f in ipairs(files) do assert(loadfile('ForeverCore/'..f..'.lua'))('ForeverCore',F) end
F:InitDB();F:Scan()
local tests=0
local function test(name,fn) fn();tests=tests+1; print('PASS '..name) end
local function reset() F.pending={};F.stagedProfile=nil;combat=false;F.db.profiles={} end
local function equal(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
test('Core cannot be disabled',function() equal(F:Stage('ForeverCore',false),false);equal(next(F.pending),nil) end)
test('Dependency enabling is transitive and staged',function() assert(F:Stage('ForeverDependent',true));equal(F.pending.TestLibrary,true);equal(get('TestLibrary').enabled,false) end)
test('Disabling dependencies also disables dependents',function() F:Stage('TestLibrary',false);equal(F:Desired('ForeverDependent'),false);equal(F:Desired('TestLibrary'),false) end)
test('Missing dependency leaves plan intact',function() reset();F:Stage('ForeverBags',false);equal(F:Stage('ForeverMissing',true),false);equal(F.pending.ForeverBags,false);equal(F.pending.ForeverMissing,nil) end)
test('Combat blocks stage/apply/reload',function() combat=true;equal(F:Stage('ForeverGather',false),false);equal(F:Apply(),false);F:Reload();equal(reloaded,nil);combat=false end)
test('Apply current character and undo',function() assert(F:Apply());equal(get('ForeverBags').enabled,false);equal(F.db.undo.ForeverBags,true);assert(F:StageSnapshot(F.db.undo));assert(F:Apply());equal(get('ForeverBags').enabled,true) end)
test('Failed API call rolls back all mutations',function()
 reset();F:Stage('ForeverBags',false);F:Stage('ForeverGather',false)
 local old=C_AddOns.DisableAddOn;F.A.DisableAddOn=function(id,char) if id=='ForeverGather' then error('Injected failure') end;old(id,char) end
 equal(F:Apply(),false);equal(get('ForeverBags').enabled,true);equal(get('ForeverGather').enabled,true);F.A.DisableAddOn=old;F:Discard()
end)
test('Save/export/import round trip',function()
 reset();assert(F:SaveProfile('Hardcore','suite'));local txt=F:ExportProfile('Hardcore');F.db.profiles={};assert(F:ImportProfile(txt));equal(F.db.profiles.Hardcore.states.ForeverBags,true);equal(F.db.profiles.Hardcore.states.OrdinaryAddon,nil)
end)
test('Import rejects code, duplicate entries, size and invalid schema',function()
 for _,s in ipairs({'print(1)','FCORE2|A|suite\nX=1','FCORE1|A|suite\nX=1\nX=0','FCORE1|A|suite\nX=loadstring()','FCORE1|A|oops\nX=0',string.rep('x',64001)}) do equal(F:ImportProfile(s),false) end
end)
test('Profiles do not overwrite names',function() equal(F:SaveProfile('Hardcore','all'),false);equal(F:ImportProfile(F:ExportProfile('Hardcore')),false) end)
test('Profile conflicts are atomic',function() reset();F:Stage('ForeverBags',false);equal(F:StageSnapshot({ForeverDependent=true,TestLibrary=false}),false);equal(F.pending.ForeverBags,false) end)
test('Unknown imported addons are safely skipped',function() reset();assert(F:StageSnapshot({UnknownAddon=true,ForeverBags=false}));equal(F.pending.ForeverBags,false) end)
test('Legacy slash discovery',function() SLASH_FOREVERCHAT1='/foreverchat';SlashCmdList.FOREVERCHAT=function() _G.chatOpened=true end;F:Scan();F:OpenModule('ForeverChat');equal(chatOpened,true) end)
test('Callback failures are bounded and isolated',function() F:RegisterModule('ForeverChat',{title='ForeverChat',open=function() error('Injected callback') end});F:OpenModule('ForeverChat');equal(#F.errors,1) end)
-- Load UI against a deliberately finite WoW API mock; unknown frame methods fail.
test('All six UI pages build and refresh',function()
 reset();F:BuildUI();F.frame:Show()
 for _,page in ipairs({'Sanctum','Addons','Profiles','Diagnostics','Appearance','About'}) do F.page=page;F:Render();F:Render() end
end)
test('Refresh reuses frames without leaking widgets',function() local before=#frames;for i=1,25 do F:Render() end;equal(#frames,before) end)
test('Modal apply and nested confirmation stay usable',function()
 F:Stage('ForeverBags',false);F:ReviewChanges();assert(F.modal:IsShown());F.modal.box.ok.scripts.OnClick();equal(F.modal:IsShown(),false);equal(get('ForeverBags').enabled,false)
 F:Confirm('Outer','body',function() F:TextDialog('Inner','hint','text') end);F.modal.box.ok.scripts.OnClick();equal(F.modal:IsShown(),true);equal(F.modal.box.title:GetText(),'Inner');F.modal:Hide()
end)
test('Memory/report has versions and no character identifier',function() F:SampleMemory();local s=F:DiagnosticReport();assert(s:find('ForeverBags',1,true));assert(not s:find('TestCharacter',1,true)) end)
test('Minimap creation, scaling and slash commands',function() F:CreateLauncher();F:UpdateMinimap();SlashCmdList.FOREVERCORE('profiles');equal(F.page,'Profiles');SlashCmdList.FOREVERCORE('reset');equal(F.db.settings.scale,1) end)
test('Per-addon minimap icon overrides work',function()
 F.db.settings.hideOtherMinimapButtons=true;F.db.settings.minimapIconOverrides={}
 local btn=CreateFrame('Button','LibDBIcon10_OrdinaryAddon',Minimap);btn:Show()
 F:Scan();F:ApplyMinimapButtonPolicy();equal(btn:IsShown(),false)
 local found=false;for _,g in ipairs(F:GetMinimapIconGroups()) do if g.key=='OrdinaryAddon' then found=true end end;assert(found)
 F:SetAddonMinimapIconVisible('OrdinaryAddon',true);equal(btn:IsShown(),true)
 F:SetAddonMinimapIconVisible('OrdinaryAddon',nil);equal(btn:IsShown(),false)
 F:SetOtherMinimapButtonsHidden(false);equal(btn:IsShown(),true)
 F:SetAddonMinimapIconVisible('OrdinaryAddon',false);equal(btn:IsShown(),false)
 F:SetAddonMinimapIconVisible('OrdinaryAddon',nil);F:SetOtherMinimapButtonsHidden(true)
end)
test('Your Addons minimap checkbox uses the shared icon policy',function()
 F.db.settings.hideOtherMinimapButtons=true;F.db.settings.minimapIconOverrides={}
 local btn=CreateFrame('Button','LibDBIcon11_OrdinaryAddon',Minimap);btn:Show()
 F:Scan();F:ApplyMinimapButtonPolicy();equal(btn:IsShown(),false)
 F.page='Addons';F:Render();local p=F.pageCache.Addons;p.scope='all';p.search:SetText('OrdinaryAddon');p.offset=0;F:UpdateAddonRows(p)
 local row=p.rows[1];equal(row.id,'OrdinaryAddon');equal(row.minimap.enabled,true);equal(row.minimap:GetValue(),false)
 row.minimap.scripts.OnClick();equal(F:GetAddonMinimapIconVisible('OrdinaryAddon'),true);equal(btn:IsShown(),true)
 row.minimap.scripts.OnClick();equal(F:GetAddonMinimapIconVisible('OrdinaryAddon'),false);equal(btn:IsShown(),false)
 F:SetAddonMinimapIconVisible('OrdinaryAddon',nil);p.search:SetText('')
end)
test('Minimap icon manager opens and reuses widgets',function()
 local before=#frames;F:OpenMinimapIconManager();assert(F.iconManager:IsShown());local built=#frames
 F:RefreshIconManager();F:RefreshIconManager();equal(#frames,built);F.iconManager:Hide();assert(built>=before)
end)
test('Legacy API enable-state parameter order',function()
 local modern=C_AddOns;C_AddOns=nil
 GetAddOnEnableState=function(character,id) assert(character=='TestCharacter');return get(id).enabled and 2 or 0 end
 equal(F.A.Enabled('ForeverCore'),true);C_AddOns=modern
end)
test('Search, favorites and paging do not expose stale rows',function()
 F.page='Addons';F:Render();local p=F.pageCache.Addons;p.scope='all';F:UpdateAddonRows(p)
 p.offset=5;F:UpdateAddonRows(p);assert(p.rows[1]:IsShown());assert(not p.rows[4]:IsShown())
 p.search:SetText('no-such-addon');equal(#p.filtered,0);assert(not p.rows[1]:IsShown())
 p.search:SetText('');p.scope='suite';p.offset=0;F:UpdateAddonRows(p)
end)
-- Export actual widget tree for layout preview, not a hand-authored mockup.
local function esc(s) return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
local function json(x)
 if type(x)=='string' then return esc(x) elseif type(x)=='number' or type(x)=='boolean' then return tostring(x) elseif type(x)=='nil' then return 'null' end
 local out={};local n=0;for k,v in pairs(x) do n=n+1 end
 if n==#x and n>0 then for _,v in ipairs(x) do out[#out+1]=json(v) end;return '['..table.concat(out,',')..']' end
 for k,v in pairs(x) do out[#out+1]=esc(tostring(k))..':'..json(v) end;return '{'..table.concat(out,',')..'}'
end
F.db.profiles={};F:SaveProfile('Hardcore','suite');F:SaveProfile('Gathering','suite');F.char.profile='Hardcore';F.char.reload=nil;F.pending={};get('ForeverBags').enabled=true
-- Do not present test-only fake modules in screenshots.
while #data>4 do table.remove(data) end
F.modules.ForeverChat={title='ForeverChat',icon=4,description='Chat companion',open=function() end}
for _,page in ipairs({'Sanctum','Addons','Profiles','Diagnostics','Appearance','About'}) do
 F.page=page;F:Render()
 local out={}
 for _,f in ipairs(frames) do
  local o={};for _,k in ipairs({'id','kind','name','shown','w','h','scale','level','bg','border','text','color','texture','texcoord','layer','fontsize','justify','maxlines','colorTexture'}) do if type(f[k])=="string" or type(f[k])=="number" or type(f[k])=="boolean" or (type(f[k])=="table" and type(f[k][1])=="number") then o[k]=f[k] end end; o.id=f.uid
  o.parent=f.parent and f.parent.uid or nil;o.all=f.all and f.all.uid or nil;o.points={}
  for _,p in ipairs(f.points) do o.points[#o.points+1]={point=p.point,rel=p.rel and p.rel.uid or nil,rp=p.rp,x=p.x,y=p.y} end
  out[#out+1]=o
 end
 local file=assert(io.open('DeveloperTools/Tests/'..page..'.json','w'));file:write(json(out));file:close()
end
print('TOTAL '..tests..' tests passed. Lua '.._VERSION..'. Game client validation remains required.')
