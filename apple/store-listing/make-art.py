# python3 make-art.py W H out.png: the App Store header or search image, a headline on the left and three iPhones on the right.
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
# Everything stays inside a safe area: the iPhone App Store crops the header's sides and puts
# the back and share buttons and the Dynamic Island over its top. The app's icon and name show
# right below the header, so the art doesn't repeat them.
wide=W/H>2
sx=round(W*(0.14 if wide else 0.1)); top=round(H*(0.2 if wide else 0.17)); bot=round(H*(0.95 if wide else 0.87))
cy=(top+bot)//2
hc=bot-top; hs=round(hc*0.89)
wc=round(hc*1320/2868); ws=round(hs*1320/2868); off=round(wc*0.8)
cx=W-sx-off-ws//2
phone('3-list.png',hs,cx-off,cy); phone('2-now-playing.png',hs,cx+off,cy); phone('1-lyrics.png',hc,cx,cy)
# Left: a headline and a line under it, vertically centred in the safe area.
left=sx; textw=cx-off-ws//2-left-round(W*0.03)
tf='apple/A2N Hymnal/Fonts/ClashGrotesk-Semibold.ttf'
heads=['Over 120','classic hymns']
lines=['Lyrics and a recording for each.','Works anywhere, even offline.']
ts=round(H*(0.13 if wide else 0.1))
while max(ImageFont.truetype(tf,ts).getlength(h) for h in heads)>textw: ts-=4
title=ImageFont.truetype(tf,ts)
body=ImageFont.truetype('/System/Library/Fonts/SFNS.ttf',round(ts*0.32))
assert max(body.getlength(l) for l in lines)<=textw, 'text runs into the phones'
hl=round(ts*1.0); lh=round(body.size*1.45); gap=round(ts*0.35)
total=hl*len(heads)+gap+lh*len(lines)
y=cy-total//2
dr=ImageDraw.Draw(bg)
for h in heads: dr.text((left,y),h,font=title,fill=INK); y+=hl
y+=gap
for l in lines: dr.text((left,y),l,font=body,fill=MUTED); y+=lh
bg.convert('RGB').save(out)
