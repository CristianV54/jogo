# Prepara o Fagulha a partir do dragão rigado de ~/Downloads (só leitura): pinta por região e exporta .glb.
# O arquivo original tem materiais SEM textura ligada (as imagens estão empacotadas mas soltas),
# então a cor vem daqui: cor por vértice (suave, estilo pintado), lida pelos grupos de vértice.
# Rodar:  Blender -b -P preparar_fagulha.py -- ORIGEM.blend SAIDA.glb
# Escala NÃO é aplicada aqui (causa escala dupla no Godot): escalar a raiz na cena do Godot.
import bpy, sys, os, collections
from mathutils import Vector

src, dst = sys.argv[sys.argv.index('--') + 1:][:2]
bpy.ops.wm.open_mainfile(filepath=src)
arm = bpy.data.objects['Armature']
ob = bpy.data.objects['Dragon_Mesh']
me = ob.data
nomes = {g.index: g.name for g in ob.vertex_groups}


def suave(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def mistura(c1, c2, t):
    return tuple(c1[i] * (1 - t) + c2[i] * t for i in range(3))


# Paletas: "fagulha" (ember, o aliado), "corrompido" (Ignis-Maw, escuro com brasa), "verde" (Filhote de Asa, selvagem)
PALETAS = {
    "fagulha": dict(TOPO=(0.40, 0.08, 0.05), FLANCO=(0.68, 0.21, 0.08), BARRIGA=(0.93, 0.74, 0.40), OSSO=(0.90, 0.82, 0.64),
                    MEMB_PERTO=(0.55, 0.14, 0.07), MEMB_LONGE=(0.90, 0.44, 0.12), OLHO=(1.0, 0.62, 0.05)),
    "corrompido": dict(TOPO=(0.05, 0.04, 0.06), FLANCO=(0.15, 0.1, 0.12), BARRIGA=(0.34, 0.12, 0.06), OSSO=(0.45, 0.4, 0.38),
                       MEMB_PERTO=(0.1, 0.05, 0.07), MEMB_LONGE=(0.42, 0.1, 0.06), OLHO=(1.0, 0.12, 0.04)),
    "verde": dict(TOPO=(0.12, 0.22, 0.1), FLANCO=(0.3, 0.42, 0.2), BARRIGA=(0.78, 0.74, 0.5), OSSO=(0.86, 0.82, 0.66),
                  MEMB_PERTO=(0.2, 0.3, 0.14), MEMB_LONGE=(0.55, 0.62, 0.3), OLHO=(0.95, 0.85, 0.1)),
}
_P = PALETAS[os.environ.get("PALETA", "fagulha")]
TOPO, FLANCO, BARRIGA, OSSO = _P["TOPO"], _P["FLANCO"], _P["BARRIGA"], _P["OSSO"]
MEMB_PERTO, MEMB_LONGE, OLHO = _P["MEMB_PERTO"], _P["MEMB_LONGE"], _P["OLHO"]
PUPILA = (0.02, 0.01, 0.01)

# --- pesos por vértice: nome do grupo -> peso
pesos = []
for v in me.vertices:
    pesos.append({nomes[g.group]: g.weight for g in v.groups})


def dominante(i):
    p = pesos[i]
    return max(p, key=p.get) if p else ""


def peso_em(i, pred):
    return sum(w for n, w in pesos[i].items() if pred(n))


# largura do corpo (para a faixa da barriga): vértices ligados à barriga/peito/pélvis
larg = [abs(v.co.x) for v in me.vertices if peso_em(v.index, lambda n: n in ("paunch", "paunch.002", "breast", "pelvic_1", "pelvic_2")) > 0.5]
meia = (sorted(larg)[int(len(larg) * 0.9)] if larg else 10.0)
print("MEIA_LARGURA_DO_CORPO", round(meia, 2))

# --- face por material de cada vértice (um vértice pode tocar 2 materiais: vale o da 1ª face)
mat_do_vertice = {}
for p in me.polygons:
    for vi in p.vertices:
        mat_do_vertice.setdefault(vi, p.material_index)

# --- camada de cor
cor_attr = me.color_attributes.new("Col", "BYTE_COLOR", "POINT")
for v in me.vertices:
    i = v.index
    n, co = v.normal, v.co
    m = mat_do_vertice.get(i, 0)
    if m == 2:                                            # olhos
        c = PUPILA if peso_em(i, lambda g: g.startswith("Auge_Lens")) > 0.5 else OLHO
    elif m == 1:                                          # membrana da asa: escura junto ao corpo, clara na ponta
        c = mistura(MEMB_PERTO, MEMB_LONGE, suave(meia * 0.8, meia * 5.0, abs(co.x)))
    else:                                                 # corpo
        c = mistura(FLANCO, TOPO, suave(0.35, 0.95, n.z))
        lat = suave(meia * 1.3, meia * 0.6, abs(co.x))
        ventre = suave(-0.10, -0.55, n.z) * lat
        gbarriga = 0.8 * suave(-0.2, -0.6, n.z) if peso_em(i, lambda g: g in ("paunch", "paunch.002", "breast")) > 0.4 else 0.0
        c = mistura(c, BARRIGA, max(ventre, gbarriga))
        ponta = peso_em(i, lambda g: g.endswith(("_3_L", "_3_R")) and g.startswith(("front_", "back_")))
        if ponta > 0.5:                                   # pontas dos dedos = garras
            c = mistura(c, OSSO, 0.85 * suave(0.5, 0.9, ponta))
    cor_attr.data[i].color = (*c, 1.0)
me.color_attributes.active_color = cor_attr
me.color_attributes.render_color_index = list(me.color_attributes).index(cor_attr)


# --- materiais limpos: um Principled lendo a cor do vértice, um por fatia
def material(nome, rug):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rug
    ca = nt.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Col"
    nt.links.new(ca.outputs["Color"], b.inputs["Base Color"])
    return m


novos = [material("Fagulha_corpo", 0.75), material("Fagulha_membrana", 0.85), material("Fagulha_olhos", 0.2)]
for i, m in enumerate(novos):
    me.materials[i] = m
me.materials.pop(index=4)      # Material.004 e Material.002 não são usados por nenhuma face
me.materials.pop(index=3)
print("MATERIAIS_FINAIS", [m.name for m in me.materials])

# --- nomes de ação: o sufixo "-loop" faz o Godot importar a animação em loop (e corrige o erro "Idel")
renomear = {"Fly_New": "Fly-loop", "Idel_New": "Idle-loop", "Run_New": "Run-loop", "Walk_New": "Walk-loop"}
for a in bpy.data.actions:
    if a.name in renomear:
        a.name = renomear[a.name]
print("ACOES", [a.name for a in bpy.data.actions])

# --- exportar: malha + esqueleto + TODAS as ações, tamanho original
bpy.context.view_layer.objects.active = arm
for o in bpy.data.objects:
    o.select_set(o in (arm, ob))
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', use_selection=True,
                          export_animations=True, export_animation_mode='ACTIONS',
                          export_force_sampling=True, export_apply=False, export_yup=True)
print("EXPORTADO", dst, os.path.getsize(dst))
