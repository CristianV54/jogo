# Monta um personagem humanoide a partir dos pacotes CC0 do Quaternius (só leitura):
#   Universal Base Characters (corpo-base e pele) + Modular Character Outfits (trajes) + Hairstyles (cabelo).
# Todos usam o MESMO esqueleto de 65 ossos da Universal Animation Library, então as animações servem direto.
# O corpo-base é recortado: fica só cabeça e pescoço (o traje cobre o resto; o pacote avisa que usar o corpo
# inteiro causa clipping). Nenhuma animação é exportada: elas vêm da biblioteca, no Godot.
#
# Rodar:
#   Blender -b -P montar_personagem.py -- NOME Male|Female Light|Dark "Parte1,Parte2" "Cabelo,Sobrancelha" SAIDA.glb
import bpy, bmesh, sys, os
from mathutils import Vector

ARGS = sys.argv[sys.argv.index('--') + 1:]
NOME, SEXO, PELE, PARTES, CABELOS, SAIDA = ARGS[0], ARGS[1], ARGS[2], ARGS[3], ARGS[4], ARGS[5]
PACOTES = os.path.expanduser("~/jogo-trabalho/baixados")
UBC = PACOTES + "/ubc/ex/Universal Base Characters[Standard]"
MCO = PACOTES + "/mco/ex/Modular Character Outfits - Fantasy[Standard]/Exports/glTF (Godot-Unreal)/Modular Parts"
CAB = UBC + "/Hairstyles/Origin at 0/glTF (Godot)"

bpy.ops.wm.read_factory_settings(use_empty=True)


def importar(caminho):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=caminho)
    return [o for o in bpy.data.objects if o not in antes]


def limpar_icosferas():
    # cada importação traz uma "Icosphere" (forma de exibição de osso) que não faz parte do personagem
    for o in [o for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith("Icosphere")]:
        bpy.data.objects.remove(o, do_unlink=True)


# 1) corpo-base: fica só cabeça e pescoço
base = importar(f"{UBC}/Base Characters/Godot - UE/Superhero_{SEXO}_FullBody.gltf")
armadura = next(o for o in base if o.type == 'ARMATURE')
corpo = max((o for o in base if o.type == 'MESH' and o.name.lower().startswith("superhero")), key=lambda o: len(o.data.vertices))
nomes_grupo = {g.index: g.name for g in corpo.vertex_groups}
bm = bmesh.new()
bm.from_mesh(corpo.data)
dv = bm.verts.layers.deform.active
apagar = []
for v in bm.verts:
    dom = max(v[dv].items(), key=lambda kv: kv[1])[0] if v[dv] else None
    if nomes_grupo.get(dom) not in ("Head", "neck_01"):
        apagar.append(v)
bmesh.ops.delete(bm, geom=apagar, context='VERTS')
bm.to_mesh(corpo.data)
bm.free()
corpo.name = f"{NOME}_cabeca"
print("CABECA verts mantidos", len(corpo.data.vertices))

# 2) pele (clara ou escura)
arq_pele = (f"{UBC}/Base Characters/Godot - UE/T_Superhero_{SEXO}_{PELE}"
            + ("_BaseColor.png" if SEXO == "Female" else ".png"))
if os.path.exists(arq_pele):
    img = bpy.data.images.load(arq_pele)
    for mat in corpo.data.materials:
        for n in mat.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and "Normal" not in (n.image.name if n.image else "") and "Rough" not in (n.image.name if n.image else ""):
                n.image = img
elif PELE != "Light":
    print("AVISO pele nao encontrada:", arq_pele)   # a pele clara já é a padrão da base

# 3) peças de traje e cabelo, presas ao MESMO esqueleto
def anexar(caminho):
    novos = importar(caminho)
    arm2 = [o for o in novos if o.type == 'ARMATURE']
    for m in [o for o in novos if o.type == 'MESH' and not o.name.startswith("Icosphere")]:
        mw = m.matrix_world.copy()
        m.parent = armadura
        m.matrix_world = mw
        for mod in m.modifiers:
            if mod.type == 'ARMATURE':
                mod.object = armadura
    for a in arm2:
        bpy.data.objects.remove(a, do_unlink=True)


for p in [x for x in PARTES.split(",") if x]:
    anexar(f"{MCO}/{p}.gltf")
def prender_cabelo_na_cabeca(nome_antes: set) -> None:
    """O cabelo do pacote é uma malha solta (sem pesos nem modificador), feita para ser pendurada no osso da cabeça
    pelo motor. Exportado assim, ele ficava parado no espaço quando a cabeça mexia. Aqui ele ganha 100% de peso no osso Head."""
    for m in [o for o in bpy.data.objects if o.type == 'MESH' and o.name not in nome_antes and not o.name.startswith("Icosphere")]:
        if len(m.vertex_groups) == 0:
            g = m.vertex_groups.new(name="Head")
            g.add(list(range(len(m.data.vertices))), 1.0, 'REPLACE')
            mod = m.modifiers.new("Armature", 'ARMATURE')
            mod.object = armadura
            print("CABELO preso ao osso Head:", m.name, len(m.data.vertices), "vertices")


for c in [x for x in CABELOS.split(",") if x]:
    antes = {o.name for o in bpy.data.objects}
    anexar(f"{CAB}/{c}.gltf")
    prender_cabelo_na_cabeca(antes)
limpar_icosferas()

# 3b) texturas: o pacote vem em 4K (um personagem passava de 50 MB); reduz para no máximo 1024.
#     Exporta em PNG: o Godot 4.7 recusou os JPEG de cor deste pacote ("Couldn't load image ... image/jpeg").
LIMITE_TEXTURA = int(os.environ.get("TEXLIM", "1024"))   # NPCs menores usam 512
for img in bpy.data.images:
    if img.size[0] > 0 and max(img.size) > LIMITE_TEXTURA:
        fator = LIMITE_TEXTURA / max(img.size)
        img.scale(max(1, int(img.size[0] * fator)), max(1, int(img.size[1] * fator)))

# 4) resumo e exportação (sem animações)
malhas = [o for o in bpy.data.objects if o.type == 'MESH']
print("RESUMO", NOME, "malhas", [(m.name, len(m.data.vertices)) for m in malhas], "armaduras", [a.name for a in bpy.data.objects if a.type == 'ARMATURE'])
bpy.context.view_layer.objects.active = armadura
for o in bpy.data.objects:
    o.select_set(True)
os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=SAIDA, export_format='GLB', use_selection=True, export_animations=False,
                          export_apply=False, export_yup=True, export_image_format='AUTO')
print("EXPORTADO", SAIDA, os.path.getsize(SAIDA))
