# Prepara a galinha e o coelho novos (CC0, Snabisch / OpenGameArt) para o jogo, a partir dos .blend originais:
#   galinha: https://opengameart.org/content/chicken-animated  (chickenV2.blend, autor Čestmír Dammer, CC0)
#   coelho:  https://opengameart.org/content/rabbit-0          (rabbit.blend, CC0)
# O que faz: tira o que não é o bicho (câmera, luzes, plano, uma malha de escultura que vem junto com a galinha e a casca de pelo
# do coelho), religa a textura que vem embutida no arquivo (os materiais são do Blender antigo e ela não estava ligada nos nós),
# deixa só as animações que o jogo usa, com os nomes do jogo, põe no tamanho certo e exporta o .glb.
# Rodar (Blender 5.3 ou bpy 5.3):  blender -b -P preparar_galinha_e_coelho.py -- RAIZ_DO_PROJETO chickenV2.blend rabbit.blend
import bpy, sys, os
from mathutils import Vector

RAIZ, ARQ_GALINHA, ARQ_COELHO = sys.argv[sys.argv.index("--") + 1:][:3]

# bicho -> arquivo, malhas que ficam, textura de cor, {ação do arquivo: nome no jogo}, medida de referência (eixo, metros)
BICHOS = {
    "galinha": {"arquivo": ARQ_GALINHA, "malhas": ("Chicken", "Eyes"), "textura": "UV-Texture.png", "materiais_com_textura": ("Chicken",),
                "acoes": {"Idle": "Idle-loop", "Walk": "WalkSlow-loop", "Eating": "Eating-loop", "Dying": "Death"}, "altura": 0.46},
    "coelho": {"arquivo": ARQ_COELHO, "malhas": ("Rabbit",), "textura": "rabbot-skinn", "materiais_com_textura": ("Fur.001",),
               "acoes": {"Sitting.000": "Idle-loop", "Running": "Run-loop", "Jump": "Jump", "Dying.000": "Death"}, "altura": 0.34},
}

for nome, cfg in BICHOS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.open_mainfile(filepath=cfg["arquivo"], load_ui=False, use_scripts=False)
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    for o in list(bpy.data.objects):
        if o is not arm and o.name not in cfg["malhas"]:
            bpy.data.objects.remove(o)
    malhas = [o for o in bpy.data.objects if o.type == "MESH"]
    # textura embutida: carrega os pontos e liga na cor do material
    img = bpy.data.images[cfg["textura"]]
    _ = img.pixels[0]
    # materiais novos (os do arquivo são do Blender antigo e o exportador não lê a cor nem a textura deles)
    novos = {}
    for o in malhas:
        for vaga in o.material_slots:
            velho = vaga.material
            if velho is None:
                continue
            if velho.name not in novos:
                m = bpy.data.materials.new(nome.capitalize() + "_" + velho.name.replace(".", "_"))
                m.use_nodes = True
                bsdf = m.node_tree.nodes["Principled BSDF"]
                bsdf.inputs["Roughness"].default_value = 0.9
                if velho.name in cfg["materiais_com_textura"]:
                    tex = m.node_tree.nodes.new("ShaderNodeTexImage")
                    tex.image = img
                    m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
                else:
                    c = velho.diffuse_color
                    bsdf.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1.0)
                novos[velho.name] = m
            vaga.material = novos[velho.name]
    for o in malhas:   # a primeira camada de UV é a da textura final
        if o.data.uv_layers:
            o.data.uv_layers.active = o.data.uv_layers[0]
            o.data.uv_layers[0].active_render = True
    # só as animações do jogo, com os nomes do jogo
    for a in list(bpy.data.actions):
        if a.name in cfg["acoes"]:
            a.name = cfg["acoes"][a.name]
            a.use_fake_user = True
        else:
            bpy.data.actions.remove(a)
    # tamanho: a altura das malhas (sem as orelhas, no coelho, a medida é o dorso) vira a altura pedida
    topo = max((o.matrix_world @ Vector(c)).z for o in malhas for c in o.bound_box)
    if nome == "coelho":
        topo = max((arm.matrix_world @ arm.data.bones[b].head_local).z for b in ("Hips", "Spine", "Spine.001")) * 1.25
    arm.scale = arm.scale * (cfg["altura"] / topo)
    parada = bpy.data.actions.get("Idle-loop")
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = parada
    if hasattr(arm.animation_data, "action_slot") and parada and len(parada.slots) > 0:
        arm.animation_data.action_slot = parada.slots[0]
    for o in bpy.data.objects:
        o.hide_set(False)
        o.select_set(True)
    bpy.context.view_layer.objects.active = arm
    destino = f"{RAIZ}/assets/models/criaturas/{nome}/{nome}.glb"
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_force_sampling=True, export_apply=False, export_yup=True,
                              export_image_format="AUTO")
    print("PREPARADO", nome, os.path.getsize(destino), "ações:", sorted(a.name for a in bpy.data.actions), "escala:", round(arm.scale.x, 4))
