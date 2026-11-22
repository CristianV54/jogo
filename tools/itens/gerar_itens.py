# Modela os itens que os animais deixam ao morrer (carne, couro, lã, presa), em low-poly de cor chapada,
# no mesmo estilo dos outros assets. Origem na base do objeto. Tamanho em metros (~0,2 a 0,3 m).
# Rodar:  Blender -b -P gerar_itens.py -- RAIZ_DO_PROJETO
import bpy, sys, os, math
RAIZ = sys.argv[sys.argv.index("--") + 1]


def material(nome, rgb):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = 0.85
    return m


def objeto(prim, mat, **kw):
    prim(**kw)
    o = bpy.context.active_object
    o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = False
    return o


def juntar_e_exportar(nome):
    bpy.ops.object.select_all(action="DESELECT")
    objs = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    destino = f"{RAIZ}/assets/models/itens/{nome}/{nome}.glb"
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)
    print("EXPORTADO", destino, os.path.getsize(destino))


def novo():
    bpy.ops.wm.read_factory_settings(use_empty=True)


S = bpy.ops.mesh.primitive_uv_sphere_add
C = bpy.ops.mesh.primitive_cylinder_add
K = bpy.ops.mesh.primitive_cone_add
I = bpy.ops.mesh.primitive_ico_sphere_add

# carne: pernil com osso
novo()
carne = material("Carne", (0.5, 0.05, 0.04))
gordura = material("Gordura", (0.75, 0.45, 0.35))
osso = material("Osso", (0.7, 0.65, 0.5))
o = objeto(S, carne, segments=8, ring_count=6, radius=0.11, location=(0, 0, 0.11))
o.scale = (1.25, 0.9, 0.8)
o = objeto(S, gordura, segments=8, ring_count=4, radius=0.075, location=(-0.02, 0, 0.17))
o.scale = (1.0, 0.8, 0.45)
objeto(C, osso, vertices=6, radius=0.02, depth=0.14, location=(0.2, 0, 0.1), rotation=(0, math.pi / 2, 0))
for dy in (-0.022, 0.022):
    objeto(S, osso, segments=6, ring_count=4, radius=0.03, location=(0.28, dy, 0.1))
juntar_e_exportar("carne")

# couro: rolo de pele amarrado
novo()
couro = material("Couro", (0.3, 0.14, 0.05))
escuro = material("CouroEscuro", (0.12, 0.06, 0.02))
corda = material("Corda", (0.45, 0.35, 0.2))
o = objeto(C, couro, vertices=8, radius=0.07, depth=0.3, location=(0, 0, 0.07), rotation=(0, math.pi / 2, 0))
for dx in (-0.15, 0.15):
    objeto(C, escuro, vertices=8, radius=0.062, depth=0.012, location=(dx, 0, 0.07), rotation=(0, math.pi / 2, 0))
objeto(C, corda, vertices=8, radius=0.076, depth=0.025, location=(0, 0, 0.07), rotation=(0, math.pi / 2, 0))
juntar_e_exportar("couro")

# lã: tufo de três bolas
novo()
la = material("La", (0.75, 0.72, 0.65))
for (x, y, z, r) in ((0, 0, 0.1, 0.1), (0.1, 0.04, 0.08, 0.08), (-0.08, -0.05, 0.075, 0.075)):
    objeto(I, la, subdivisions=1, radius=r, location=(x, y, z))
juntar_e_exportar("la")

# presa: cone de marfim curvo (dois cones em ângulo)
novo()
marfim = material("Marfim", (0.7, 0.62, 0.45))
objeto(K, marfim, vertices=6, radius1=0.045, radius2=0.025, depth=0.13, location=(0, 0, 0.065))
o = objeto(K, marfim, vertices=6, radius1=0.025, radius2=0.0, depth=0.13, location=(0.03, 0, 0.17), rotation=(0, math.radians(25), 0))
juntar_e_exportar("presa")

# maçã: esfera vermelha com cabinho e folha
novo()
vermelha = material("Maca", (0.55, 0.04, 0.03))
verde = material("Folha", (0.12, 0.35, 0.08))
cabo = material("Cabo", (0.2, 0.12, 0.05))
o = objeto(S, vermelha, segments=8, ring_count=6, radius=0.09, location=(0, 0, 0.09))
o.scale = (1.0, 1.0, 0.92)
objeto(C, cabo, vertices=5, radius=0.008, depth=0.05, location=(0, 0, 0.18))
o = objeto(S, verde, segments=5, ring_count=3, radius=0.035, location=(0.04, 0, 0.19))
o.scale = (1.4, 0.7, 0.3)
juntar_e_exportar("maca")

# raiz medicinal: raiz retorcida clara com folhas verdes
novo()
terra = material("Raiz", (0.45, 0.32, 0.18))
folha2 = material("FolhaRaiz", (0.15, 0.4, 0.1))
o = objeto(S, terra, segments=6, ring_count=4, radius=0.06, location=(0, 0, 0.06))
o.scale = (0.8, 0.8, 1.6)
for dx, ang in ((-0.05, 25), (0.05, -25)):
    objeto(K, terra, vertices=5, radius1=0.025, radius2=0.004, depth=0.14, location=(dx, 0, 0.02), rotation=(0, math.radians(180 + ang), 0))
for dx in (-0.03, 0.03, 0):
    o = objeto(S, folha2, segments=5, ring_count=3, radius=0.04, location=(dx, 0, 0.2))
    o.scale = (0.5, 0.25, 1.2)
juntar_e_exportar("raiz")

# minério bruto de Ferro Negro: pedra escura com veios azuis
novo()
pedra = material("PedraNegra", (0.04, 0.04, 0.05))
veio = material("VeioAzul", (0.1, 0.25, 0.8))
o = objeto(I, pedra, subdivisions=1, radius=0.13, location=(0, 0, 0.12))
o.scale = (1.0, 0.8, 0.85)
for dx, dy in ((0.08, 0.02), (-0.06, 0.07)):
    o = objeto(I, veio, subdivisions=1, radius=0.03, location=(dx, dy, 0.17))
    o.scale = (0.6, 0.6, 1.3)
juntar_e_exportar("minerio_bruto")

# chave de jaula: argola, haste e dentes
novo()
ferro2 = material("FerroChave", (0.35, 0.3, 0.2))
objeto(C, ferro2, vertices=8, radius=0.05, depth=0.015, location=(0, 0, 0.2), rotation=(math.pi / 2, 0, 0))
objeto(C, ferro2, vertices=5, radius=0.012, depth=0.2, location=(0, 0, 0.09))
objeto(C, ferro2, vertices=4, radius=0.02, depth=0.03, location=(0.03, 0, 0.02), rotation=(0, math.pi / 2, 0))
objeto(C, ferro2, vertices=4, radius=0.02, depth=0.03, location=(0.03, 0, 0.06), rotation=(0, math.pi / 2, 0))
juntar_e_exportar("chave")
