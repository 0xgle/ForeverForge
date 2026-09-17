import json,re,sys
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
S=2
fontpath='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def font(n):return ImageFont.truetype(fontpath,max(1,int(n*S)))
def plain(s):return re.sub(r'\|c[0-9a-fA-F]{8}|\|r','',re.sub(r'\|H.*?\|h(.*?)\|h',r'\1',s))
for page in ['chat','settings','compact']:
 data=json.loads(Path('qa/'+page+'.json').read_text());nodes={n['id']:n for n in data};cache={};busy=set()
 def rect(i):
  if i in cache:return cache[i]
  n=nodes[i]
  if n.get('name')=='UIParent':return (0,0,1440,900)
  if n.get('name')=='ForeverChatFrame':return (0,0,1000,650)
  if i in busy:return (0,0,n.get('w',0),n.get('h',0))
  busy.add(i)
  if n.get('all'): r=rect(n['all'])
  else:
   w=n.get('w',0);h=n.get('h',0)
   if n['kind']=='FontString':
    fs=n.get('fontsize',12);w=w or font(fs).getlength(plain(n.get('text','')))/S;h=h or fs*1.3
   xs=[];ys=[]
   def factors(p):return (0 if 'LEFT' in p else 1 if 'RIGHT' in p else .5,0 if 'TOP' in p else 1 if 'BOTTOM' in p else .5)
   for p in n.get('points',[]):
    rr=rect(p.get('rel') or n['parent']);a,b=factors(p['point']);c,d=factors(p['rp'])
    xs.append((a,rr[0]+c*rr[2]+p['x']));ys.append((b,rr[1]+d*rr[3]-p['y']))
   def solve(items,size):
    if not items:return 0,size
    for a,v in items:
     for b,u in items:
      if abs(b-a)>.01:return v-a*((u-v)/(b-a)),(u-v)/(b-a)
    return items[0][1]-items[0][0]*size,size
   x,w=solve(xs,w);y,h=solve(ys,h);r=(x,y,w,h)
  busy.remove(i);cache[i]=r;return r
 def visible(n):return n.get('shown',True) and (not n.get('parent') or visible(nodes[n['parent']]))
 def inside(n):
  if n.get('name')=='ForeverChatFrame':return True
  return bool(n.get('parent') and inside(nodes[n['parent']]))
 canvas=Image.new('RGBA',(1000*S,650*S),(6,9,10,255))
 def rgba(c,alpha=1):return tuple(round(255*min(1,max(0,x))) for x in c[:3])+(round(255*(c[3] if len(c)>3 else 1)*alpha),)
 layers={'BACKGROUND':0,'BORDER':1,'ARTWORK':2,'OVERLAY':3}
 order=sorted(data,key=lambda n:(n.get('level',0) if n['kind'] not in ('Texture','FontString') else nodes[n['parent']].get('level',0),layers.get(n.get('layer'),0),n['id']))
 for n in order:
  if not inside(n) or not visible(n):continue
  x,y,w,h=rect(n['id']);x=round(x*S);y=round(y*S);w=round(w*S);h=round(h*S)
  if w<=0 or h<=0:continue
  if n['kind']=='Texture':
   if n.get('texture'):
    p=Path('build/ForeverChat/Media')/(n['texture'].split('\\')[-1]+'.tga')
    im=Image.open(p).convert('RGBA');co=n.get('texcoord',[0,1,0,1]);im=im.crop((co[0]*im.width,co[2]*im.height,co[1]*im.width,co[3]*im.height)).resize((w,h),Image.Resampling.LANCZOS)
    if n.get('alpha') is not None:im.putalpha(round(255*n['alpha']))
   else:im=Image.new('RGBA',(w,h),rgba(n.get('colorTexture',[0,0,0,0]),n.get('alpha',1)))
   canvas.alpha_composite(im,(x,y))
  if n['kind']=='FontString' and n.get('text'):
   im=Image.new('RGBA',(w,h));draw=ImageDraw.Draw(im);f=font(n.get('fontsize',12));s=plain(n['text']);tw=draw.textlength(s,font=f)
   tx=(w-tw)/2 if n.get('justify')=='CENTER' else w-tw if n.get('justify')=='RIGHT' else 0
   draw.text((tx,h/2),s,font=f,fill=rgba(n.get('color',[1,1,1,1])),anchor='lm');canvas.alpha_composite(im,(x,y))
  if n['kind']=='ScrollingMessageFrame':
   im=Image.new('RGBA',(w,h));draw=ImageDraw.Draw(im);f=font(n.get('fontsize',13));yy=0
   for s in n.get('messages',[]):
    s=plain(s);line=''
    for word in s.split(' '):
     if draw.textlength(line+word,font=f)>w and line:
      draw.text((0,yy),line,font=f,fill=(216,225,221),anchor='lt');yy+=18*S;line=''
     line+=word+' '
    draw.text((0,yy),line,font=f,fill=(216,225,221),anchor='lt');yy+=(n.get('fontsize',13)+n.get('spacing',3)+3)*S
   canvas.alpha_composite(im,(x,y))
 canvas.convert('RGB').save('qa/'+page+'.png')
 print(page,'rendered',len(data),'regions')
