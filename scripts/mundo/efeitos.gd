class_name Efeitos
extends RefCounted
## Efeitos visuais curtos e sem estado.

## Pinta todas as malhas de `raiz` de vermelho por `duracao` segundos (sinal de que levou um golpe).
static func piscar(raiz: Node3D, duracao := 0.18) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.1, 0.1, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var malhas := raiz.find_children("*", "MeshInstance3D", true, false)
	for mi in malhas:
		(mi as MeshInstance3D).material_overlay = mat
	raiz.get_tree().create_timer(duracao).timeout.connect(func() -> void:
		for mi in malhas:
			if is_instance_valid(mi):
				(mi as MeshInstance3D).material_overlay = null)
