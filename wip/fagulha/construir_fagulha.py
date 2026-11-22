# Fagulha, dragão jovem aliado do Torin. Modelado por script no Blender 5.3.
# Anatomia lida num dragão de referência (só proporções, nenhuma malha copiada):
#   cabeça = 1 H; pescoço ~1,2 H; tronco ~1,8 H; cauda ~6 H; envergadura ~10 H (adulto).
# Filhote: cabeça maior em relação ao corpo (H maior), cauda e asas relativamente menores,
# pernas curtas e grossas, tronco de barril.
# Eixos: Z para cima, ele olha para -Y (frente padrão do Blender), X é a largura.
# Fatos do Blender (testados): a pele termina EXATAMENTE no ponto do esqueleto (não sobra o raio);
# numa aresta ao longo de Y o raio é (largura em X, altura em Z).
# Rodar:  Blender -b -P construir_fagulha.py
import bpy, bmesh, math, os, json
from mathutils import Vector, Matrix

AQUI = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def material(nome, cor, rug=0.65):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*cor, 1)
    b.inputs["Roughness"].default_value = rug
    m.diffuse_color = (*cor, 1)
    return m


# Um material só; a cor vem da camada de cor pintada em cada vértice ("cor"), que o glb também leva.
M_PINTURA = material("Pintura", (1, 1, 1), 0.7)
_nt = M_PINTURA.node_tree
_vc = _nt.nodes.new("ShaderNodeVertexColor"); _vc.layer_name = "cor"
_nt.links.new(_vc.outputs["Color"], _nt.nodes["Principled BSDF"].inputs["Base Color"])


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def mistura(c1, c2, t):
    return tuple(c1[i] * (1 - t) + c2[i] * t for i in range(3))


def pintar(ob, fn):
    ob.data.materials.clear()
    ob.data.materials.append(M_PINTURA)
    attr = ob.data.color_attributes.new("cor", "FLOAT_COLOR", "POINT")
    for v in ob.data.vertices:
        attr.data[v.index].color = (*fn(v.co, v.normal), 1.0)


TOPO = (0.40, 0.08, 0.05)
FLANCO = (0.68, 0.21, 0.08)
BARRIGA = (0.93, 0.74, 0.40)
OSSO = (0.90, 0.82, 0.64)


def cor_corpo(co, n):
    c = mistura(FLANCO, TOPO, suave(0.35, 0.95, n.z))
    lat = suave(0.22, 0.09, abs(co.x))                      # só na linha do meio
    ventre = suave(-0.10, -0.55, n.z) * lat                 # barriga, cauda por baixo, solas
    garganta = suave(-0.25, -0.65, n.y) * lat * suave(-0.62, -0.56, co.y) * suave(0.78, 0.86, co.z)
    return mistura(c, BARRIGA, max(ventre, garganta))


class Pele:
    """Esqueleto de linhas com raio (largura, altura) em cada ponto; o modificador Skin veste a pele."""

    def __init__(self):
        self.v, self.e, self.r, self.raizes = [], [], [], set()

    def no(self, p, r, ligado=None):
        self.v.append(Vector(p))
        self.r.append(r if isinstance(r, tuple) else (r, r))
        i = len(self.v) - 1
        if ligado is not None:
            self.e.append((ligado, i))
        else:
            self.raizes.add(i)   # todo pedaço solto precisa da sua raiz, senão a pele não é gerada
        return i

    def cadeia(self, pts, raios, ligado=None):
        ult, ids = ligado, []
        for p, r in zip(pts, raios):
            ult = self.no(p, r, ult)
            ids.append(ult)
        return ids

    def construir(self, nome, sub=2, suavizar=0.9):
        bm = bmesh.new()
        cam = bm.verts.layers.skin.verify()
        vs = [bm.verts.new(p) for p in self.v]
        bm.verts.ensure_lookup_table()
        for a, b in self.e:
            bm.edges.new((vs[a], vs[b]))
        for i, v in enumerate(vs):
            v[cam].radius = self.r[i]
            v[cam].use_root = (i in self.raizes)
        me = bpy.data.meshes.new(nome)
        bm.to_mesh(me); bm.free()
        ob = bpy.data.objects.new(nome, me)
        sc.collection.objects.link(ob)
        s = ob.modifiers.new("pele", "SKIN")
        s.branch_smoothing = suavizar
        s.use_smooth_shade = True
        sd = ob.modifiers.new("sub", "SUBSURF")
        sd.levels = sub; sd.render_levels = sub
        dg = bpy.context.evaluated_depsgraph_get()
        ob.data = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        ob.modifiers.clear()
        sem_soltos = bmesh.new(); sem_soltos.from_mesh(ob.data)   # a pele deixa vértices órfãos nas junções
        bmesh.ops.delete(sem_soltos, geom=[v for v in sem_soltos.verts if not v.link_edges], context="VERTS")
        sem_soltos.to_mesh(ob.data); sem_soltos.free()
        for f in ob.data.polygons:
            f.use_smooth = True
        return ob


def cone(bm, base, direcao, comp, raio, seg=8):
    d = Vector(direcao).normalized()
    rot = Vector((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4()
    m = Matrix.Translation(base) @ rot @ Matrix.Translation((0, 0, comp / 2))
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg,
                          radius1=raio, radius2=0.0, depth=comp, matrix=m)


def objeto_de_bm(bm, nome, mat):
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(nome, me)
    sc.collection.objects.link(ob)
    ob.data.materials.append(mat)
    for f in ob.data.polygons:
        f.use_smooth = True
    return ob


# ---------------------------------------------------------------- corpo (tronco + pescoço + cabeça + cauda + pernas)
# raios = (largura, altura). Tronco de barril: mais largo que alto na cintura, peito fundo.
corpo = Pele()
quadril = corpo.no((0, 0.38, 0.70), (0.27, 0.22))
meio = corpo.no((0, 0.01, 0.74), (0.28, 0.24), quadril)
peito = corpo.no((0, -0.36, 0.76), (0.31, 0.27), meio)   # peito largo: a vista de frente não pode virar "pino"

PESCOCO = [(0, -0.47, 0.90), (0, -0.55, 1.04), (0, -0.59, 1.16), (0, -0.60, 1.25)]
R_PESCOCO = [(0.17, 0.17), (0.135, 0.135), (0.115, 0.115), (0.11, 0.11)]
ids_pescoco = corpo.cadeia(PESCOCO, R_PESCOCO, peito)
nuca = ids_pescoco[-1]

# cabeça costurada no pescoço: crânio largo, focinho que afina e inclina para baixo
CABECA = [(0, -0.64, 1.27), (0, -0.73, 1.26), (0, -0.84, 1.235), (0, -0.92, 1.205), (0, -0.985, 1.185)]
R_CABECA = [(0.12, 0.11), (0.14, 0.105), (0.095, 0.075), (0.075, 0.055), (0.058, 0.042)]
ids_cab = corpo.cadeia(CABECA, R_CABECA, nuca)
cranio = ids_cab[1]
for f in (1, -1):
    # crista que corre do osso da sobrancelha até o focinho (cara de dragão, não de cabra)
    corpo.cadeia([(0.088 * f, -0.76, 1.33), (0.07 * f, -0.82, 1.312)],
                 [(0.026, 0.024), (0.018, 0.016)], cranio)
    # músculo da mastigação: bochecha larga atrás da boca
    corpo.cadeia([(0.115 * f, -0.74, 1.20)], [(0.055, 0.055)], cranio)

CAUDA = [(0, 0.60, 0.70), (0, 0.85, 0.64), (0.03, 1.10, 0.56), (0.09, 1.35, 0.47),
         (0.12, 1.60, 0.40), (0.09, 1.85, 0.37), (0.02, 2.05, 0.39), (-0.03, 2.22, 0.43)]
R_CAUDA = [(0.20, 0.17), (0.155, 0.135), (0.12, 0.105), (0.09, 0.08),
           (0.065, 0.058), (0.045, 0.04), (0.027, 0.025), (0.012, 0.012)]
corpo.cadeia(CAUDA, R_CAUDA, quadril)

# pernas dianteiras: ombro -> cotovelo (para trás) -> punho -> palma. Curtas e grossas (filhote).
DIANT = [(0.20, -0.30, 0.66), (0.30, -0.14, 0.45), (0.275, -0.26, 0.29), (0.26, -0.36, 0.14), (0.26, -0.43, 0.055)]
R_DIANT = [(0.155, 0.155), (0.115, 0.115), (0.10, 0.10), (0.082, 0.082), (0.075, 0.07)]
# pernas traseiras (digitígradas): quadril -> joelho (para frente) -> jarrete (para trás) -> bola do pé
TRAS = [(0.20, 0.34, 0.66), (0.32, 0.10, 0.50), (0.28, 0.42, 0.24), (0.27, 0.31, 0.06)]
R_TRAS = [(0.185, 0.185), (0.14, 0.14), (0.09, 0.09), (0.078, 0.07)]   # raio do quadril > 0,19 gera "caixa" na junção da pele
pes = {}
for lado, f in (("E", 1), ("D", -1)):
    ids = corpo.cadeia([(p[0] * f, p[1], p[2]) for p in DIANT], R_DIANT, peito)
    pes["diant" + lado] = ids[-1]
    # cotovelo marcado, apontando para trás
    corpo.cadeia([(0.315 * f, -0.05, 0.47)], [(0.05, 0.05)], ids[1])
    ids = corpo.cadeia([(p[0] * f, p[1], p[2]) for p in TRAS], R_TRAS, quadril)
    pes["tras" + lado] = ids[-1]
    # joelho (rótula) para frente e jarrete (calcanhar) para trás: as duas juntas que dão a perna de réptil
    corpo.cadeia([(0.33 * f, 0.04, 0.525)], [(0.05, 0.05)], ids[1])
    corpo.cadeia([(0.28 * f, 0.50, 0.27)], [(0.05, 0.05)], ids[2])

DEDOS_X = (-0.062, 0.0, 0.062)
garras = []
for chave, idx in pes.items():
    base = corpo.v[idx]
    for dx in DEDOS_X:
        p1 = (base.x + dx, base.y - 0.08, 0.045)
        p2 = (base.x + dx * 1.3, base.y - 0.15, 0.032)
        corpo.cadeia([p1, p2], [(0.036, 0.032), (0.027, 0.024)], idx)
        d = Vector((dx * 0.8, -1.0, -0.40)).normalized()
        garras.append((Vector(p2) - d * 0.02, d))

ob_corpo = corpo.construir("Fagulha_corpo", sub=3)

# ---------------------------------------------------------------- mandíbula (separada, encaixada sob o focinho)
mand = Pele()
mand.cadeia([(0, -0.68, 1.172), (0, -0.79, 1.147), (0, -0.89, 1.135), (0, -0.96, 1.13)],
            [(0.085, 0.042), (0.072, 0.036), (0.056, 0.032), (0.04, 0.028)])
ob_mand = mand.construir("Fagulha_mandibula", sub=2, suavizar=0.5)

# ---------------------------------------------------------------- chifres (para trás, nascendo dentro do crânio)
ch = Pele()
for f in (1, -1):
    ch.cadeia([(0.07 * f, -0.67, 1.31), (0.10 * f, -0.56, 1.43), (0.12 * f, -0.43, 1.49),
               (0.12 * f, -0.32, 1.485)], [0.036, 0.028, 0.016, 0.004])
ob_chifre = ch.construir("Fagulha_chifres", sub=1, suavizar=0.5)

# ---------------------------------------------------------------- olhos, pupilas, sobrancelhas, narinas
bm = bmesh.new()
for f in (1, -1):
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.036,
                              matrix=Matrix.Translation((0.105 * f, -0.775, 1.285)))
ob_olhos = objeto_de_bm(bm, "Fagulha_olhos", M_PINTURA)
bm = bmesh.new()
for f in (1, -1):
    bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=0.022,
                              matrix=Matrix.Translation((0.133 * f, -0.782, 1.287))
                              @ Matrix.Diagonal((0.35, 0.9, 1.6, 1.0)))
ob_pup = objeto_de_bm(bm, "Fagulha_pupilas", M_PINTURA)
bm = bmesh.new()
for f in (1, -1):
    bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=6, radius=0.013,
                              matrix=Matrix.Translation((0.032 * f, -0.972, 1.208)))
ob_narinas = objeto_de_bm(bm, "Fagulha_narinas", M_PINTURA)

# ---------------------------------------------------------------- garras e presas
bm = bmesh.new()
for base, d in garras:
    cone(bm, base, d, 0.07, 0.017)
ob_garras = objeto_de_bm(bm, "Fagulha_garras", M_PINTURA)
bm = bmesh.new()
for f in (1, -1):
    for y, z, c in ((-0.935, 1.168, 0.034), (-0.86, 1.185, 0.028)):   # presas de cima, para baixo
        cone(bm, (0.040 * f, y, z + 0.012), (0, -0.15, -1.0), c, 0.0085)
    cone(bm, (0.030 * f, -0.935, 1.150), (0, -0.15, 1.0), 0.026, 0.0075)   # presa de baixo, para cima
ob_presas = objeto_de_bm(bm, "Fagulha_presas", M_PINTURA)


# ---------------------------------------------------------------- espinhos colados à malha de verdade
def ponto_de_cima(ob, centro, raio, cima):
    """Vértice do corpo, perto de `centro`, mais fundo na direção `cima`."""
    cima = Vector(cima).normalized()
    melhor, ds = None, -1e9
    for v in ob.data.vertices:
        rel = v.co - Vector(centro)
        if abs(v.co.x) < 0.035 and rel.length < raio * 1.7:
            d = rel.dot(cima)
            if d > ds:
                melhor, ds = v.co.copy(), d
    return melhor


bm = bmesh.new()
dorsais = []  # (centro, raio, cima, comprimento)
for p, r in zip(PESCOCO, R_PESCOCO):
    dorsais.append((p, r[0], (0, 0.75, 0.65), 0.095))
for p in ((0, -0.20, 0.76), (0, 0.00, 0.74), (0, 0.20, 0.72)):
    dorsais.append((p, 0.25, (0, 0, 1), 0.105))
for i, (p, r) in enumerate(zip(CAUDA, R_CAUDA)):
    c = 0.100 - i * 0.012
    if c > 0.024:
        dorsais.append((p, r[0], (0, 0.1, 1), c))
for centro, raio, cima, comp in dorsais:
    v = ponto_de_cima(ob_corpo, centro, raio, cima)
    if v is not None:
        d = (Vector(cima).normalized() + Vector((0, 0.55, 0))).normalized()
        cone(bm, v - Vector(cima).normalized() * 0.012, d, comp, 0.032)
# franja de espinhos na bochecha, apontando para trás
for f in (1, -1):
    for y, z, c in ((-0.71, 1.27, 0.09), (-0.66, 1.21, 0.075), (-0.62, 1.15, 0.06)):
        cone(bm, (0.115 * f, y, z), (0.8 * f, 0.6, 0.1), c, 0.026)
ob_esp = objeto_de_bm(bm, "Fagulha_espinhos", M_PINTURA)

# ---------------------------------------------------------------- asas: ossos + membrana
R_ = (0.10, -0.22, 0.88)   # raiz DENTRO do tronco
E_ = (0.44, 0.00, 1.13)
W_ = (0.84, -0.30, 1.39)
DEDOS = [(1.30, -0.68, 1.45), (1.33, -0.18, 1.29), (1.18, 0.30, 1.09), (0.82, 0.60, 0.96)]
B_ = (0.17, 0.38, 0.80)    # onde a membrana prende no flanco (dentro do corpo)

ossos = Pele()
for f in (1, -1):
    pts = lambda L: [(p[0] * f, p[1], p[2]) for p in L]
    r = ossos.no((R_[0] * f, R_[1], R_[2]), 0.06)
    e = ossos.no((E_[0] * f, E_[1], E_[2]), 0.042, r)
    w = ossos.no((W_[0] * f, W_[1], W_[2]), 0.032, e)
    for t in DEDOS:
        ossos.cadeia(pts([t]), [0.008], w)
ob_ossos = ossos.construir("Fagulha_asa_ossos", sub=1, suavizar=0.5)


def dist_segmento(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (p - (a + ab * t)).length


def membrana(f):
    bm = bmesh.new()
    P = lambda p: Vector((p[0] * f, p[1], p[2]))
    W, E, R, B = P(W_), P(E_), P(R_), P(B_)
    T = [P(t) for t in DEDOS]
    borda = []
    for i in range(len(T)):
        borda.append(T[i])
        if i < len(T) - 1:
            for t, inset in ((0.25, 0.10), (0.50, 0.30), (0.75, 0.10)):
                p = T[i].lerp(T[i + 1], t)
                borda.append(p + (W - p) * inset)
    mid = T[-1].lerp(B, 0.5)
    borda.append(mid + (W - mid) * 0.12)
    borda.append(B)
    vb = [bm.verts.new(p) for p in borda]
    vW, vE, vR = (bm.verts.new(p) for p in (W, E, R))

    def face(*vs):  # orientação igual nos dois lados: o espelho inverte a ordem
        bm.faces.new(vs if f > 0 else vs[::-1])
    for i in range(len(borda) - 1):
        face(vW, vb[i + 1], vb[i])        # leque a partir do punho
    face(vb[-1], vW, vE)                  # (vb[-1] é o ponto B do flanco)
    face(vb[-1], vE, vR)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)
    # a membrana cai entre os ossos (barriga de vela) e fica colada neles
    ossos_seg = [(R, E), (E, W)] + [(W, t) for t in T]
    for v in bm.verts:
        dmin = min(dist_segmento(v.co, a, b) for a, b in ossos_seg)
        v.co.z -= 0.07 * suave(0.0, 0.22, dmin)
    return bm


bm = bmesh.new()
for f in (1, -1):
    b = membrana(f)
    me = bpy.data.meshes.new("tmp"); b.to_mesh(me); b.free()
    bm.from_mesh(me); bpy.data.meshes.remove(me)
ob_mem = objeto_de_bm(bm, "Fagulha_asa_membrana", M_PINTURA)
so = ob_mem.modifiers.new("esp", "SOLIDIFY"); so.thickness = 0.012; so.offset = 0
ss = ob_mem.modifiers.new("sub", "SUBSURF"); ss.levels = 1; ss.render_levels = 1
dg = bpy.context.evaluated_depsgraph_get()
ob_mem.data = bpy.data.meshes.new_from_object(ob_mem.evaluated_get(dg))
ob_mem.modifiers.clear()
for f in ob_mem.data.polygons:
    f.use_smooth = True

# ---------------------------------------------------------------- pintura suave (camada de cor por vértice)
pintar(ob_corpo, cor_corpo)
pintar(ob_mand, lambda co, n: mistura(BARRIGA, FLANCO, 0.55 * suave(0.3, 0.9, n.z)))
pintar(ob_chifre, lambda co, n: mistura((0.60, 0.50, 0.36), OSSO, suave(-0.7, -0.3, co.y)))
pintar(ob_garras, lambda co, n: OSSO)
pintar(ob_presas, lambda co, n: (0.97, 0.94, 0.84))
pintar(ob_esp, lambda co, n: (0.28, 0.06, 0.04))
pintar(ob_ossos, lambda co, n: TOPO)
pintar(ob_mem, lambda co, n: mistura((0.55, 0.14, 0.07), (0.90, 0.44, 0.12), suave(0.15, 1.15, abs(co.x))))
pintar(ob_olhos, lambda co, n: (1.0, 0.62, 0.05))
pintar(ob_pup, lambda co, n: (0.02, 0.01, 0.01))
pintar(ob_narinas, lambda co, n: (0.12, 0.03, 0.02))

# ---------------------------------------------------------------- filhote rente ao chão
# Encurta só as pernas (abaixo do quadril); da cintura para cima tudo desce junto, sem deformar.
# Referência: o dragão quadrúpede de estudo tem o tronco baixo e as pernas dobradas.
ALT_QUADRIL, ABAIXAR = 0.70, 0.12


def agachar(z):
    return z * ((ALT_QUADRIL - ABAIXAR) / ALT_QUADRIL) if z <= ALT_QUADRIL else z - ABAIXAR


def AG(p):
    return (p[0], p[1], agachar(p[2]))


# ---------------------------------------------------------------- agrupar sob um pai
raiz = bpy.data.objects.new("Fagulha", None)
sc.collection.objects.link(raiz)
partes = [ob_corpo, ob_mand, ob_chifre, ob_olhos, ob_pup, ob_narinas, ob_garras, ob_presas,
          ob_esp, ob_ossos, ob_mem]
for o in partes:
    for v in o.data.vertices:
        v.co.z = agachar(v.co.z)
    o.data.update()
    o.parent = raiz

# ---------------------------------------------------------------- medição (o "log")


def caixa(obs, filtro=lambda v: True):
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for o in obs:
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            if not filtro(w):
                continue
            for i in range(3):
                mn[i] = min(mn[i], w[i]); mx[i] = max(mx[i], w[i])
    return mn, mx


def caminho(pts):
    return sum((Vector(pts[i + 1]) - Vector(pts[i])).length for i in range(len(pts) - 1))


# cabeça medida NA MALHA: do fundo do crânio à ponta do focinho (nó da nuca em diante)
mnh, mxh = caixa([ob_corpo], lambda w: w.y < PESCOCO[-1][1] and w.z > 1.10 - ABAIXAR)
Hm = mxh.y - mnh.y
mnw, mxw = caixa([ob_ossos, ob_mem])
mna, mxa = caixa(partes)
tronco = caminho([AG(p) for p in ((0, 0.38, 0.70), (0, 0.01, 0.74), (0, -0.36, 0.76))])
pesc = caminho([AG(p) for p in [(0, -0.36, 0.76)] + PESCOCO])
cauda = caminho([AG(p) for p in [(0, 0.38, 0.70)] + CAUDA])
perna_d = caminho([AG(p) for p in DIANT])
perna_t = caminho([AG(p) for p in TRAS])
med = {
    "cabeca_H_m": round(Hm, 3),
    "tronco_em_H": round(tronco / Hm, 2),
    "pescoco_em_H": round(pesc / Hm, 2),
    "cauda_em_H": round(cauda / Hm, 2),
    "envergadura_em_H": round((mxw.x - mnw.x) / Hm, 2),
    "perna_diant_em_H": round(perna_d / Hm, 2),
    "perna_tras_em_H": round(perna_t / Hm, 2),
    "comprimento_total_m": round(mxa.y - mna.y, 2),
    "altura_ate_chifre_m": round(mxa.z - mna.z, 2),
    "largura_asas_m": round(mxa.x - mna.x, 2),
    "pe_no_chao_z_min": round(mna.z, 3),
    "vertices_total": sum(len(o.data.vertices) for o in partes),
    "faces_total": sum(len(o.data.polygons) for o in partes),
}
def componentes(ob):
    """Quantos pedaços soltos a malha tem (union-find nas arestas)."""
    pai = list(range(len(ob.data.vertices)))

    def raiz(i):
        while pai[i] != i:
            pai[i] = pai[pai[i]]; i = pai[i]
        return i
    for e in ob.data.edges:
        pai[raiz(e.vertices[0])] = raiz(e.vertices[1])
    return len({raiz(i) for i in range(len(pai))})


med["pedacos_soltos"] = {o.name: componentes(o) for o in partes if o in (ob_corpo, ob_mand, ob_chifre, ob_ossos, ob_mem)}
# esperado: corpo 1, mandibula 1, chifres 2 (um de cada lado), ossos da asa 2, membrana 2
bmw = bmesh.new(); bmw.from_mesh(ob_mem.data)
med["membrana_arestas_abertas_alem_da_borda"] = sum(1 for e in bmw.edges if len(e.link_faces) > 2)
bmw.free()
print("MEDICAO", json.dumps(med, ensure_ascii=False))
json.dump(med, open(os.path.join(AQUI, "medicao.json"), "w"), indent=1, ensure_ascii=False)

# ---------------------------------------------------------------- renders
sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.80, 0.80, 0.82)
sc.render.resolution_x, sc.render.resolution_y = 1400, 800
cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("c", cam)
sc.collection.objects.link(co); sc.camera = co
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "VERTEX"
sc.display.shading.show_cavity = False
os.makedirs(os.path.join(AQUI, "render"), exist_ok=True)

ctr = Vector((0, 0.55, 0.75))


def foto(nome, pos, alvo=ctr, ortho=None, lente=50):
    if ortho:
        cam.type = "ORTHO"; cam.ortho_scale = ortho
    else:
        cam.type = "PERSP"; cam.lens = lente
    cam.clip_start, cam.clip_end = 0.01, 50
    co.location = Vector(pos)
    co.rotation_euler = (Vector(alvo) - co.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(AQUI, "render", nome + ".png")
    bpy.ops.render.render(write_still=True)


foto("lado", (6, 0.6, 0.75), alvo=(0, 0.6, 0.75), ortho=3.9)
foto("frente", (0, -6, 0.75), ortho=3.9)
foto("topo", (0, 0.55, 6), ortho=3.9)
foto("tres_quartos", (3.4, -3.0, 1.9), alvo=(0, 0.3, 0.75), lente=42)
foto("cabeca", (1.0, -1.9, 1.33), alvo=(0, -0.78, 1.10), lente=70)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(AQUI, "fagulha.blend"))
print("FIM OK")
