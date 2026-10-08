# python3 art.py W H out.png : the App Store header / search image, icon and name on the left, three iPhones on the right.
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont
W,H,out=int(sys.argv[1]),int(sys.argv[2]),sys.argv[3]
d='apple/store-listing/iphone-6.9/'
INK=(31,27,23); MUTED=(105,96,86)
stops=[(0.0,(243,241,238)),(0.4,(243,241,238)),(0.62,(236,206,150)),(0.84,(222,158,40)),(1.0,(150,80,10))]
grad=Image.new('RGB',(W,1))
for x in range(W):
    t=x/(W-1)
    for (a,ca),(b,cb) in zip(stops,stops[1:]):
        if a<=t<=b:
            f=(t-a)/(b-a); grad.putpixel((x,0),tuple(round(p+(q-p)*f) for p,q in zip(ca,cb))); break
bg=grad.resize((W,H)).convert('RGBA')
def shadowed(im,m,x,y,blur,off,op):
    sh=Image.new('RGBA',bg.size,(0,0,0,0)); sm=Image.new('L',bg.size,0); sm.paste(m.point(lambda v:int(v*op)),(x,y+off))
    sh.putalpha(sm.filter(ImageFilter.GaussianBlur(blur))); bg.alpha_composite(sh); bg.alpha_composite(im,(x,y))
def rounded(im,r):
    m=Image.new('L',im.size,0); ImageDraw.Draw(m).rounded_rectangle((0,0,im.width-1,im.height-1),radius=r,fill=255); im.putalpha(m); return im,m
def phone(name,h,cx,cy):
    im=Image.open(d+name).convert('RGBA'); w=round(im.width*h/im.height); im=im.resize((w,h),Image.LANCZOS)
    im,m=rounded(im,round(w*0.12)); shadowed(im,m,cx-w//2,cy-h//2,H*0.025,round(H*0.015),0.35)
    return w
# Phones: centre one larger, all fully inside the frame.
hc=round(H*(0.86 if W/H>2 else 0.74)); hs=round(hc*0.89)
wc=round(hc*1320/2868); ws=round(hs*1320/2868); off=round(wc*0.8)
margin=round(H*0.07); cx=W-margin-off-ws//2
phone('3-list.png',hs,cx-off,H//2); phone('2-now-playing.png',hs,cx+off,H//2); phone('1-lyrics.png',hc,cx,H//2)
# Left: icon, name, tagline, vertically centred.
left=round(W*0.065); textw=cx-off-ws//2-left
isz=round(H*(0.17 if W/H>2 else 0.13))
ic=Image.open('apple/A2N Hymnal/Assets.xcassets/AppIconImage.imageset/AppIconImage-light.png').convert('RGBA').resize((isz,isz),Image.LANCZOS)
ic,im_=rounded(ic,round(isz*0.225))
tf='apple/A2N Hymnal/Fonts/ClashGrotesk-Semibold.ttf'; ts=round(isz*0.62)
while ImageFont.truetype(tf,ts).getlength('A2N Hymnal')>textw*0.85: ts-=4
title=ImageFont.truetype(tf,ts)
body=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf',round(isz*0.2))
lines=['Over 120 classic hymns, with lyrics','and a recording for each.','English and Chinese. Works offline.']
lh=round(body.size*1.45); gap1=round(isz*0.28); gap2=round(isz*0.22)
th=title.getbbox('A2N Hymnal')[3]
total=isz+gap1+th+gap2+lh*len(lines)
y=(H-total)//2
shadowed(ic,im_,left,y,H*0.012,round(H*0.006),0.25)
dr=ImageDraw.Draw(bg); y+=isz+gap1
dr.text((left,y),'A2N Hymnal',font=title,fill=INK); y+=th+gap2
for l in lines: dr.text((left,y),l,font=body,fill=MUTED); y+=lh
assert max(dr.textlength(l,font=body) for l in lines)<textw, 'text runs into the phones'
bg.convert('RGB').save(out)
