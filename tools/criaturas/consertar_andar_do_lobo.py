# Conserta as animações do lobo JÁ exportado (assets/models/criaturas/lobo/lobo.glb), sem precisar do FBX original.
# Defeito: em Walk e Run só os ossos-alvo de IK (IKFrontLeft...) se mexiam; os ossos das pernas, que puxam a malha, ficavam
# parados, e o lobo deslizava como estátua. Idle não mexia nada.
# O que faz: religa cada perna ao seu alvo de IK (como no rig do pacote), grava quadro a quadro a pose que resulta nos ossos
# das pernas, tira o IK, cria um Idle com respiração (pescoço, cabeça e rabo), refaz a morte (tombar de lado) e exporta de novo o .glb.
# Rodar (Blender 5.3 ou o módulo bpy 5.3):  blender -b -P consertar_andar_do_lobo.py -- RAIZ_DO_PROJETO
import bpy, sys, math
from mathutils import Matrix

RAIZ = sys.argv[-1]
ARQ = f"{RAIZ}/assets/models/criaturas/lobo/lobo.glb"
# perna: (coxa, canela, pata, alvo de IK)
PERNAS = [("Bone.014", "Bone.015", "Bone.016", "IKFrontRight"), ("Bone.017", "Bone.018", "Bone.019", "IKFrontLeft"),
          ("Bone.008", "Bone.009", "Bone.010", "IKBackLeft"), ("Bone.011", "Bone.012", "Bone.013", "IKBackRight")]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=ARQ)
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
malha = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm][0]
for o in list(bpy.data.objects):
    if o not in (arm, malha):
        bpy.data.objects.remove(o)   # formas de osso que o importador cria
cena = bpy.context.scene
bpy.context.view_layer.objects.active = arm
pb = arm.pose.bones
for b in pb:
    b.rotation_mode = "QUATERNION"


def usar(acao):
    arm.animation_data.action = acao
    if hasattr(arm.animation_data, "action_slot") and len(acao.slots) > 0:
        arm.animation_data.action_slot = acao.slots[0]


def gravar(nomes, quadro):
    for n in nomes:
        pb[n].keyframe_insert("location", frame=quadro)
        pb[n].keyframe_insert("rotation_quaternion", frame=quadro)


# ---- 1) pernas: IK ligado, lê a pose de cada quadro; IK desligado, grava a mesma pose nos ossos
ossos_pernas = [n for p in PERNAS for n in p[:3]]
for nome in ("Walk", "Run"):
    acao = bpy.data.actions[nome]
    usar(acao)
    restricoes = []
    for coxa, canela, pata, alvo in PERNAS:
        ik = pb[pata].constraints.new("IK")
        ik.target = arm
        ik.subtarget = alvo
        ik.chain_count = 3
        ik.use_tail = False
        giro = pb[pata].constraints.new("COPY_ROTATION")   # a pata fica com a inclinação do alvo
        giro.target = arm
        giro.subtarget = alvo
        restricoes += [(pata, ik), (pata, giro)]
    ini, fim = int(acao.frame_range[0]), int(acao.frame_range[1])
    poses = {}
    for q in range(ini, fim + 1):
        cena.frame_set(q)
        bpy.context.view_layer.update()
        poses[q] = {n: pb[n].matrix.copy() for n in ossos_pernas}
    for pata, r in restricoes:
        pb[pata].constraints.remove(r)
    for q in range(ini, fim + 1):
        cena.frame_set(q)
        for coxa, canela, pata, alvo in PERNAS:
            for n in (coxa, canela, pata):   # do pai para o filho
                pb[n].matrix = poses[q][n]
                bpy.context.view_layer.update()
        gravar(ossos_pernas, q)
    print("PERNAS GRAVADAS", nome, ini, fim)

# ---- 2) Idle: respiração leve (pescoço e cabeça sobem e descem, rabo balança), 41 quadros que fecham em laço
acao = bpy.data.actions["Idle"]
usar(acao)
cena.frame_set(1)
bpy.context.view_layer.update()
base = {n: pb[n].matrix.copy() for n in ("Bone.002", "Bone.003", "Bone.004", "Bone.005")}
ini, fim = 1, 41
for q in range(ini, fim + 1):
    fase = 2.0 * math.pi * (q - ini) / (fim - ini)
    cena.frame_set(q)
    for n, eixo, graus, atraso in (("Bone.002", "Y", 2.5, 0.0), ("Bone.003", "Y", -2.0, 0.6), ("Bone.004", "Z", 7.0, 0.0), ("Bone.005", "Z", 5.0, 0.8)):
        m = base[n]
        c = m.to_translation()
        g = Matrix.Rotation(math.radians(graus) * math.sin(fase - atraso), 4, eixo)
        pb[n].matrix = Matrix.Translation(c) @ g @ Matrix.Translation(-c) @ m
        bpy.context.view_layer.update()
    gravar(["Bone.002", "Bone.003", "Bone.004", "Bone.005"], q)
print("IDLE GRAVADO")

# ---- 3) Death: a antiga girava o lobo de pé em volta do eixo vertical (ele virava de lado e continuava em pé).
# Agora ele tomba de verdade: o corpo todo rola 90 graus em volta do eixo do comprimento (X), apoiado nas patas de um lado.
acao = bpy.data.actions["Death"]
usar(acao)
base_raiz = arm.data.bones["Bone"].matrix_local.copy()   # pose de repouso do osso raiz (não a pose da animação antiga)
apoio = Matrix.Translation((0.0, -0.45, 0.0))   # linha das patas direitas no chão
for q in range(1, 25):
    t = min(1.0, (q - 1) / 17.0)
    suave = t * t * (3.0 - 2.0 * t)
    cena.frame_set(q)
    g = Matrix.Rotation(math.radians(90.0) * suave, 4, "X")
    pb["Bone"].matrix = apoio @ g @ apoio.inverted() @ base_raiz
    bpy.context.view_layer.update()
    gravar(["Bone"], q)
print("DEATH GRAVADA")

# ---- 4) exporta com as mesmas opções de tools/criaturas/gerar_lobo.py
usar(bpy.data.actions["Idle"])
for o in bpy.data.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=ARQ, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="ACTIONS", export_apply=False, export_yup=True, export_image_format="AUTO",
                          export_force_sampling=True, export_vertex_color="ACTIVE", export_active_vertex_color_when_no_material=True)
print("EXPORTADO", ARQ)
