# Converte para .glb: animais do pacote Farm Animals (Quaternius) e armas do MedievalPack (Quaternius), só leitura.
# Cores ajustadas por material. As animações perdem o prefixo "Armature|Armature|".
# Rodar:  Blender -b -P converter_animais_e_armas.py -- RAIZ_DO_PROJETO
import bpy, sys, os
RAIZ = sys.argv[sys.argv.index("--") + 1]
ANIMAIS = "/Volumes/Extreme SSD/JOGO/modelos-3d/pacotes_livres/animais/Farmx20Animalsx20byx20x40Quaternius/Farm Animals by @Quaternius/FBX/"
ARMAS = "/Volumes/Extreme SSD/JOGO/modelos-3d/pacotes_livres/armas_ferramentas_3d/quaternius_MedievalPack/MedievalPack/OBJ/"


def cor_material(nome_mat, cor):
    m = bpy.data.materials.get(nome_mat)
    if m is None:
        return
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    if b:
        b.inputs["Base Color"].default_value = (*cor, 1)


def exportar(destino, com_animacao):
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    for a in bpy.data.actions:
        a.name = a.name.split("|")[-1]
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=destino, export_format="GLB", use_selection=True, export_animations=com_animacao,
                              export_animation_mode="ACTIONS", export_apply=False, export_yup=True, export_image_format="AUTO")
    print("EXPORTADO", destino, os.path.getsize(destino))


# animais: (arquivo, saida, {material: cor})  -- PLACEHOLDER_: não têm andar nem correr, só Idle e Jump
for arq, saida, cores in (
    ("Pig", "criaturas/javali/javali.glb", {"Material": (0.16, 0.11, 0.09), "Material.003": (0.3, 0.22, 0.17)}),
    ("Pug", "criaturas/lobo/lobo.glb", {"Beige": (0.55, 0.55, 0.57), "Brown": (0.22, 0.22, 0.25)}),
):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=ANIMAIS + arq + ".fbx")
    for n, c in cores.items():
        cor_material(n, c)
    exportar(f"{RAIZ}/assets/models/{saida}", True)

# armas (o .obj perde a referência da textura: religa a imagem do pacote ao material)
TEXTURAS = "/Volumes/Extreme SSD/JOGO/modelos-3d/pacotes_livres/armas_ferramentas_3d/quaternius_MedievalPack/MedievalPack/Blends/Textures/"
TEX_DA_ARMA = {"ShortSword": "SwordTexture.png", "LongSword": "SwordTexture.png", "Club": "ClubTexture.png",
               "Katana": "KatanaTexture.png", "SimpleAxe": "SimpleAxeTexture.png"}
for arq in ("ShortSword", "LongSword", "Club", "Katana", "SimpleAxe"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=ARMAS + arq + ".obj")
    img = bpy.data.images.load(TEXTURAS + TEX_DA_ARMA[arq])
    for m in bpy.data.materials:
        m.use_nodes = True
        nt = m.node_tree
        b = nt.nodes.get("Principled BSDF")
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    dims = [tuple(round(x, 2) for x in o.dimensions) for o in bpy.data.objects if o.type == "MESH"]
    print("ARMA", arq, dims)
    exportar(f"{RAIZ}/assets/models/armas/{arq.lower()}.glb", False)
