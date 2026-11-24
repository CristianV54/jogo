# Desenha a PLANTA do mapa novo (ilha de 3 x 3 km, reino no centro), para aprovar no papel antes de construir no jogo.
# É só um desenho de planejamento: os lugares e as posições estão na lista LUGARES abaixo (x = leste, z = sul, em metros,
# com o centro do reino em 0, 0). Mudou a planta? Mude a lista e rode de novo.
#   python3 tools/planta_do_mapa.py docs/mapa-novo/PLANTA_v1.png
import sys, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SAIDA = sys.argv[1]
LADO_M = 3300.0          # metros mostrados (a ilha tem ~3000 de ponta a ponta)
PX = 1650                # pixels
E = PX / LADO_M          # pixels por metro

# nome, tema (o que faz a vila ser única), x, z, tipo
LUGARES = [
    ("Valdoria", "REINO: cidade grande murada, mercado, artesãos, porto do rio", 0, 60, "reino"),
    ("Castelo Imperial", "no morro, acima da cidade", 0, -170, "castelo"),
    ("Refúgio do Pinhal", "acampamento do bando no pinhal (onde o jogo começa)", -150, 1080, "vila"),
    ("Pomar Alto", "pomares de maçã e o moinho", -880, 700, "vila"),
    ("Vila Campos Altos", "SÓ PLANTAÇÃO: trigo, milho, celeiros", -1080, -60, "vila"),
    ("Aldeia Névoa Azul", "vila escondida ATRÁS do bosque", -1000, -860, "vila"),
    ("Vila Pedras Altas", "mineiros, na serra de pedra", -120, -1150, "vila"),
    ("Cratera de Ignis", "forjas sobre o vulcão", 880, -860, "vila"),
    ("Fortaleza de Ferrogris", "posto militar do Império", 1120, 20, "vila"),
    ("Aldeia Beira-Rio", "pescadores, barcos e docas na foz", 900, 760, "vila"),
    ("Acampamento da Ruptura", "rebeldes do Vane", 380, 1090, "vila"),
    ("Posto de Caça", "caçadores e curtume", -520, 330, "posto"),
    ("Cabana do Lenhador", "serraria no pinhal", 330, 620, "posto"),
    ("Fazenda Campina", "gado e ovelhas", -560, -330, "posto"),
    ("Fazenda Rio Claro", "cavalos", 560, 380, "posto"),
    ("Posto da Estrada Imperial", "estalagem dos viajantes", 560, -260, "posto"),
]
# chefe, x, z
CHEFES = [("Gorath", -640, -600), ("Kaelor", 1010, 20), ("Ignis-Maw", 840, -940), ("Vane e Solon", 0, -215)]
# biomas: nome, x, z, cor
BIOMAS = [
    ("campos do reino", 0, 0, (150, 176, 104)), ("pinhal", -100, 1000, (74, 116, 78)), ("pomares", -900, 650, (124, 164, 92)),
    ("plantações", -1050, -100, (196, 186, 104)), ("bosque de névoa", -720, -700, (78, 122, 120)), ("serra de pedra", -50, -1150, (134, 134, 128)),
    ("terra vulcânica", 900, -850, (112, 78, 68)), ("terra cinzenta", 1100, 50, (142, 138, 116)), ("alagados e praia", 900, 800, (120, 158, 128)),
    ("mata", 350, 950, (86, 130, 84)), ("mata", -500, 300, (98, 142, 88)), ("campos", 500, 300, (150, 172, 100)), ("campos", 450, -300, (154, 170, 104)),
    ("campos", -500, -300, (160, 176, 100)),
]
RIOS = [
    [(-200, -1250), (-260, -900), (-330, -520), (-300, -150), (-230, 150), (-330, 520), (-520, 900), (-640, 1330)],   # Rio Cinzento (oeste do reino)
    [(120, -1220), (260, -900), (330, -500), (290, -120), (300, 200), (520, 520), (760, 700), (1150, 900)],          # rio do leste, foz em Beira-Rio
]


def px(x, z):
    return (PX / 2 + x * E, PX / 2 + z * E)


def raio_da_costa(ang):
    return 1390 + 90 * np.sin(ang * 3 + 0.6) + 60 * np.sin(ang * 5 + 2.1) + 40 * np.sin(ang * 9 + 4.0) + 25 * np.sin(ang * 14 + 1.0)


# ---- terreno: cor por bioma (o mais perto manda, com mistura) e o mar em volta
ys, xs = np.mgrid[0:PX, 0:PX]
mx = (xs - PX / 2) / E
mz = (ys - PX / 2) / E
dist = np.hypot(mx, mz)
costa = raio_da_costa(np.arctan2(mz, mx))
img = np.zeros((PX, PX, 3), dtype=np.float32)
peso_total = np.zeros((PX, PX), dtype=np.float32)
for _, bx, bz, cor in BIOMAS:
    w = 1.0 / (np.hypot(mx - bx, mz - bz) + 60.0) ** 3
    img += w[..., None] * np.array(cor, dtype=np.float32)
    peso_total += w
img /= peso_total[..., None]
rng = np.random.default_rng(7)
img += rng.normal(0, 5, (PX, PX, 1))
praia = (dist > costa - 35) & (dist <= costa)
img[praia] = np.array((222, 206, 156))
raso = (dist > costa) & (dist <= costa + 130)
img[raso] = np.array((112, 176, 190))
fundo = dist > costa + 130
img[fundo] = np.array((52, 104, 138))
im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
d = ImageDraw.Draw(im, "RGBA")
F = lambda t: ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", t)
Fn = lambda t: ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", t)

# ---- anéis de distância (para sentir o tamanho)
for r, rot in ((500, "500 m"), (1000, "1 km")):
    c = px(0, 60)
    d.ellipse([c[0] - r * E, c[1] - r * E, c[0] + r * E, c[1] + r * E], outline=(255, 255, 255, 70), width=1)
    d.text((c[0] + r * E * 0.71 + 4, c[1] - r * E * 0.71 - 14), rot, font=Fn(13), fill=(255, 255, 255, 170))

# ---- rios e lago
for rio in RIOS:
    d.line([px(*p) for p in rio], fill=(86, 150, 196, 255), width=7, joint="curve")
lago = px(300, 60)
d.ellipse([lago[0] - 46, lago[1] - 62, lago[0] + 40, lago[1] + 60], fill=(86, 150, 196, 255))

# ---- estradas: do reino para cada lugar, e a estrada do anel ligando as vilas
centro = px(0, 60)
vilas = [l for l in LUGARES if l[4] == "vila"]
for nome, _, x, z, tipo in LUGARES:
    if tipo in ("vila", "posto"):
        d.line([centro, px(x, z)], fill=(120, 92, 60, 230), width=4 if tipo == "vila" else 2)
ordem = sorted(vilas, key=lambda l: math.atan2(l[3] - 60, l[2]))
for a, b in zip(ordem, ordem[1:] + ordem[:1]):
    d.line([px(a[2], a[3]), px(b[2], b[3])], fill=(120, 92, 60, 150), width=2)

# ---- o reino: muralha, cidade e o castelo no morro
c = px(0, 60)
R = 330 * E
d.ellipse([c[0] - R, c[1] - R, c[0] + R, c[1] + R], fill=(204, 180, 140, 255), outline=(70, 60, 55, 255), width=5)
for k in range(0, 360, 14):   # quarteirões
    for rr in (0.35, 0.6, 0.83):
        qx = c[0] + math.cos(math.radians(k + rr * 40)) * R * rr
        qz = c[1] + math.sin(math.radians(k + rr * 40)) * R * rr
        d.rectangle([qx - 5, qz - 5, qx + 5, qz + 5], fill=(170, 96, 70, 255))
m = px(0, -170)
d.ellipse([m[0] - 62, m[1] - 50, m[0] + 62, m[1] + 50], fill=(150, 146, 140, 255), outline=(60, 56, 52, 255), width=3)
d.rectangle([m[0] - 26, m[1] - 20, m[0] + 26, m[1] + 20], fill=(96, 92, 100, 255), outline=(30, 30, 34, 255), width=2)
for sx in (-26, 26):
    for sz in (-20, 20):
        d.rectangle([m[0] + sx - 7, m[1] + sz - 7, m[0] + sx + 7, m[1] + sz + 7], fill=(70, 66, 80, 255))


def rotulo(x, z, titulo, sub, tam=17, dx=14, dz=-10):
    p = px(x, z)
    for ox in (-2, 0, 2):
        for oz in (-2, 0, 2):
            d.text((p[0] + dx + ox, p[1] + dz + oz), titulo, font=F(tam), fill=(255, 255, 255, 235))
    d.text((p[0] + dx, p[1] + dz), titulo, font=F(tam), fill=(30, 26, 22, 255))
    if sub:
        w = d.textlength(sub, font=Fn(12))
        d.rectangle([p[0] + dx - 2, p[1] + dz + tam + 3, p[0] + dx + w + 3, p[1] + dz + tam + 19], fill=(255, 255, 255, 190))
        d.text((p[0] + dx, p[1] + dz + tam + 4), sub, font=Fn(12), fill=(40, 36, 30, 255))


for nome, tema, x, z, tipo in LUGARES:
    p = px(x, z)
    if tipo == "vila":
        d.ellipse([p[0] - 11, p[1] - 11, p[0] + 11, p[1] + 11], fill=(180, 70, 50, 255), outline=(255, 255, 255, 255), width=3)
        rotulo(x, z, nome, tema)
    elif tipo == "posto":
        d.ellipse([p[0] - 6, p[1] - 6, p[0] + 6, p[1] + 6], fill=(235, 215, 150, 255), outline=(60, 50, 40, 255), width=2)
        rotulo(x, z, nome, tema, tam=13, dx=10, dz=-8)
rotulo(0, 60, "VALDORIA (o reino)", "cidade grande murada: mercado, artesãos, quartel, porto do rio", tam=22, dx=-150, dz=40)
rotulo(0, -170, "Castelo Imperial", "no morro, acima da cidade", tam=15, dx=70, dz=-30)
for nome, x, z in CHEFES:
    p = px(x, z)
    d.regular_polygon((p[0], p[1], 13), 3, rotation=180, fill=(200, 30, 30, 255), outline=(255, 255, 255, 255))
    d.text((p[0] - 30, p[1] + 14), "chefe: " + nome, font=F(12), fill=(150, 10, 10, 255))

# ---- tubarões no mar, título, escala e norte
for ang in (20, 95, 160, 235, 300):
    r = raio_da_costa(math.radians(ang)) + 200
    p = px(math.cos(math.radians(ang)) * r, math.sin(math.radians(ang)) * r)
    d.polygon([(p[0] - 12, p[1] + 6), (p[0], p[1] - 14), (p[0] + 12, p[1] + 6)], fill=(60, 70, 80, 255))
    d.text((p[0] - 26, p[1] + 8), "tubarão", font=Fn(12), fill=(230, 240, 245, 255))
d.rectangle([0, 0, PX, 46], fill=(30, 26, 22, 220))
d.text((16, 9), "Reino de Cinzas: PLANTA do mapa novo, versão 1 (ilha de 3 x 3 km, reino no centro). Proposta para aprovar.", font=F(21), fill=(255, 255, 255, 255))
b0 = (60, PX - 60)
d.line([b0, (b0[0] + 500 * E, b0[1])], fill=(255, 255, 255, 255), width=5)
d.text((b0[0], b0[1] - 24), "500 m  (1 min 10 s correndo, 40 s a cavalo)", font=F(15), fill=(255, 255, 255, 255))
d.text((PX - 70, 60), "N", font=F(28), fill=(255, 255, 255, 255))
d.line([(PX - 60, 150), (PX - 60, 96)], fill=(255, 255, 255, 255), width=4)
d.polygon([(PX - 60, 90), (PX - 70, 108), (PX - 50, 108)], fill=(255, 255, 255, 255))
im.save(SAIDA)
print("PLANTA", SAIDA, im.size)
