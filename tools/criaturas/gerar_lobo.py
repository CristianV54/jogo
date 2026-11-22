# Gera o lobo do jogo a partir do Wolf do "Animal Pack Vol.2" (Quaternius, CC0, baixado de opengameart.org/content/animated-animales-low-poly).
# O pacote só traz Idle e Walking; aqui nascem Walk (renomeada), Run (a caminhada acelerada), Jump (o bote do ataque) e Death
# (o lobo tomba de lado). Pelagem em tons de cinza e bege por vértice (costas escuras, barriga e focinho claros).
# Rodar:  Blender -b -P gerar_lobo.py -- ARQUIVO_Wolf.fbx RAIZ_DO_PROJETO
import bpy, sys, math
from mathutils import Vector, Euler
FBX, RAIZ = sys.argv[sys.argv.index("--") + 1], sys.argv[sys.argv.index("--") + 2]
ESCALA = 0.28   # o modelo original tem ~3 m de altura na cernelha; o lobo do jogo tem ~0,85 m

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=FBX)
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
malha = [o for o in bpy.data.objects if o.type == "MESH"][0]

# ---- animações: nomes do jogo
acoes = {a.name.split("|")[-1]: a for a in bpy.data.actions}
walk = acoes["Walking"]
walk.name = "Walk"
acoes["Idle"].name = "Idle"
run = walk.copy()
run.name = "Run"
for camada in run.layers:   # Blender 5: as curvas ficam em camadas > faixas > canais
    for faixa in camada.strips:
        for canal in faixa.channelbags:
            for fc in canal.fcurves:
                for kp in fc.keyframe_points:
                    kp.co.x = 1 + (kp.co.x - 1) * 0.5
                    kp.handle_left.x = 1 + (kp.handle_left.x - 1) * 0.5
                    kp.handle_right.x = 1 + (kp.handle_right.x - 1) * 0.5
run.use_fake_user = True


def eixo_que_abaixa(osso_nome, ponta_nome):
    """Qual eixo local do osso (e sinal) leva a ponta para baixo sem desviar para o lado."""
    pb = arm.pose.bones[osso_nome]
    ponta = arm.pose.bones[ponta_nome]
    melhor = (0.0, 0, 1.0)
    base = (arm.matrix_world @ ponta.tail).copy()
    for eixo in range(3):
        for sinal in (-1.0, 1.0):
            pb.rotation_mode = "XYZ"
            pb.rotation_euler = Euler([sinal * 0.5 if i == eixo else 0.0 for i in range(3)])
            bpy.context.view_layer.update()
            t = arm.matrix_world @ ponta.tail
            queda = base.z - t.z
            desvio = abs(t.y - base.y)
            pontos = queda - desvio
            if pontos > melhor[0]:
                melhor = (pontos, eixo, sinal)
            pb.rotation_euler = Euler((0, 0, 0))
    bpy.context.view_layer.update()
    return melhor[1], melhor[2]


def eixo_do_tombo(osso_nome):
    """Qual eixo local gira o corpo em volta do comprimento dele (a cabeça sobe ou desce de lado, em Y)."""
    pb = arm.pose.bones[osso_nome]
    ponta = arm.pose.bones["Bone.003"]
    base = (arm.matrix_world @ ponta.tail).copy()
    melhor = (0.0, 0, 1.0)
    for eixo in range(3):
        for sinal in (-1.0, 1.0):
            pb.rotation_mode = "XYZ"
            pb.rotation_euler = Euler([sinal * 0.5 if i == eixo else 0.0 for i in range(3)])
            bpy.context.view_layer.update()
            t = arm.matrix_world @ ponta.tail
            # cabeça vai para o lado (Y) e sobe pouco: é o tombo
            pontos = abs(t.y - base.y) - abs(t.z - base.z)
            if pontos > melhor[0]:
                melhor = (pontos, eixo, sinal * (1.0 if t.y > base.y else -1.0))
            pb.rotation_euler = Euler((0, 0, 0))
    bpy.context.view_layer.update()
    return melhor[1], melhor[2]


arm.animation_data_create()
arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.rotation_mode = "XYZ"
    pb.rotation_euler = Euler((0, 0, 0))
bpy.context.view_layer.update()
ex_pescoco, sn_pescoco = eixo_que_abaixa("Bone.002", "Bone.003")
ex_tronco, sn_tronco = eixo_que_abaixa("Bone.001", "Bone.003")
ex_tombo, sn_tombo = eixo_do_tombo("Bone")
print("EIXOS pescoço", ex_pescoco, sn_pescoco, "tronco", ex_tronco, sn_tronco, "tombo", ex_tombo, sn_tombo)


def novo(nome, quadros):
    """quadros: lista de (quadro, {osso: (eixo, ângulo)}); os ossos não citados ficam na pose de descanso."""
    a = bpy.data.actions.new(nome)
    a.use_fake_user = True
    arm.animation_data.action = a
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
    for q, ossos in quadros:
        for pb in arm.pose.bones:
            ang = ossos.get(pb.name)
            pb.rotation_euler = Euler([ang[1] if (ang and i == ang[0]) else 0.0 for i in range(3)])
            pb.keyframe_insert("rotation_euler", frame=q)
    return a


# Jump = bote: agacha o tronco, estica o pescoço para baixo e morde, volta
bote = novo("Jump", [
    (1, {}),
    (6, {"Bone.001": (ex_tronco, sn_tronco * -0.25), "Bone.002": (ex_pescoco, sn_pescoco * -0.35)}),
    (10, {"Bone.001": (ex_tronco, sn_tronco * 0.3), "Bone.002": (ex_pescoco, sn_pescoco * 0.5), "Bone.003": (ex_pescoco, sn_pescoco * 0.25)}),
    (14, {"Bone.001": (ex_tronco, sn_tronco * 0.1), "Bone.002": (ex_pescoco, sn_pescoco * 0.2)}),
    (20, {}),
])
# Death = tomba de lado e fica
morte = novo("Death", [
    (1, {}),
    (10, {"Bone": (ex_tombo, sn_tombo * 0.9), "Bone.002": (ex_pescoco, sn_pescoco * 0.15)}),
    (18, {"Bone": (ex_tombo, sn_tombo * 1.45), "Bone.002": (ex_pescoco, sn_pescoco * 0.25)}),
    (24, {"Bone": (ex_tombo, sn_tombo * 1.5), "Bone.002": (ex_pescoco, sn_pescoco * 0.25)}),
])
for a in (acoes["Idle"], walk, run):
    a.use_fake_user = True

# ---- as pernas andam por IK no Blender e o glTF só leva ossos comuns: assa o movimento visto nos ossos (uma ação por vez)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.select_all(action="SELECT")
for nome in ("Idle", "Walk", "Run"):
    a = bpy.data.actions[nome]
    arm.animation_data.action = a
    ini, fim = int(a.frame_range[0]), int(a.frame_range[1])
    bpy.ops.nla.bake(frame_start=ini, frame_end=fim, only_selected=False, visual_keying=True, clear_constraints=False,
                     use_current_action=True, bake_types={"POSE"})
    print("ASSADA", nome, ini, fim)
bpy.ops.object.mode_set(mode="OBJECT")

# ---- pelagem por vértice
mat = bpy.data.materials["Wolf"]
mat.use_nodes = True
nt = mat.node_tree
col = malha.data.color_attributes.new("Col", "BYTE_COLOR", "POINT")
malha.data.color_attributes.active_color = col
malha.data.color_attributes.render_color_index = malha.data.color_attributes.find("Col")
mm = malha.matrix_world
zs = [(mm @ v.co).z for v in malha.data.vertices]
z0, z1 = min(zs), max(zs)
xs = [(mm @ v.co).x for v in malha.data.vertices]
for i, v in enumerate(malha.data.vertices):
    p = mm @ v.co
    h = (p.z - z0) / max(z1 - z0, 1e-5)           # 0 pé, 1 costas/orelha
    nz = v.normal.z
    costas = max(0.0, min(1.0, (nz + 0.1) * 1.1 + (h - 0.6)))
    escuro = Vector((0.4, 0.37, 0.34))
    medio = Vector((0.66, 0.6, 0.5))
    claro = Vector((0.9, 0.87, 0.8))
    c = medio.lerp(escuro, costas) if nz > -0.15 else medio.lerp(claro, min(1.0, -nz * 1.3))
    if h < 0.35:                                   # patas mais claras em cima, escuras nos pés
        c = c.lerp(Vector((0.34, 0.3, 0.27)), 0.35)
    col.data[i].color = (c.x ** 2.2, c.y ** 2.2, c.z ** 2.2, 1.0)
vc = nt.nodes.new("ShaderNodeVertexColor")
vc.layer_name = "Col"
bsdf = nt.nodes["Principled BSDF"]
nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 1.0

# ---- orientação (frente = -Y do Blender, como os outros animais) e tamanho
arm.rotation_euler = Euler((0, 0, -math.pi / 2))
arm.scale = Vector((arm.scale.x, arm.scale.y, arm.scale.z)) * ESCALA
for o in bpy.data.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = arm
arm.animation_data.action = acoes["Idle"]
destino = f"{RAIZ}/assets/models/criaturas/lobo/lobo.glb"
bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="ACTIONS", export_apply=False, export_yup=True, export_image_format="AUTO",
                          export_force_sampling=True, export_vertex_color="ACTIVE", export_active_vertex_color_when_no_material=True)
print("EXPORTADO", destino)
