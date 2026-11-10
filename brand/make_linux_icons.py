# -*- coding: utf-8 -*-
"""
Genera le icone che il pacchetto Linux (.deb / AppImage) installa in
/usr/share/icons/hicolor, partendo dall'icona MTDesk gia' approvata.

Cosa produce, dentro client/res/ :
    32x32.png        32 x 32    (AppImage e bundle cargo - NON entra nel .deb)
    64x64.png        64 x 64    (solo AppImage - NON entra nel .deb)
    128x128.png     128 x 128   (AppImage e bundle cargo - NON entra nel .deb)
    128x128@2x.png  256 x 256   (ENTRA nel .deb)
    scalable.svg    vettoriale  (ENTRA nel .deb)

Le due che contano per Ubuntu sono le ultime: sono le sole che il pacchetto .deb
installa davvero. Le trovi in client/build.py, funzione build_flutter_deb, dove
vengono copiate in /usr/share/icons/hicolor/... e RINOMINATE in mtdesk.png e
mtdesk.svg. Quel nome "mtdesk" non e' un dettaglio: deve combaciare con la riga
Icon=mtdesk dei file res/rustdesk.desktop e res/rustdesk-link.desktop e con il
nome cercato da flutter/linux/my_application.cc. Se i tre non coincidono, Ubuntu
non trova l'icona e mostra al suo posto un riquadro grigio generico.

Come funziona, in breve:
  - Il "master" e' client/res/icon.png, 1024x1024, cioe' la stessa identica
    immagine usata per l'icona di Windows. Si parte SEMPRE da li' e si scende
    di dimensione con il filtro LANCZOS (il piu' pulito per rimpicciolire).
    Non si ingrandisce mai un'immagine piccola: verrebbe sfocata.
  - L'SVG invece e' ridisegnato in vettoriale, cosi' resta nitido a qualsiasi
    dimensione. Il monogramma "MT" viene convertito da testo a forme
    geometriche: in questo modo l'icona si vede uguale anche sui PC Linux
    che non hanno installato il font usato per disegnarla.

Uso:  python brand/make_linux_icons.py
"""
from PIL import Image, ImageDraw, ImageFont
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                      # .../MTDESK
RES = os.path.join(ROOT, "client", "res")         # .../MTDESK/client/res
MASTER = os.path.join(RES, "icon.png")            # icona MTDesk approvata, 1024x1024
FONT_PATH = r"C:\Windows\Fonts\segoeuib.ttf"      # stesso font di make_icon.py

# Palette brand Marketing Tools (vedi BRAND-MTDESK.md)
BRAND_STOPS = ["#2ECC71", "#00BCD4", "#2196F3", "#9C27B0", "#FF9800"]
BG_TOP, BG_BOTTOM = "#141424", "#080816"
CYAN, PURPLE = "#00BCD4", "#9C27B0"

S = 1024              # lato del master
RADIUS_RATIO = 0.225  # raggio degli angoli arrotondati, come in make_icon.py
FONT_RATIO = 0.5      # altezza del font rispetto al lato, come in make_icon.py

# Le quattro PNG richieste: nome file -> lato reale in pixel.
# Attenzione: "128x128@2x.png" e' 256x256 reali (e' la convenzione "@2x").
PNG_TARGETS = {
    "32x32.png": 32,
    "64x64.png": 64,
    "128x128.png": 128,
    "128x128@2x.png": 256,
}


def make_pngs():
    """Scala il master 1024 verso il basso con LANCZOS e salva le quattro PNG."""
    src = Image.open(MASTER).convert("RGBA")
    if src.size != (S, S):
        raise SystemExit(f"Il master {MASTER} dovrebbe essere {S}x{S}, invece e' {src.size}")
    done = []
    for name, size in PNG_TARGETS.items():
        out = os.path.join(RES, name)
        src.resize((size, size), Image.LANCZOS).save(out, "PNG", optimize=True)
        done.append((out, Image.open(out).size))
    return done


def glyph_paths(rect):
    """
    Ricava il contorno vettoriale di "MT" dal font e lo restituisce come path
    SVG gia' posizionato dentro `rect` (x, y, larghezza, altezza) nello spazio
    dell'icona 1024x1024.

    Perche' convertire il testo in forme: l'SVG deve vedersi uguale anche sui
    PC Linux dove il font usato per disegnare l'icona non e' installato.

    Perche' le coordinate finali sono "cotte" dentro il path invece di usare
    un <g transform=...>: il gradiente del brand e' dichiarato in
    userSpaceOnUse, e quello si misura nel sistema di coordinate in cui sta
    l'elemento colorato. Dentro un gruppo trasformato verrebbe letto in unita'
    del font, si stringerebbe sulle lettere e le tingerebbe di verde e arancio
    invece che di ciano/blu/viola.
    """
    from fontTools.ttLib import TTFont
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.boundsPen import BoundsPen
    from fontTools.pens.transformPen import TransformPen

    font = TTFont(FONT_PATH)
    glyphset = font.getGlyphSet()
    cmap = font.getBestCmap()
    names = [cmap[ord(ch)] for ch in "MT"]

    # Crenatura (kerning): quanto avvicinare la T alla M. Se il font non la
    # dichiara restiamo a 0: le lettere saranno solo un filo piu' distanti.
    try:
        kern_x = font["kern"].kernTables[0].kernTable.get((names[0], names[1]), 0)
    except Exception:
        kern_x = 0

    # Dove parte ogni lettera lungo la riga, in unita' del font.
    advances = []
    x = 0.0
    for i, name in enumerate(names):
        advances.append(x)
        x += glyphset[name].width
        if i == 0:
            x += kern_x

    def draw_all(pen_factory, scale=1.0, ox=0.0, oy=0.0):
        pen = pen_factory()
        for name, adv in zip(names, advances):
            # y ribaltata (nei font l'asse Y sale, in SVG scende) + scala + spostamento
            glyphset[name].draw(TransformPen(
                pen, (scale, 0, 0, -scale, scale * adv + ox, oy)))
        return pen

    # Passata 1: misuro l'ingombro reale delle lettere in unita' del font.
    bounds = draw_all(lambda: BoundsPen(glyphset)).bounds
    if bounds is None:
        raise SystemExit("Non sono riuscito a leggere il contorno delle lettere dal font")
    gx0, gy0, gx1, gy1 = bounds
    gw, gh = gx1 - gx0, gy1 - gy0

    # Quanto rimpicciolire e dove spostare, per far coincidere quell'ingombro
    # con il rettangolo che le lettere occupano nella PNG.
    tx, ty, tw, th = rect
    k = min(tw / gw, th / gh)
    ox = tx + (tw - gw * k) / 2 - gx0 * k
    oy = ty + (th - gh * k) / 2 - gy0 * k

    # Passata 2: ridisegno con la trasformazione gia' applicata alle coordinate.
    return draw_all(lambda: SVGPathPen(glyphset), scale=k, ox=ox, oy=oy).getCommands()


def target_rect():
    """
    Dove stanno davvero le lettere dentro il PNG master, in pixel.
    Rifacciamo lo stesso disegno di make_icon.py e poi misuriamo il risultato,
    invece di fidarci dei soli numeri di textbbox(): quelli comprendono anche
    i margini laterali che il font si porta dietro, e darebbero un rettangolo
    piu' largo del vero (le lettere dell'SVG verrebbero grosse e spostate).
    """
    font = ImageFont.truetype(FONT_PATH, int(S * FONT_RATIO))
    tmask = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(tmask)
    b = d.textbbox((0, 0), "MT", font=font)
    tw, th = b[2] - b[0], b[3] - b[1]
    tx = (S - tw) // 2 - b[0]
    ty = (S - th) // 2 - b[1] - int(S * 0.01)
    d.text((tx, ty), "MT", font=font, fill=255)
    x0, y0, x1, y1 = tmask.getbbox()   # rettangolo dell'inchiostro effettivo
    return (x0, y0, x1 - x0, y1 - y0)


def make_svg():
    d = glyph_paths(target_rect())
    r = int(S * RADIUS_RATIO)

    stops = "\n".join(
        f'      <stop offset="{i * 25}%" stop-color="{c}"/>'
        for i, c in enumerate(BRAND_STOPS)
    )

    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<!--
  MTDesk - icona vettoriale (hicolor/scalable).
  Generata da brand/make_linux_icons.py. Non modificare a mano:
  rigenera lo script, cosi' resta allineata alle PNG.
  Colori: palette Marketing Tools (brand/BRAND-MTDESK.md).
-->
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"
     viewBox="0 0 {S} {S}" role="img" aria-label="MTDesk">
  <title>MTDesk</title>
  <defs>
    <!-- sfondo scuro, dall'alto verso il basso -->
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="{BG_TOP}"/>
      <stop offset="100%" stop-color="{BG_BOTTOM}"/>
    </linearGradient>
    <!-- aloni d'angolo: ciano in alto a sinistra, viola in basso a destra -->
    <radialGradient id="glowC" cx="12%" cy="12%" r="75%">
      <stop offset="0%" stop-color="{CYAN}" stop-opacity="0.27"/>
      <stop offset="100%" stop-color="{CYAN}" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glowP" cx="90%" cy="92%" r="70%">
      <stop offset="0%" stop-color="{PURPLE}" stop-opacity="0.24"/>
      <stop offset="100%" stop-color="{PURPLE}" stop-opacity="0"/>
    </radialGradient>
    <!-- Gradiente firma del brand, inclinato a 135 gradi (da alto-sinistra a
         basso-destra). gradientUnits="userSpaceOnUse" e' importante: senza,
         il gradiente si schiaccerebbe sulle sole lettere e comparirebbero
         verde e arancio, mentre nell'icona vera le lettere prendono solo la
         parte centrale (ciano -> blu -> viola), come nella PNG. -->
    <linearGradient id="brand" gradientUnits="userSpaceOnUse"
                    x1="0" y1="0" x2="{S}" y2="{S}">
{stops}
    </linearGradient>
    <!-- leggero bagliore ciano dietro le lettere -->
    <filter id="soft" x="-25%" y="-25%" width="150%" height="150%">
      <feGaussianBlur stdDeviation="28"/>
    </filter>
    <!-- tutto resta dentro il quadrato con gli angoli arrotondati -->
    <clipPath id="card">
      <rect x="0" y="0" width="{S}" height="{S}" rx="{r}" ry="{r}"/>
    </clipPath>
  </defs>

  <g clip-path="url(#card)">
    <rect width="{S}" height="{S}" fill="url(#bg)"/>
    <rect width="{S}" height="{S}" fill="url(#glowC)"/>
    <rect width="{S}" height="{S}" fill="url(#glowP)"/>
    <path d="{d}" fill="{CYAN}" fill-opacity="0.55" filter="url(#soft)"/>
    <path d="{d}" fill="url(#brand)"/>
  </g>
  <!-- bordo vetro sottile -->
  <rect x="6" y="6" width="{S - 12}" height="{S - 12}" rx="{r - 4}" ry="{r - 4}"
        fill="none" stroke="#FFFFFF" stroke-opacity="0.125" stroke-width="3"/>
</svg>
'''
    out = os.path.join(RES, "scalable.svg")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(svg)
    return out


if __name__ == "__main__":
    for path, size in make_pngs():
        print(f"OK  {os.path.basename(path):<16} {size[0]}x{size[1]}")
    print(f"OK  {os.path.basename(make_svg()):<16} vettoriale")
