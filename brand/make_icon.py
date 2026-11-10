# -*- coding: utf-8 -*-
"""Genera l'icona MTDesk (monogramma MT, gradiente brand, dark glass) -> PNG + ICO."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

OUT = os.path.join(os.path.dirname(__file__), "icons")
os.makedirs(OUT, exist_ok=True)
S = 1024
FONT_PATH = r"C:\Windows\Fonts\segoeuib.ttf"

# --- Palette brand (marketingtools.digital) ---
BRAND_STOPS = [(0x2E,0xCC,0x71),(0x00,0xBC,0xD4),(0x21,0x96,0xF3),(0x9C,0x27,0xB0),(0xFF,0x98,0x00)]
BG_TOP    = (0x14,0x14,0x24)
BG_BOTTOM = (0x08,0x08,0x16)
CYAN      = (0x00,0xBC,0xD4)
PURPLE    = (0x9C,0x27,0xB0)

def lerp(a,b,t): return tuple(int(round(a[i]+(b[i]-a[i])*t)) for i in range(3))

def multistop_row(width, stops):
    row=[]
    n=len(stops)-1
    for x in range(width):
        p=x/(width-1)*n
        i=min(int(p),n-1)
        row.append(lerp(stops[i],stops[i+1],p-i))
    return row

def diagonal_gradient(size, stops):
    """Gradiente 135deg (alto-sx -> basso-dx) su canvas size x size."""
    D=int(math.ceil(size*math.sqrt(2)))+2
    row=multistop_row(D,stops)
    base=Image.new("RGB",(D,D))
    px=base.load()
    for x in range(D):
        c=row[x]
        for y in range(D):
            px[x,y]=c
    rot=base.rotate(-45,expand=True,resample=Image.BICUBIC)
    w,h=rot.size
    left=(w-size)//2; top=(h-size)//2
    return rot.crop((left,top,left+size,top+size))

def vgradient(size, top, bottom):
    img=Image.new("RGB",(size,size))
    px=img.load()
    for y in range(size):
        c=lerp(top,bottom,y/(size-1))
        for x in range(size):
            px[x,y]=c
    return img

def rounded_mask(size, radius):
    m=Image.new("L",(size,size),0)
    d=ImageDraw.Draw(m)
    d.rounded_rectangle([0,0,size-1,size-1],radius=radius,fill=255)
    return m

# --- Sfondo dark glass arrotondato ---
bg=vgradient(S,BG_TOP,BG_BOTTOM).convert("RGBA")
# glow radiale d'angolo (ciano alto-sx, viola basso-dx)
def radial_glow(size,center,color,rad,alpha):
    g=Image.new("RGBA",(size,size),(0,0,0,0))
    px=g.load()
    cx,cy=center
    for y in range(size):
        for x in range(size):
            d=math.hypot(x-cx,y-cy)
            if d<rad:
                a=int(alpha*(1-d/rad)**2)
                px[x,y]=(color[0],color[1],color[2],a)
    return g
bg=Image.alpha_composite(bg,radial_glow(S,(S*0.12,S*0.12),CYAN,S*0.75,70))
bg=Image.alpha_composite(bg,radial_glow(S,(S*0.9,S*0.92),PURPLE,S*0.7,60))

radius=int(S*0.225)
mask=rounded_mask(S,radius)

# bordo glass sottile
bd=ImageDraw.Draw(bg)
bd.rounded_rectangle([6,6,S-7,S-7],radius=radius-4,outline=(255,255,255,32),width=3)

# --- Monogramma MT col gradiente brand ---
grad=diagonal_gradient(S,BRAND_STOPS).convert("RGBA")
font=ImageFont.truetype(FONT_PATH,int(S*0.5))
txt="MT"
tmask=Image.new("L",(S,S),0)
td=ImageDraw.Draw(tmask)
bbox=td.textbbox((0,0),txt,font=font)
tw=bbox[2]-bbox[0]; th=bbox[3]-bbox[1]
tx=(S-tw)//2-bbox[0]; ty=(S-th)//2-bbox[1]-int(S*0.01)
td.text((tx,ty),txt,font=font,fill=255)

# glow dietro il testo (ciano)
glow=Image.new("RGBA",(S,S),(0,0,0,0))
gmask=tmask.filter(ImageFilter.GaussianBlur(28))
glow_col=Image.new("RGBA",(S,S),(0,0xBC,0xD4,255))
glow.paste(glow_col,(0,0),gmask)
bg=Image.alpha_composite(bg,Image.composite(glow,Image.new("RGBA",(S,S),(0,0,0,0)),gmask))

# testo col gradiente
text_layer=Image.new("RGBA",(S,S),(0,0,0,0))
text_layer.paste(grad,(0,0),tmask)
bg=Image.alpha_composite(bg,text_layer)

# --- Applica maschera arrotondata finale ---
icon=Image.new("RGBA",(S,S),(0,0,0,0))
icon.paste(bg,(0,0),mask)

# Export
icon.save(os.path.join(OUT,"mtdesk-1024.png"))
for sz in (512,256,128,64,48,32):
    icon.resize((sz,sz),Image.LANCZOS).save(os.path.join(OUT,f"mtdesk-{sz}.png"))
# glifo trasparente (senza bg) per overlay
glyph=Image.new("RGBA",(S,S),(0,0,0,0))
glyph.paste(grad,(0,0),tmask)
glyph.save(os.path.join(OUT,"mtdesk-glyph-1024.png"))
# ICO multi-size Windows
icon.save(os.path.join(OUT,"mtdesk.ico"),sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
print("OK icone generate in", OUT)
print(os.listdir(OUT))
