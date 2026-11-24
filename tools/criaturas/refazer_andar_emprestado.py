# Refaz o andar que a ovelha, o porco, o cão e o javali pegaram emprestado da vaca (Walk, WalkSlow e Run).
# Defeito: a rotação de cada osso da vaca tinha sido copiada crua. Como as pernas e o corpo de cada bicho têm outra proporção,
# ele andava agachado, com as pernas dobradas e os cascos fora do chão.
# O que faz, direto nos .glb do projeto (não precisa dos FBX originais):
#   1) lê da vaca, quadro a quadro, onde cada casco está e quanto o corpo, a coluna, o pescoço e o rabo giram em relação ao repouso;
#   2) no bicho de destino, põe cada casco no mesmo lugar, na escala das pernas dele, e deixa o IK dobrar a perna;
#      corpo, coluna, pescoço e rabo recebem o mesmo giro, medido no espaço do esqueleto (não a rotação crua do osso);
#   3) grava a pose em todos os ossos, tira o IK e exporta com as opções de tools/criaturas/gerar_animais.py.
# Rodar (Blender 5.3 ou o módulo bpy 5.3):  blender -b -P refazer_andar_emprestado.py -- RAIZ_DO_PROJETO [bicho ...]
import bpy, sys
from mathutils import Matrix

args = sys.argv[sys.argv.index("--") + 1:]
RAIZ = args[0]
DESTINOS = args[1:] or ["ovelha", "porco", "cao", "javali"]
ACOES = ("Walk-loop", "WalkSlow-loop", "Run-loop")
# bicho -> (passada, giro do tronco), frações do movimento da vaca. No porco, no javali e no cão a coxa fica dentro do corpo:
# passada inteira esticava a pele do corpo em pernas finas e compridas, e o giro inteiro do tronco enfiava o focinho no chão.
# No cão o IK torcia as pernas (a malha ficava fina e comprida): nele as pernas recebem o giro da vaca reduzido pela passada.
SEM_IK = ("cao",)
AJUSTE = {"ovelha": (1.0, 1.0), "porco": (0.6, 0.35), "javali": (0.6, 0.35), "cao": (0.45, 0.6)}
PERNAS = ("BackLowLeg.L", "BackLowLeg.R", "FrontLowLeg.L", "FrontLowLeg.R")   # canela; o casco é o osso "<canela>_end"
ALVO_DE = {"BackLowLeg.L": "BackFoot.L", "BackLowLeg.R": "BackFoot.R", "FrontLowLeg.L": "FrontFoot.L", "FrontLowLeg.R": "FrontFoot.R"}
COXA_DE = {"BackLowLeg.L": "BackUpLeg.L", "BackLowLeg.R": "BackUpLeg.R", "FrontLowLeg.L": "FrontUpLeg.L", "FrontLowLeg.R": "FrontUpLeg.R"}


def abrir(nome):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f"{RAIZ}/assets/models/criaturas/{nome}/{nome}.glb")
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    for o in list(bpy.data.objects):
        if o is not arm and o.parent is None:
            bpy.data.objects.remove(o)   # formas de osso que o importador cria
    bpy.context.view_layer.objects.active = arm
    for b in arm.pose.bones:
        b.rotation_mode = "QUATERNION"
    return arm


def usar(arm, acao):
    arm.animation_data.action = acao
    if hasattr(arm.animation_data, "action_slot") and len(acao.slots) > 0:
        arm.animation_data.action_slot = acao.slots[0]


# ---- 1) a vaca: giro de cada osso em relação ao repouso (no espaço do esqueleto), deslocamento do corpo e dos cascos
def pose_parada(arm):
    """Pose do primeiro quadro de Idle: é o corpo "de pé" de verdade (no cão, o tamanho das pernas vem dela, não do esqueleto em repouso)."""
    usar(arm, bpy.data.actions["Idle-loop"])
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    return {b.name: b.matrix.copy() for b in arm.pose.bones}, {b.name: b.matrix_basis.copy() for b in arm.pose.bones}


vaca = abrir("vaca")
repouso_vaca, _ = pose_parada(vaca)
altura_vaca = {p: repouso_vaca[COXA_DE[p]].to_translation().z - repouso_vaca[p + "_end"].to_translation().z for p in PERNAS}
fonte = {}
for nome in ACOES:
    acao = bpy.data.actions[nome]
    usar(vaca, acao)
    ini, fim = int(acao.frame_range[0]), int(acao.frame_range[1])
    quadros = []
    for q in range(ini, fim + 1):
        bpy.context.scene.frame_set(q)
        bpy.context.view_layer.update()
        giros = {}
        for pb in vaca.pose.bones:
            giros[pb.name] = pb.matrix.to_3x3().normalized() @ repouso_vaca[pb.name].to_3x3().normalized().inverted()
        corpo = vaca.pose.bones["Body"].matrix.to_translation() - repouso_vaca["Body"].to_translation()
        cascos = {p: vaca.pose.bones[p + "_end"].matrix.to_translation() - repouso_vaca[p + "_end"].to_translation() for p in PERNAS}
        quadros.append((giros, corpo, cascos))
    fonte[nome] = (ini, quadros)
    print("VACA LIDA", nome, len(quadros))

# ---- 2 e 3) cada bicho de destino
for bicho in DESTINOS:
    arm = abrir(bicho)
    pb = arm.pose.bones
    repouso, base = pose_parada(arm)
    ordem = [b.name for b in arm.data.bones]   # pais antes dos filhos
    escala = {p: (repouso[COXA_DE[p]].to_translation().z - repouso[p + "_end"].to_translation().z) / altura_vaca[p] for p in PERNAS}
    escala_corpo = sum(escala.values()) / len(escala)
    # o corpo não desce mais que 1/5 da perna (a barriga do porco arrastava no chão)
    passada, giro_do_tronco = AJUSTE.get(bicho, (1.0, 1.0))
    altura_perna = sum(repouso[COXA_DE[p]].to_translation().z - repouso[p + "_end"].to_translation().z for p in PERNAS) / len(PERNAS)
    identidade = Matrix.Identity(3).to_quaternion()
    print("PROPORCAO", bicho, "pernas", round(escala_corpo, 2), "passada", passada, "giro do tronco", giro_do_tronco)
    da_perna = set()
    for p in PERNAS:
        da_perna |= {p, p + "_end", COXA_DE[p]}
    giro_direto = set()
    if bicho in SEM_IK:
        giro_direto = da_perna
        da_perna = set()
    for nome in ACOES:
        acao = bpy.data.actions[nome]
        usar(arm, acao)
        ini, quadros = fonte[nome]
        restricoes = []
        for p in (PERNAS if bicho not in SEM_IK else ()):
            ik = pb[p + "_end"].constraints.new("IK")
            ik.target = arm
            ik.subtarget = ALVO_DE[p]
            ik.chain_count = 3
            ik.use_tail = False
            restricoes.append((p + "_end", ik))
        poses = []
        for i, (giros, corpo, cascos) in enumerate(quadros):
            bpy.context.scene.frame_set(ini + i)
            for b in pb:
                b.matrix_basis = base[b.name]
            bpy.context.view_layer.update()
            for n in ordem:
                if n in da_perna or n not in giros:
                    continue
                if n in ALVO_DE.values():   # alvo do casco: mesma passada da vaca, na escala da perna deste bicho
                    canela = [c for c, a in ALVO_DE.items() if a == n][0]
                    lugar = repouso[n].to_translation() + cascos[canela] * escala[canela] * passada
                    pb[n].matrix = Matrix.Translation(lugar) @ repouso[n].to_3x3().to_4x4()
                else:
                    lugar = pb[n].matrix.to_translation()   # onde o pai o deixou
                    giro = giros[n]
                    if n in giro_direto:
                        giro = identidade.slerp(giro.to_quaternion(), passada).to_matrix()
                    if n == "Body":
                        desce = corpo * escala_corpo * passada
                        desce.z = max(desce.z, -0.2 * altura_perna)
                        lugar = repouso[n].to_translation() + desce
                        giro = identidade.slerp(giro.to_quaternion(), giro_do_tronco).to_matrix()
                    pb[n].matrix = Matrix.Translation(lugar) @ (giro @ repouso[n].to_3x3()).to_4x4()
                bpy.context.view_layer.update()
            poses.append({n: pb[n].matrix.copy() for n in ordem})
        for n, r in restricoes:
            pb[n].constraints.remove(r)
        for i, pose in enumerate(poses):
            bpy.context.scene.frame_set(ini + i)
            for n in ordem:
                pb[n].matrix = pose[n]
                bpy.context.view_layer.update()
            for n in ordem:
                pb[n].keyframe_insert("location", frame=ini + i)
                pb[n].keyframe_insert("rotation_quaternion", frame=ini + i)
                pb[n].keyframe_insert("scale", frame=ini + i)
        print("REFEITA", bicho, nome, len(poses))
    usar(arm, bpy.data.actions["Idle-loop"])
    for o in bpy.data.objects:
        o.select_set(True)
    destino = f"{RAIZ}/assets/models/criaturas/{bicho}/{bicho}.glb"
    bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_apply=False, export_yup=True, export_image_format="AUTO")
    print("EXPORTADO", destino)
