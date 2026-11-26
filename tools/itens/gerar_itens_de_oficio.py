# Modela os itens de ofício e as armaduras (moeda, minério e lingote de ferro, madeira, pão, peixe assado, picareta,
# peitoral e ombreira de couro e de ferro), no mesmo estilo dos outros itens (formas simples, sombreado suave).
# As ARMADURAS são modeladas no espaço do Torin em pose de descanso (metros, pés na origem, frente em +Z do jogo),
# para o Humanoide vesti-las presas aos ossos spine_03 (peito) e upperarm (ombros).
# Rodar:  python3 tools/itens/gerar_itens_de_oficio.py   (precisa do módulo bpy: pip install bpy)
import bpy, os, math
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
S = bpy.ops.mesh.primitive_uv_sphere_add
C = bpy.ops.mesh.primitive_cylinder_add
K = bpy.ops.mesh.primitive_cone_add
B = bpy.ops.mesh.primitive_cube_add

def novo():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def material(nome, rgb, metal=0.0, aspero=0.8):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = aspero
    b.inputs["Metallic"].default_value = metal
    return m

def objeto(prim, mat, escala=(1, 1, 1), suave=True, **kw):
    prim(**kw)
    o = bpy.context.active_object
    o.scale = escala
    o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = suave
    return o

def exportar(pasta, nome):
    bpy.ops.object.select_all(action="DESELECT")
    objs = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    destino = os.path.join(RAIZ, 'assets', 'models', pasta, nome, nome + '.glb')
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)
    print("EXPORTADO", nome, os.path.getsize(destino))

# No Blender Z é para cima e -Y é a frente do jogo (+Z) depois da exportação.
# --- moeda: pilha de três discos dourados
novo(); ouro = material("Ouro", (0.85, 0.62, 0.15), 0.9, 0.35); escuro = material("OuroEscuro", (0.55, 0.38, 0.08), 0.9, 0.4)
for i, (dx, dy) in enumerate([(0, 0), (0.012, 0.006), (-0.01, 0.01)]):
    objeto(C, ouro, vertices=20, radius=0.06, depth=0.014, location=(dx, dy, 0.008 + i * 0.016))
    objeto(C, escuro, vertices=20, radius=0.045, depth=0.016, location=(dx, dy, 0.008 + i * 0.016))
exportar('itens', 'moeda')
# --- minério de ferro: pedra cinza com veios cor de ferrugem
novo(); pedra = material("Pedra", (0.36, 0.34, 0.33)); veio = material("Veio", (0.62, 0.36, 0.2), 0.5, 0.5)
objeto(S, pedra, (1.2, 0.9, 0.75), False, segments=7, ring_count=5, radius=0.11, location=(0, 0, 0.085))
objeto(S, pedra, (0.8, 0.9, 0.7), False, segments=6, ring_count=4, radius=0.08, location=(0.1, 0.04, 0.06))
for x, y, z in [(-0.05, -0.07, 0.12), (0.04, 0.05, 0.15), (0.11, -0.03, 0.09), (-0.09, 0.04, 0.08)]:
    objeto(S, veio, (1, 1, 0.6), False, segments=5, ring_count=3, radius=0.03, location=(x, y, z))
exportar('itens', 'minerio_de_ferro')
# --- lingote de ferro: barra de trapézio
novo(); ferro = material("Ferro", (0.55, 0.56, 0.6), 0.85, 0.4)
o = objeto(B, ferro, (0.13, 0.06, 0.035), False, size=2, location=(0, 0, 0.035))
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='DESELECT'); bpy.ops.object.mode_set(mode='OBJECT')
for v in o.data.vertices:
    if v.co.z > 0: v.co.x *= 0.82; v.co.y *= 0.7
objeto(B, ferro, (0.11, 0.05, 0.03), False, size=2, location=(0.03, 0.09, 0.03), rotation=(0, 0, 0.5))
exportar('itens', 'lingote_de_ferro')
# --- madeira: três toras amarradas
novo(); casca = material("Casca", (0.33, 0.22, 0.12)); cerne = material("Cerne", (0.75, 0.6, 0.38)); corda = material("Corda", (0.6, 0.5, 0.3))
for dx, dz in [(-0.06, 0.05), (0.06, 0.05), (0, 0.15)]:
    objeto(C, casca, vertices=10, radius=0.055, depth=0.36, location=(dx, 0, dz), rotation=(math.pi / 2, 0, 0))
    for s in (-1, 1):
        objeto(C, cerne, vertices=10, radius=0.045, depth=0.01, location=(dx, s * 0.181, dz), rotation=(math.pi / 2, 0, 0))
for y in (-0.09, 0.09):
    objeto(C, corda, (1, 1, 1), True, vertices=12, radius=0.125, depth=0.02, location=(0, y, 0.085), rotation=(math.pi / 2, 0, 0))
exportar('itens', 'madeira')
# --- pão: broa com três talhos
novo(); crosta = material("Crosta", (0.72, 0.48, 0.22)); miolo = material("Miolo", (0.9, 0.78, 0.55))
objeto(S, crosta, (1.5, 0.95, 0.62), True, segments=14, ring_count=8, radius=0.1, location=(0, 0, 0.062))
for x in (-0.06, 0, 0.06):
    objeto(B, miolo, (0.008, 0.06, 0.012), False, size=2, location=(x, 0, 0.118), rotation=(0, 0, 0.5))
exportar('itens', 'pao')
# --- peixe assado no espeto
novo(); peixe = material("Peixe", (0.6, 0.45, 0.28)); pau = material("Pau", (0.4, 0.28, 0.16))
objeto(S, peixe, (1.9, 0.5, 0.8), True, segments=12, ring_count=7, radius=0.07, location=(0, 0, 0.07))
objeto(K, peixe, (1, 0.3, 1.3), False, vertices=4, radius1=0.06, radius2=0.0, depth=0.09, location=(-0.16, 0, 0.07), rotation=(0, math.pi / 2, 0))
objeto(C, pau, vertices=6, radius=0.008, depth=0.5, location=(0, 0, 0.07), rotation=(0, math.pi / 2, 0))
exportar('itens', 'peixe_assado')
# --- picareta: cabo de madeira e cabeça de ferro em arco com duas pontas
novo(); cabo = material("Cabo", (0.45, 0.3, 0.16)); ferro = material("Ferro", (0.5, 0.52, 0.56), 0.85, 0.4)
objeto(C, cabo, vertices=8, radius=0.022, depth=0.8, location=(0, 0, 0.4))
objeto(B, ferro, (0.05, 0.035, 0.04), True, size=2, location=(0, 0, 0.78))
for s in (-1, 1):
    objeto(K, ferro, (1, 0.6, 1), True, vertices=8, radius1=0.04, radius2=0.004, depth=0.3, location=(s * 0.19, 0, 0.76), rotation=(0, s * (math.pi / 2 + 0.22), 0))
exportar('armas', 'picareta')
# --- ARMADURAS, no espaço do Torin (frente do jogo = -Y do Blender). Peito: de 1,02 a 1,50 m; ombro em (±0,21; 1,46)
def peitoral(nome, cor, cor_detalhe, metal, placas):
    novo(); m = material("Base", cor, metal, 0.5 if metal else 0.8); d = material("Detalhe", cor_detalhe, metal, 0.45 if metal else 0.75)
    objeto(S, m, (0.21, 0.142, 0.265), True, segments=18, ring_count=12, radius=1.0, location=(0, 0.005, 1.27))          # o casco do tronco
    objeto(C, d, (1.0, 0.76, 1.0), True, vertices=18, radius=0.205, depth=0.06, location=(0, 0.0, 1.06))                 # cinto
    objeto(C, d, (1.0, 0.8, 1.0), True, vertices=18, radius=0.15, depth=0.05, location=(0, 0.0, 1.5))                    # gola
    if placas:   # ferro: aresta no peito e rebites
        objeto(B, d, (0.012, 0.02, 0.2), True, size=2, location=(0, -0.132, 1.3))
        for x in (-0.12, 0.12):
            for z in (1.16, 1.4):
                objeto(S, d, (1, 1, 1), True, segments=6, ring_count=4, radius=0.016, location=(x, -0.112, z))
    else:        # couro: três tiras costuradas na frente e duas fivelas
        for z in (1.17, 1.28, 1.39):
            objeto(B, d, (0.19, 0.008, 0.012), True, size=2, location=(0, -0.13, z))
        for z in (1.2, 1.34):
            objeto(B, material("Fivela", (0.7, 0.6, 0.3), 0.8, 0.4), (0.022, 0.01, 0.022), False, size=2, location=(0.07, -0.138, z))
    exportar('armaduras', nome)
def ombreira(nome, cor, cor_detalhe, metal, raio):
    novo(); m = material("Base", cor, metal, 0.5 if metal else 0.8); d = material("Detalhe", cor_detalhe, metal, 0.45)
    objeto(S, m, (1.0, 0.9, 0.75), True, segments=14, ring_count=8, radius=raio, location=(0.23, 0.0, 1.47))             # ombro ESQUERDO do Torin (+X)
    objeto(C, d, (1.0, 0.9, 1.0), True, vertices=14, radius=raio * 0.98, depth=0.025, location=(0.25, 0.0, 1.415), rotation=(0, 0.25, 0))
    exportar('armaduras', nome)
peitoral('peitoral_de_couro', (0.2, 0.11, 0.05), (0.1, 0.055, 0.03), 0.0, False)   # cores escuras: o couro saía creme ao sol
ombreira('ombreira_de_couro', (0.2, 0.11, 0.05), (0.1, 0.055, 0.03), 0.0, 0.085)
peitoral('peitoral_de_ferro', (0.36, 0.38, 0.42), (0.2, 0.21, 0.25), 0.7, True)
ombreira('ombreira_de_ferro', (0.36, 0.38, 0.42), (0.2, 0.21, 0.25), 0.7, 0.105)
