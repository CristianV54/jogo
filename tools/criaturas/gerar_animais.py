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


def material(nome, rgb):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Alpha"].default_value = 1.0
    return m


def peca(arm, osso, mat, prim, **kw):
    """Cria uma peça (cone etc.) em coordenadas do mundo do Blender e a prende ao osso, para acompanhar a animação."""
    prim(**kw)
    o = bpy.context.active_object
    o.data.materials.append(mat)
    o.parent = arm
    o.matrix_parent_inverse = arm.matrix_world.inverted()
    vg = o.vertex_groups.new(name=osso)
    vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    mod = o.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    return o


def cone(arm, osso, mat, base, ponta, raio1, raio2, vertices=8):
    """Cone/tronco de cone que vai do ponto 'base' ao ponto 'ponta' (mundo do Blender)."""
    from mathutils import Vector
    b, p = Vector(base), Vector(ponta)
    eixo = p - b
    meio = (b + p) / 2
    rot = Vector((0, 0, 1)).rotation_difference(eixo.normalized()).to_euler()
    return peca(arm, osso, mat, bpy.ops.mesh.primitive_cone_add, vertices=vertices, radius1=raio1, radius2=raio2,
                depth=eixo.length, location=meio, rotation=rot)


def ajuste_lobo(arm):
    """Cachorro (pug) vira lobo: focinho comprido, nariz, orelhas em pé e rabo cheio. Frente é -Y, alto é +Z."""
    pelo = bpy.data.materials["Beige"]
    escuro = material("LoboNariz", (0.02, 0.02, 0.025))
    cone(arm, "Head", pelo, (0, -1.85, 2.15), (0, -2.6, 2.1), 0.24, 0.1)
    peca(arm, "Head", escuro, bpy.ops.mesh.primitive_uv_sphere_add, segments=8, ring_count=6, radius=0.1, location=(0, -2.62, 2.1))
    for lado in (-1, 1):
        cone(arm, "Head", pelo, (lado * 0.36, -1.45, 2.55), (lado * 0.5, -1.5, 3.2), 0.2, 0.02, 5)
    cone(arm, "Hips", pelo, (0, 1.4, 1.6), (0, 1.95, 0.7), 0.2, 0.05)


def ajuste_javali(arm):
    """Porco vira javali: presas de marfim, nariz escuro e crina de cerdas no dorso."""
    corpo = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm][0]
    pts = [corpo.matrix_world @ v.co for v in corpo.data.vertices]
    marfim = material("JavaliPresa", (0.6, 0.52, 0.36))
    cerda = material("JavaliCerda", (0.015, 0.01, 0.008))
    for lado in (-1, 1):
        cone(arm, "Head", marfim, (lado * 0.42, -4.75, 2.05), (lado * 0.62, -5.2, 2.95), 0.13, 0.02, 6)
    for i in range(7):
        y = -1.2 + i * 0.55
        zmax = max(p.z for p in pts if abs(p.x) < 1.2 and abs(p.y - y) < 0.7)
        osso = "Torso" if y < 0.45 else "Hips"
        cone(arm, osso, cerda, (0, y, zmax - 0.15), (0, y + 0.1, zmax + 0.55), 0.17, 0.02, 5)


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
    # o lobo agora vem de tools/criaturas/gerar_lobo.py (Wolf do Quaternius); aqui o javali ainda é o porco em marrom escuro
    montar("javali", "Pig", {"Material": (0.02, 0.015, 0.01), "Material.003": (0.06, 0.04, 0.03)}, ajuste_javali)
