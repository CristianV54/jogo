# Gera os animais do jogo a partir do pacote Farm Animals (Quaternius, CC0), só leitura.
# Vaca e cavalo vêm com Idle, Walk, WalkSlow, Run, Jump e Death. Ovelha, porco e cachorro só vêm com Idle e Jump:
# o esqueleto é o mesmo (muda só a cauda), então a rotação de cada osso do Walk/Run/Death da vaca é copiada quadro a quadro.
# Rodar:  Blender -b -P gerar_animais.py -- RAIZ_DO_PROJETO
import bpy, sys, os
RAIZ = sys.argv[sys.argv.index("--") + 1]
PASTA = "/Volumes/Extreme SSD/JOGO/modelos-3d/pacotes_livres/animais/Farmx20Animalsx20byx20x40Quaternius/Farm Animals by @Quaternius/FBX/"
EMPRESTADAS = ("Walk", "WalkSlow", "Run", "Death")   # animações da vaca que as outras recebem
EM_LOOP = ("Idle", "Walk", "WalkSlow", "Run")


def cena_vazia():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def importar(nome):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=PASTA + nome + ".fbx")
    novos = [o for o in bpy.data.objects if o not in antes]
    return [o for o in novos if o.type == "ARMATURE"][0], [o for o in novos if o.type == "MESH"]


def cor(nome_mat, rgb):
    m = bpy.data.materials.get(nome_mat)
    if m is None:
        print("AVISO material inexistente", nome_mat, [x.name for x in bpy.data.materials])
        return
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    if b:
        b.inputs["Base Color"].default_value = (*rgb, 1)


def acao_do_osso(origem_arm, acao):
    """Lê a pose de cada osso da origem em todos os quadros da ação: {quadro: {osso: (modo, valor)}}."""
    origem_arm.animation_data_create()
    origem_arm.animation_data.action = acao
    inicio, fim = int(acao.frame_range[0]), int(acao.frame_range[1])
    quadros = {}
    for q in range(inicio, fim + 1):
        bpy.context.scene.frame_set(q)
        quadros[q] = {}
        for pb in origem_arm.pose.bones:
            quadros[q][pb.name] = (pb.rotation_mode, tuple(pb.rotation_quaternion) if pb.rotation_mode == "QUATERNION" else tuple(pb.rotation_euler))
    return quadros, inicio, fim


def aplicar_no_destino(destino, nome, quadros, inicio):
    destino.animation_data_create()
    nova = bpy.data.actions.new(nome)
    destino.animation_data.action = nova
    for q, ossos in quadros.items():
        for nome_osso, (modo, valor) in ossos.items():
            pb = destino.pose.bones.get(nome_osso)
            if pb is None:
                continue
            pb.rotation_mode = modo
            if modo == "QUATERNION":
                pb.rotation_quaternion = valor
                pb.keyframe_insert("rotation_quaternion", frame=q - inicio + 1)
            else:
                pb.rotation_euler = valor
                pb.keyframe_insert("rotation_euler", frame=q - inicio + 1)
    destino.animation_data.action = None
    return nova


def empurrar_para_nla(arm, acao, nome):
    ad = arm.animation_data_create()
    trilha = ad.nla_tracks.new()
    trilha.name = nome + ("-loop" if nome in EM_LOOP else "")
    trilha.strips.new(trilha.name, int(acao.frame_range[0]), acao)


def exportar(nome_saida):
    destino = f"{RAIZ}/assets/models/criaturas/{nome_saida}/{nome_saida}.glb"
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="NLA_TRACKS", export_apply=False, export_yup=True, export_image_format="AUTO")
    print("EXPORTADO", destino, os.path.getsize(destino))


def curto(acao):
    return acao.name.split("|")[-1]


def montar(nome_saida, arquivo, cores, ajuste=None):
    """Importa o animal, dá a ele as animações da vaca que faltam, pinta e exporta."""
    cena_vazia()
    vaca, malhas_vaca = importar("Cow")
    if arquivo == "Cow":
        alvo = vaca
        for a in list(bpy.data.actions):
            empurrar_para_nla(alvo, a, curto(a))
    else:
        emprestadas = {}
        for a in list(bpy.data.actions):
            if curto(a) in EMPRESTADAS:
                quadros, ini, fim = acao_do_osso(vaca, a)
                emprestadas[curto(a)] = (quadros, ini)
        for o in malhas_vaca + [vaca]:
            bpy.data.objects.remove(o, do_unlink=True)
        for a in list(bpy.data.actions):
            bpy.data.actions.remove(a)
        alvo, _ = importar(arquivo)
        if arquivo == "Horse":
            for a in list(bpy.data.actions):
                empurrar_para_nla(alvo, a, curto(a))
        else:
            for a in list(bpy.data.actions):
                if curto(a) in ("Idle", "Jump"):
                    a.name = curto(a)
                    empurrar_para_nla(alvo, a, a.name)
            for n, (quadros, ini) in emprestadas.items():
                empurrar_para_nla(alvo, aplicar_no_destino(alvo, n, quadros, ini), n)
    for m in bpy.data.materials:   # o FBX do pacote traz alfa 0: sem isto o animal fica invisível no Godot
        m.use_nodes = True
        b = m.node_tree.nodes.get("Principled BSDF")
        if b:
            b.inputs["Alpha"].default_value = 1.0
        m.blend_method = "OPAQUE"
    for mat, rgb in cores.items():
        cor(mat, rgb)
    if ajuste:
        ajuste(alvo)
    exportar(nome_saida)


def listar():
    cena_vazia()
    for a in ("Cow", "Horse", "Sheep", "Pig", "Pug"):
        arm, malhas = importar(a)
        print("MATERIAIS", a, [m.name for m in bpy.data.materials])
        cena_vazia()


if "--listar" in sys.argv:
    listar()
else:
    montar("vaca", "Cow", {})
    montar("cavalo", "Horse", {})
    montar("ovelha", "Sheep", {})
    montar("porco", "Pig", {})
    montar("cao", "Pug", {})
    # PLACEHOLDER_: lobo é o cachorro (Pug) em cinza e javali é o porco em marrom escuro, agora com andar, corrida e morte de verdade
    montar("lobo", "Pug", {"Beige": (0.18, 0.18, 0.2), "Brown": (0.05, 0.05, 0.06)})
    montar("javali", "Pig", {"Material": (0.02, 0.015, 0.01), "Material.003": (0.06, 0.04, 0.03)})
