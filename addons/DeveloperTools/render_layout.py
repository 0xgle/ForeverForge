"""Developer layout simulation; not a World of Warcraft client screenshot."""
import json, re, pathlib
from PIL import Image, ImageDraw, ImageFont
ROOT=pathlib.Path('build/ForeverMarket')
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def render(source):
 nodes=json.loads(source.read_text()); idx={n['id']:n for n in nodes}; cache={}
 def box(n):
  if n['id'] in cache:return cache[n['id']]
  if n['name']=='UIParent':b=(0,0,n['w'],n['h'])
  elif n['all']:b=box(idx[n['all']])
  else:
   parent=box(idx[n['relative']]) if n['relative'] else (0,0,1600,1000)
   w=n['w'];h=n['h']
   if n['kind']=='FontString':
    h=h or n['fontSize']*1.35
    w=w or ImageFont.truetype(FONT,n['fontSize']).getlength(re.sub(r'\|c[0-9a-fA-F]{8}|\|r','',n['text']))
   def anchor(point):return (0 if 'LEFT' in point else 1 if 'RIGHT' in point else .5,0 if 'TOP' in point else 1 if 'BOTTOM' in point else .5)
   a=anchor(n['point']);r=anchor(n['relPoint']);b=(parent[0]+parent[2]*r[0]+n['x']-w*a[0],parent[1]+parent[3]*r[1]-n['y']-h*a[1],w,h)
  cache[n['id']]=b;return b
 im=Image.new('RGBA',(1600,1000),(14,19,23,255));d=ImageDraw.Draw(im)
 def color(v,default=(220,230,225,255)):return tuple(int(max(0,min(1,x))*255) for x in (v if len(v)==4 else v+[1])) if v else default
 for n in nodes:
  if not n['visible'] or n['name'] in ['UIParent','AuctionFrame']:continue
  x,y,w,h=box(n)
  if not w or not h:continue
  if n['bg']:
   layer=Image.new('RGBA',im.size);ld=ImageDraw.Draw(layer);ld.rectangle((x,y,x+w,y+h),fill=color(n['bg']),outline=color(n['border']) if n['border'] else None);im=Image.alpha_composite(im,layer);d=ImageDraw.Draw(im)
  if n['texture']:
   file=ROOT/n['texture'].replace('Interface\\AddOns\\ForeverMarket\\','').replace('\\','/')
   if file.is_file():
    a=Image.open(file).convert('RGBA').resize((max(1,round(w)),max(1,round(h))),Image.Resampling.LANCZOS);im.alpha_composite(a,(round(x),round(y)));d=ImageDraw.Draw(im)
   elif n['texture']=='icon':d.rounded_rectangle((x,y,x+w,y+h),4,fill=(46,99,59),outline=(141,161,100));d.text((x+6,y+4),'P',font=ImageFont.truetype(FONT,17),fill='white')
  if n['text'] and n['kind'] != 'EditBox':
   text=re.sub(r'\|c[0-9a-fA-F]{8}|\|r','',n['text']);font=ImageFont.truetype(FONT,n['fontSize']);lines=[]
   for line in text.split('\n'):
    if n['wrap']:
     current=''
     for word in line.split():
      candidate=(current+' '+word).strip()
      if font.getlength(candidate)>w and current:lines.append(current);current=word
      else:current=candidate
     lines.append(current)
    else:
     while font.getlength(line)>w and line:line=line[:-1]
     lines.append(line)
   for i,line in enumerate(lines):
    xx=x+(w-font.getlength(line))/2 if n['justify']=='CENTER' else x+w-font.getlength(line) if n['justify']=='RIGHT' else x
    d.text((xx,y+i*n['fontSize']*1.3),line,font=font,fill=color(n['color']))
  if n['kind']=='EditBox':
   d.text((x+8,y+7),n['text'],font=ImageFont.truetype(FONT,12),fill=(214,229,225))
 frame=next(n for n in nodes if n['name']=='ForeverMarketFrame');x,y,w,h=box(frame)
 im=im.crop((int(x),int(y),int(x+w),int(y+h))).convert('RGB');out=source.with_suffix('.png');im.save(out);print(out)
for source in pathlib.Path('build/DeveloperTools').glob('layout-*.json'):render(source)
