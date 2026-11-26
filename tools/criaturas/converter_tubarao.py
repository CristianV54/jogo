# Converte o tubarão-martelo CC0 (Phelippeau Rudy, OpenGameArt "Shark - low poly") para .glb com uma animação "Swim"
# em laço (a cauda e o corpo ondulam de lado). Uso: python3 -I converter.py entrada.blend saida.glb
import bpy, sys, math
from mathutils import Vector, Quaternion
entrada, saida = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=entrada)
for o in list(bpy.data.objects):
    if o.type in ('CAMERA', 'LIGHT'):
        bpy.data.objects.remove(o)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
malha = next(o for o in bpy.data.objects if o.type == 'MESH')
print('ossos:', [(b.name, b.parent.name if b.parent else None, tuple(round(v, 2) for v in (arm.matrix_world @ b.head_local)), tuple(round(v, 2) for v in (arm.matrix_world @ b.tail_local))) for b in arm.data.bones])
print('malha: min', tuple(round(min((malha.matrix_world @ v.co)[i] for v in malha.data.vertices), 2) for i in range(3)), 'max', tuple(round(max((malha.matrix_world @ v.co)[i] for v in malha.data.vertices), 2) for i in range(3)))
# o material do arquivo é do Blender antigo (sem nós): refaz com a pintura original ligada na cor, e sombreado suave
img = next(i for i in bpy.data.images if i.packed_file is not None)
mat = bpy.data.materials.new('Tubarao')
mat.use_nodes = True
bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
tex.image = img
mat.node_tree.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
bsdf.inputs['Roughness'].default_value = 0.6
malha.data.materials.clear()
malha.data.materials.append(mat)
for poligono in malha.data.polygons:
    poligono.use_smooth = True
bpy.context.view_layer.objects.active = arm
arm.animation_data_create()
acao = bpy.data.actions.new('Swim')
arm.animation_data.action = acao
bpy.context.scene.frame_start = 0
bpy.context.scene.frame_end = 40
# cada osso gira em torno do eixo vertical do mundo; quanto mais fundo na cadeia (mais perto da cauda), mais gira e mais atrasado
def profundidade(b):
    n = 0
    while b.parent:
        n += 1
        b = b.parent
    return n
for pb in arm.pose.bones:
    pb.rotation_mode = 'QUATERNION'
    eixo = ((arm.matrix_world.to_3x3() @ pb.bone.matrix_local.to_3x3()).inverted() @ Vector((0, 0, 1))).normalized()
    p = profundidade(pb.bone)
    amplitude = math.radians(3 if pb.name.startswith('Aileron') else 4 + 7 * p)   # as barbatanas do peito quase não mexem
    for quadro in range(0, 41, 5):
        ang = amplitude * math.sin(2 * math.pi * quadro / 40.0 - 0.8 * p)
        pb.rotation_quaternion = Quaternion(eixo, ang)
        pb.keyframe_insert('rotation_quaternion', frame=quadro)
bpy.ops.export_scene.gltf(filepath=saida, export_format='GLB', export_animations=True, export_yup=True, export_apply=False)
print('exportado', saida)
