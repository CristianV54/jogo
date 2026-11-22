# Abre o .blend (só leitura), reduz a escala do esqueleto e exporta .glb com TODAS as ações.
import bpy, sys, os
src, dst = sys.argv[sys.argv.index('--')+1:][:2]
bpy.ops.wm.open_mainfile(filepath=src)
arm = bpy.data.objects['Armature']; mesh = bpy.data.objects['Dragon_Mesh']
# escala NÃO é aplicada aqui (causava escala dupla no Godot): a raiz é escalada na cena do Godot
print("ACOES_NO_ARQUIVO", [a.name for a in bpy.data.actions])
# garante que cada ação esteja ligada ao esqueleto (o exportador só leva as que estão ligadas)
bpy.context.view_layer.objects.active = arm
for a in bpy.data.objects: a.select_set(a in (arm, mesh))
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', use_selection=True,
    export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
    export_apply=False, export_yup=True)
print("EXPORTADO", dst, os.path.getsize(dst))
