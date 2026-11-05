import json,math,sys
spot=sys.argv[1] if len(sys.argv)>1 else "center"
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path('changgeng');data=json.loads(Path('/tmp/v27-'+spot+'-commands.json').read_text());img=Image.new('RGBA',(1280,800),(30,48,40,255));cx,cy=data['camera'];fonts={}
def font(size):
 size=max(9,int(size))
 if size not in fonts:fonts[size]=ImageFont.truetype(str(root/'assets/font.otf'),size)
 return fonts[size]
def rgba(s):return tuple(bytes.fromhex(s if len(s)==8 else s+'ff'))
cache={}
def pt(p,tr,world):
 x,y=p;tx,ty,a,sx,sy=tr;x*=sx;y*=sy
 return (round(tx+x*math.cos(a)-y*math.sin(a)-(cx if world else 0)),round(ty+x*math.sin(a)+y*math.cos(a)-(cy if world else 0)))
def paint(c,world=True):
 draw=ImageDraw.Draw(img);tr=c.get('transform',[0,0,0,1,1]);kind=c['kind'];col=rgba(c.get('color','ffffffff'))
 if kind in ['rect','card','ellipse','texture','label','icon']:
  x,y,w,h=c['rect'];a=pt((x,y),tr,world);b=pt((x+w,y+h),tr,world);box=[a[0],a[1],max(a[0]+1,b[0]),max(a[1]+1,b[1])]
  if kind=='card':
   draw.rounded_rectangle(box,radius=round(c.get('radius',8)*tr[3]),fill=col,outline=rgba(c['border']),width=3)
   for ox in [box[0]+8,box[2]-8]:
    for oy in [box[1]+8,box[3]-8]:draw.rectangle((ox-1,oy-1,ox+2,oy+2),fill=(214,188,120))
  elif kind=='ellipse':draw.ellipse(box,fill=col)
  elif kind=='rect':draw.rectangle(box,fill=col if c.get('filled',True) else None,outline=None if c.get('filled',True) else col,width=max(1,round(c.get('width',1)*tr[3])))
  elif kind=='label':
   text=c['text'];ypos=box[1]+2
   for line in text.splitlines():
    buf=''
    for char in line:
     if draw.textlength(buf+char,font=font(c['size']))>max(20,w-8):draw.text((box[0]+4,ypos),buf,font=font(c['size']),fill=col);ypos+=c['size']+5;buf=''
     buf+=char
    draw.text((box[0]+4,ypos),buf,font=font(c['size']),fill=col);ypos+=c['size']+5
  else:
   filename=c.get('file','items_v26.png')
   if filename not in cache:cache[filename]=Image.open(root/'assets/art'/filename).convert('RGBA')
   src=cache[filename]
   if kind=='icon':idx=c['index'];x0=round(idx%8*src.width/8);y0=round(idx//8*src.height/8);r=(x0,y0,round((idx%8+1)*src.width/8),round((idx//8+1)*src.height/8))
   else:rx,ry,rw,rh=c['region'];r=(round(rx),round(ry),round(rx+rw),round(ry+rh))
   icon=src.crop(r).resize((max(1,round(w*tr[3])),max(1,round(h*tr[4]))),Image.Resampling.NEAREST)
   img.alpha_composite(icon,(a[0],a[1]))
 elif kind=='line':draw.line([pt(c['a'],tr,world),pt(c['b'],tr,world)],fill=col,width=max(1,round(c['width']*tr[3])))
 elif kind=='circle':
  x,y=pt(c['at'],tr,world);r=c['r']*tr[3];draw.ellipse((x-r,y-r,x+r,y+r),fill=col)
 elif kind=='text':
  x,y=pt(c['at'],tr,world);draw.text((x,y-c['size']*tr[4]),c['text'],font=font(c['size']*tr[4]),fill=col)
for c in data['commands']:paint(c)
Path('changgeng/previews').mkdir(exist_ok=True)
img.convert('RGB').save('changgeng/previews/v27-'+spot+'-world.png')
for c in data['ui']:paint(c,False)
img.convert('RGB').save('changgeng/previews/v27-'+spot+'-ui.png')
print('rendered',len(data['commands']))
