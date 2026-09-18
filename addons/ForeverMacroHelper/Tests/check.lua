local root=(arg and arg[1]) or './'
if root:sub(-1)~='/' then root=root..'/' end
local F={};local errors={};local frames={};local combat=false;local cls='WARRIOR';local locale='enUS';local account={};local char={}
local function fail(m) error(m,2) end
local function check(v,m) if not v then fail(m) end end
local methods={}
local mt={__index=function(t,k) if methods[k] then return methods[k] end;return nil end}
local function widget(kind,name,parent)
 local w=setmetatable({kind=kind,name=name,parent=parent,scripts={},shown=true,width=400,height=200,text='',enabled=true},mt)
 frames[#frames+1]=w;if name then _G[name]=w end;return w
end
for _,k in ipairs({'SetPoint','ClearAllPoints','SetAllPoints','SetFrameStrata','SetClampedToScreen','SetMovable','EnableMouse','RegisterForDrag','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetFontObject','SetTextInsets','SetAutoFocus','SetJustifyH','SetJustifyV','SetTextColor','SetTexture','SetTexCoord','SetMultiLine','SetCursorPosition','ClearFocus','StartMoving','StopMovingOrSizing','RegisterForClicks','SetOwner','AddLine','SetAlpha','SetScale','RegisterEvent','SetNormalTexture','SetHighlightTexture','SetWordWrap'}) do methods[k]=function()end end
function methods:SetSize(w,h)self.width=w;self.height=h end
function methods:SetWidth(w)self.width=w end
function methods:SetHeight(h)self.height=h end
function methods:GetWidth()return self.width end
function methods:GetHeight()return self.height end
function methods:SetScript(k,f)self.scripts[k]=f end
function methods:GetScript(k)return self.scripts[k]end
function methods:CreateTexture()return widget('Texture',nil,self)end
function methods:CreateFontString()return widget('FontString',nil,self)end
function methods:SetText(s)self.text=tostring(s or '');if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false)end end
function methods:GetText()return self.text end
function methods:SetShown(v)if v then self:Show()else self:Hide()end end
function methods:Show()local before=self.shown;self.shown=true;if not before and self.scripts.OnShow then self.scripts.OnShow(self)end end
function methods:Hide()local before=self.shown;self.shown=false;if before and self.scripts.OnHide then self.scripts.OnHide(self)end end
function methods:IsShown()return self.shown end
function methods:SetEnabled(v)self.enabled=v end
function methods:Enable()self.enabled=true end
function methods:Disable()self.enabled=false end
function methods:SetFrameLevel(n)self.level=n end
function methods:GetFrameLevel()return self.level or 1 end
function methods:GetPoint()return 'CENTER',UIParent,'CENTER',0,0 end
function methods:GetCenter()return 0,0 end
function methods:GetEffectiveScale()return 1 end
function methods:SetScrollChild(c)self.child=c end
function methods:SetVerticalScroll(n)self.scroll=n end
function methods:GetVerticalScroll()return self.scroll or 0 end
function methods:AddMessage(s)if s:find('attempt to') then errors[#errors+1]=s end end
CreateFrame=widget;UIParent=widget('Frame');UIParent:SetSize(1920,1080);Minimap=widget('Frame');GameTooltip=widget('Frame');DEFAULT_CHAT_FRAME=widget('Frame');UISpecialFrames={};SlashCmdList={};BackdropTemplateMixin={};C_Timer={After=function(_,fn)fn()end};unpack=table.unpack
WOW_PROJECT_ID=2;WOW_PROJECT_CLASSIC=2;MAX_ACCOUNT_MACROS=120;MAX_CHARACTER_MACROS=18
function UnitName()return 'Tester'end
function GetRealmName()return 'Test Realm'end
function UnitClass()return cls,cls end
function InCombatLockdown()return combat end
function GetLocale()return locale end
function GetNumMacros()return #account,#char end
function GetMacroInfo(i)local v=i>120 and char[i-120]or account[i];if v then return v.name,v.icon,v.body end end
local function sortChar()table.sort(char,function(a,b)return a.name<b.name end)end
function CreateMacro(name,icon,body,perCharacter)
 check(not combat,'Protected create during combat');check(perCharacter==true,'Unexpected account write');if #char>=18 then error('full')end
 char[#char+1]={name=name,icon=icon,body=body};sortChar();for i,m in ipairs(char)do if m.name==name then return i+120 end end
end
function EditMacro(i,name,icon,body)
 check(not combat,'Protected edit during combat');check(i>120,'Unexpected account edit')
 local m=char[i-120];m.name=name or m.name;m.icon=icon or m.icon;m.body=body or m.body;sortChar();return i
end
function DeleteMacro(i)check(not combat,'Protected delete during combat');check(i>120,'Unexpected account delete');table.remove(char,i-120)end
function PickupMacro(i)check(not combat,'Protected pickup during combat');check(i>120,'Wrong macro pickup')end
for line in io.lines(root..'ForeverMacroHelper.toc')do
 if line:match('%.lua$')then local path=line:gsub('\\','/');local fn,err=loadfile(root..path);check(fn,err);fn('ForeverMacroHelper',F)end
end
F:Fire('BOOT');F:Fire('LOGIN');check(#errors==0,table.concat(errors,'\n'));check(F.frame and not F.frame:IsShown(),'Window must start hidden');check(F.selectedMacro,'Initial selection missing')
local E=F.Engine;local count=0;local names={};local ids={};local classCounts={};local coverage={}
for _,m in ipairs(F.Macros)do
 check(not ids[m.id],'Duplicate id '..m.id);ids[m.id]=true;check(not names[m.macroName],'Duplicate macro name '..m.macroName);names[m.macroName]=true
 check(#m.macroName<=16,'Long name '..m.macroName);check(#m.body<=255,'Long body '..m.id);check(#m.body>0,'Empty body')
 check(not m.body:find('@focus',1,true),'Unsupported focus template');check(not m.body:find('/run',1,true),'Unexpected script macro')
 classCounts[m.class]=(classCounts[m.class]or 0)+1;coverage[m.class]=coverage[m.class]or{};coverage[m.class][m.mode]=true;count=count+1
end
check(count==214,'Count mismatch')
for class,c in pairs(classCounts)do check(coverage[class].BOTH or (coverage[class].PVP and coverage[class].PVE),'Missing mode coverage '..class);print(class,c)end
local m=F.MacroByID.war_charge
account={{name=m.macroName,body='personal account macro',icon=1}}
local ok,msg=E:Install(m);check(ok,msg);check(#char==1,'Create count');check(account[1].body=='personal account macro','Account overwritten')
check(E:Install(m),'Repeat update');check(#char==1,'Duplicate created');check(E:IsOwned(m),'Missing ownership')
check(E:Install(m,m.body..'\n/stopcasting'),'Custom body save');check(E:Draft(m):find('/stopcasting',1,true),'Custom body not loaded')
local idx=E:GetIndex(m);char[idx-120].body='manual edit outside addon'
check(not E:Install(m),'External edit overwritten');check(not E:Delete(m),'External edit deleted')
char={};E:Records().installed={};char[1]={name=m.macroName,body='unrelated same-name macro'}
check(not E:Install(m),'Unowned name collision overwritten')
char={};E:Records().installed={}
combat=true;check(not E:Install(m),'Combat create');check(not E:Delete(m),'Combat delete');F:Fire('COMBAT_CHANGED');check(not F.createButton.enabled,'Create button in combat');combat=false
locale='deDE';check(not E:Install(m),'Non-English client should not silently receive broken names');locale='enUS'
cls='MAGE';check(not E:Install(m),'Cross-class install');cls='WARRIOR'
check(not E:Install(m,''),'Empty body accepted');check(not E:Install(m,string.rep('x',256)),'Oversized body accepted')
for i=1,18 do char[i]={name='Custom'..i,body='/say keep '..i}end
check(not E:Install(m),'Full slots');local done,total,err=E:InstallPack('PVE');check(done==0 and err,'Pack partial on full slots')
char={};E:Records().installed={};check(E:Install(m),'Initial create');local body=m.body..'\n/stopcasting';check(E:Install(m,body),'Edited install')
done,total,err=E:InstallPack('PVE');check(not err,err);local _,saved=E:IsInstalled(m);check(saved==body,'Pack overwrote customized macro')
local _,before=E:IsInstalled(m);check(not E:Delete(m,'wrong snapshot'),'Delete ignored snapshot');check(E:Delete(m,before),'Owned delete failed')
-- API silent-failure handling.
char={};local oldCreate=CreateMacro;CreateMacro=function()return nil end;check(not E:Install(m),'Silent API failure reported success');CreateMacro=oldCreate
-- Legacy migration compares exact bodies and stays character-scoped.
cls='DRUID';local legacy=F.MacroByID.dru_decurse;char={{name=legacy.legacyName,body=legacy.legacyBody or legacy.body}};check(E:Install(legacy),'Legacy name adoption');check(#char==1,'Legacy duplicated');check(char[1].name==legacy.macroName,'Legacy name not migrated')
-- Every class / mode pack fits empty slots, and all details and filtering can render.
for class in pairs(classCounts)do if class~='GENERAL'then cls=class;char={};for _,mode in ipairs({'ALL','PVE','PVP'})do check(#E:GetPack(mode)<=18,'Pack over capacity '..class..mode)end end end
cls='WARRIOR';char={};F:Toggle();check(F.frame:IsShown(),'Slash toggle open');F:Toggle();check(not F.frame:IsShown(),'Slash toggle close')
for _,m2 in ipairs(F.Macros)do F:SelectMacro(m2);check(F.editor:GetText()~='','Blank editor')end
F.selectedClass='ALL';F.selectedCategory='ALL';F.selectedMode='ALL';F.searchText='impossible-no-match-123';F:Refresh();check(#F.filtered==0,'Search should be empty')
F.searchText='';F.onlyFavorites=true;F:Refresh();check(#F.filtered==0,'Favorite filter');F:ToggleFavorite(m.id);F:Refresh();check(#F.filtered==1,'Favorite filter count')
F:Confirm('Test','Preview',function()end);check(F.confirmPanel:IsShown(),'Confirmation missing')
check(#errors==0,table.concat(errors,'\n'))
print('PASS: 214 templates, syntax/load, UI lifecycle, all detail selections, filters, ownership, account isolation, external edits, combat, locale, capacity, pack preservation, delete snapshots and legacy migration.')
