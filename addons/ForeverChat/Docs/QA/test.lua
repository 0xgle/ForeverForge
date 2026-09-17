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
function methods:SetParent(p) self.parent=p end
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
function methods:Hide() local prev=self.shown;self.shown=false;if prev and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:Show() local before=self.shown;self.shown=true;if not before and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:SetScale(s) self.scale=s end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale end
function methods:SetFrameLevel(n) self.level=n end
function methods:GetFrameLevel() return self.level end
function methods:GetCenter() return self.w/2,self.h/2 end
function methods:CreateTexture(name,layer) local x=new('Texture',name,self);x.layer=layer;return x end
function methods:CreateFontString(name,layer) local x=new('FontString',name,self);x.layer=layer;return x end
function methods:SetScrollChild(f) self.scrollchild=f;f.parent=self end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
function methods:SetEnabled(v) self.enabled=v end
function methods:SetNormalTexture(t) self.normalTexture=t end
function methods:AddMessage(msg) self.messages=self.messages or {};table.insert(self.messages,msg) end
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

function methods:UnregisterEvent(e) self.events[e]=nil end
function methods:GetPoint(i) local p=self.points[i];return p.point,p.rel,p.rp,p.x,p.y end
function methods:Clear() self.messages={};self.offset=0 end
function methods:ScrollToBottom() self.offset=0 end
function methods:ScrollToTop() self.offset=20 end
function methods:ScrollUp() self.offset=(self.offset or 0)+1 end
function methods:ScrollDown() self.offset=math.max(0,(self.offset or 0)-1) end
function methods:GetScrollOffset() return self.offset or 0 end
function methods:SetAlpha(a) self.alpha=a end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetLeft() return 30 end
function methods:GetBottom() return 80 end
function methods:SetSpacing(n) self.spacing=n end
for _,n in ipairs({'SetTextInsets','SetWordWrap','SetFading','SetHyperlinksEnabled','UpdateScrollChildRect','SetHyperlink'}) do methods[n]=function() end end
local clock=10000
function time() return clock end
function GetTime() return clock end
function IsInGuild() return false end
function IsInGroup() return false end
function IsInRaid() return false end
function GetZoneText() return 'Westfall' end
function ChatFrame_OpenChat(s) _G.openedChat=s end
local registered
ForeverCore={apiVersion=1,RegisterModule=function(_,id,spec) registered=spec end}
ChatFrame1=DEFAULT_CHAT_FRAME
ForeverChatDB={schemaVersion=2,width=980,height=520,scale=1,theme='TEAL',history={{sender='OldFriend',msg='Keep this message',isWhisper=true,t=9990}}}
assert(loadfile('build/ForeverChat/ForeverChat.lua'))('ForeverChat')
assert(loadfile('build/ForeverChat/Sanctum.lua'))('ForeverChat')
local FC=ForeverChat
FC.eventFrame.scripts.OnEvent(FC.eventFrame,'PLAYER_LOGIN')
assert(FC.initialized,FC.initError)
local tests=0
local function test(name,fn) fn();tests=tests+1;print('PASS '..name) end
local function emit(msg,who,event) FC:HandleChat(event or 'CHAT_MSG_SAY',msg,who or 'Friend','','',nil,nil,nil,1,'General',nil,nil,nil) end

test('startup and migration preserve history/theme',function()
 assert(FC.db.schemaVersion==3 and FC.db.width==1000 and FC.db.height==650)
 assert(FC.db.history[1].msg=='Keep this message' and FC.db.theme=='TEAL')
 assert(FC.frame and #FC.whisperRows==2 and #FC.lfgRows==3)
end)
test('Core settings and standalone UI',function()
 assert(registered and registered.settings)
 registered.settings();assert(FC.settingsPanel.shown and not FC.body.shown)
 FC:ToggleSettings(false);assert(FC.body.shown)
 ForeverCore=nil;FC:RegisterWithCore()
end)
test('incoming messages do not jump while reading',function()
 for i=1,30 do emit('line '..i) end
 FC.messages.scripts.OnMouseWheel(FC.messages,1)
 local last=FC.messages.messages[#FC.messages.messages]
 emit('new while paused')
 assert(FC.paused and FC.pendingMessages==1 and FC.jump.shown)
 assert(FC.messages.offset==1 and FC.messages.messages[#FC.messages.messages]==last)
 FC.jump.scripts.OnClick(FC.jump)
 assert(not FC.paused and FC.pendingMessages==0 and not FC.jump.shown)
 assert(FC.messages.messages[#FC.messages.messages]:find('new while paused',1,true))
end)
test('wheel returns to live',function()
 FC.messages.scripts.OnMouseWheel(FC.messages,1);emit('wheel test')
 FC.messages.scripts.OnMouseWheel(FC.messages,-1)
 assert(not FC.paused and FC.pendingMessages==0)
end)
test('sidebar expands message area',function()
 FC.db.compact=true;FC:ApplyAppearance();assert(not FC.rail.shown and FC.messages.points[2].x==-18)
 FC.db.compact=false;FC:ApplyAppearance();assert(FC.rail.shown and FC.messages.points[2].x==-282)
end)
test('whisper reply retains full realm name',function()
 emit('Hello','Ally-RealmOne','CHAT_MSG_WHISPER')
 emit('Hello','Ally-RealmTwo','CHAT_MSG_WHISPER')
 assert(FC.whisperRows[1].sender=='Ally-RealmTwo' and FC.whisperRows[2].sender=='Ally-RealmOne')
 FC.whisperRows[1].scripts.OnClick(FC.whisperRows[1]);assert(openedChat=='/w Ally-RealmTwo ')
end)
test('LFG fresh unique senders and expiry',function()
 emit('LFM DM need tank','Leader');emit('LFM DM need healer','Leader')
 assert(FC.lfgRows[1].sender=='Leader' and FC.lfgRows[2].sender==nil)
 clock=clock+901;FC:UpdateRail();assert(FC.lfgRows[1].sender==nil)
end)
test('search and filtered copy',function()
 FC:SetTab('WHISPERS');FC.search:SetText('Hello');FC:CopyView()
 assert(FC.copyPanel.edit.text:find('Hello',1,true))
 assert(not FC.copyPanel.edit.text:find('LFM',1,true))
 assert(not FC.copyPanel.edit.text:find('|H',1,true))
 FC.copyPanel:Hide();FC.search:SetText('');FC:SetTab('ALL')
end)
test('duplicate filter and bounded cache cleanup',function()
 local n=#FC.db.history;emit('same','Spammer');emit('same','Spammer');assert(#FC.db.history==n+1)
 clock=clock+40;emit('after cleanup','Tester');assert(FC.duplicateCache['Spammer'..string.char(31)..'same']==nil)
end)
test('hidden current tab unread and reset on show',function()
 FC:Hide();emit('hidden message');assert((FC.unread.ALL or 0)>0)
 FC:Show();assert(FC.unread.ALL==0)
end)
test('500 record history cap',function()
 FC:Hide();for i=1,550 do emit('record '..i) end;assert(#FC.db.history==500);FC:Show()
end)
test('scale fits small screen',function()
 UIParent:SetSize(960,540);FC:FitScale();assert(FC.frame.scale*650<=516.01)
 UIParent:SetSize(1440,900);FC:FitScale()
end)
test('settings reset updates controls',function()
 FC:ToggleSettings(true);FC:ToggleSettings(false);assert(not FC.settingsPanel.shown)
 FC:HandleSlash('reset');assert(FC.db.width==1000 and FC.db.height==650)
end)
-- A sample conversation solely for rendering the actual widget tree; never shipped as history.
FC.db.history={};FC.db.theme='GOLD';FC:ApplyTheme();FC.currentTab='ALL'
local samples={
 {'CHAT_MSG_GUILD','Mira','Good morning! Anyone heading to Westfall?'},
 {'CHAT_MSG_GUILD','Thorin','On my way. Bringing potions for the group.'},
 {'CHAT_MSG_PARTY','Elowen','Let us clear the patrol before we pull.'},
 {'CHAT_MSG_SAY','Glegolas','Sounds good. Slow and steady.'},
 {'CHAT_MSG_CHANNEL','Brom','LFM DM - need tank and healer. Level 20+.'},
 {'CHAT_MSG_WHISPER','Mira','Meet you at the fountain in five minutes.'},
 {'CHAT_MSG_WHISPER','Thorin','I saved a health potion for you.'},
 {'CHAT_MSG_CHANNEL','Elowen','LFG SFK healer, ready to travel.'},
 {'CHAT_MSG_CHANNEL','Arden','LFM WC need DPS for a relaxed run.'},
 {'CHAT_MSG_PARTY','Mira','Everyone ready? Stay together.'},
}
for _,r in ipairs(samples) do emit(r[3],r[2],r[1]) end
FC:Render(true);FC:UpdateRail()

local function esc(s) return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
local function json(x)
 if type(x)=='string' then return esc(x) elseif type(x)=='number' or type(x)=='boolean' then return tostring(x) elseif type(x)=='nil' then return 'null' end
 local out={};local n=0;for k,v in pairs(x) do n=n+1 end
 if n==#x and n>0 then for _,v in ipairs(x) do out[#out+1]=json(v) end;return '['..table.concat(out,',')..']' end
 for k,v in pairs(x) do out[#out+1]=esc(tostring(k))..':'..json(v) end;return '{'..table.concat(out,',')..'}'
end
local function export(page)
 local out={}
 for _,f in ipairs(frames) do
  local o={};for _,k in ipairs({'kind','name','shown','w','h','scale','level','text','color','texture','texcoord','layer','fontsize','justify','justifyV','maxlines','colorTexture','alpha','spacing','messages'}) do
   if f[k]~=nil then o[k]=f[k] end
  end
  o.id=f.uid;o.parent=f.parent and f.parent.uid or nil;o.all=f.all and f.all.uid or nil;o.points={}
  for _,p in ipairs(f.points) do o.points[#o.points+1]={point=p.point,rel=p.rel and p.rel.uid or nil,rp=p.rp,x=p.x,y=p.y} end
  out[#out+1]=o
 end
 local file=assert(io.open('qa/'..page..'.json','w'));file:write(json(out));file:close()
end
export('chat');FC:ToggleSettings(true);export('settings');FC:ToggleSettings(false)
FC.db.compact=true;FC:ApplyAppearance();export('compact')
print('TOTAL '..tests..' behavior tests passed; Lua '.._VERSION..'. Client testing still required.')
