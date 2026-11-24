# Modela a galinha (low-poly, cor chapada, ~0,4 m): Corpo e Cabeca são nós separados, para o Godot balançar a cabeça (bicar).
# A origem de Cabeca fica no pescoço. Frente = -Y no Blender (vira +Z no Godot).
# Rodar:  Blender -b -P gerar_galinha.py -- RAIZ_DO_PROJETO
import bpy, sys, os, math
RAIZ = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(nome, rgb):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = 0.9
    return m


PENAS = mat("Penas", (0.75, 0.7, 0.6))
ASAS = mat("Asas", (0.55, 0.45, 0.33))
CRISTA = mat("Crista", (0.6, 0.03, 0.03))
BICO = mat("Bico", (0.8, 0.45, 0.05))
PERNAS = mat("Pernas", (0.7, 0.4, 0.05))


def peca(prim, material, loc, escala=(1, 1, 1), rot=(0, 0, 0), **kw):
    prim(location=loc, rotation=rot, **kw)
    o = bpy.context.active_object
    o.scale = escala
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    o.data.materials.append(material)
    for p in o.data.polygons:
        p.use_smooth = False
    return o


S = bpy.ops.mesh.primitive_uv_sphere_add
C = bpy.ops.mesh.primitive_cylinder_add
K = bpy.ops.mesh.primitive_cone_add

# corpo (tudo que não é cabeça): peito, cauda, asas, pernas
corpo = [
    peca(S, PENAS, (0, 0, 0.22), (0.11, 0.16, 0.11), segments=8, ring_count=6, radius=1),
    peca(K, ASAS, (0, 0.17, 0.3), (0.05, 0.12, 0.12), (math.radians(-60), 0, 0), vertices=5, radius1=1, radius2=0.1, depth=1),
    peca(S, ASAS, (0.105, 0.0, 0.23), (0.03, 0.1, 0.07), segments=6, ring_count=4, radius=1),
    peca(S, ASAS, (-0.105, 0.0, 0.23), (0.03, 0.1, 0.07), segments=6, ring_count=4, radius=1),
]
# pescoço: liga o peito à cabeça (sem ele a cabeça ficava solta no ar, 5 cm acima do corpo)
corpo.append(peca(K, PENAS, (0, -0.115, 0.3), (0.05, 0.05, 0.15), (math.radians(35), 0, 0), vertices=7, radius1=1, radius2=0.75, depth=1))
for x in (-0.04, 0.04):
    corpo.append(peca(C, PERNAS, (x, -0.01, 0.07), (0.012, 0.012, 0.07), vertices=5, radius=1, depth=1))
    corpo.append(peca(S, PERNAS, (x, -0.03, 0.01), (0.03, 0.04, 0.012), segments=5, ring_count=3, radius=1))
for o in corpo:
    o.select_set(True)
bpy.context.view_layer.objects.active = corpo[0]
bpy.ops.object.join()
bpy.context.active_object.name = "Corpo"

# cabeça: origem no pescoço (0, -0.12, 0.32); bico aponta para -Y
cab = [
    peca(S, PENAS, (0, -0.15, 0.37), (0.055, 0.06, 0.06), segments=8, ring_count=5, radius=1),
    peca(K, BICO, (0, -0.215, 0.365), (0.02, 0.02, 0.03), (math.radians(90), 0, 0), vertices=4, radius1=1, radius2=0.05, depth=1),
    peca(S, CRISTA, (0, -0.15, 0.43), (0.012, 0.035, 0.03), segments=5, ring_count=3, radius=1),
    peca(S, CRISTA, (0, -0.2, 0.335), (0.012, 0.015, 0.03), segments=5, ring_count=3, radius=1),
]
for o in cab:
    o.select_set(True)
bpy.context.view_layer.objects.active = cab[0]
bpy.ops.object.join()
c = bpy.context.active_object
c.name = "Cabeca"
bpy.context.scene.cursor.location = (0, -0.12, 0.32)
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

bpy.ops.object.select_all(action="SELECT")
destino = f"{RAIZ}/assets/models/criaturas/corvo/corvo.glb"   # hoje este modelo simples é só a base do corvo; a galinha do jogo vem de preparar_galinha_e_coelho.py
os.makedirs(os.path.dirname(destino), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)
print("EXPORTADO", destino, os.path.getsize(destino))
