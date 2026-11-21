extends SceneTree
# Mede para onde a cabeça do Fagulha aponta (cabeça menos pélvis, em metros, no espaço do modelo).

func _init() -> void:
	var raiz: Node3D = load("res://assets/models/criaturas/fagulha/fagulha.glb").instantiate()
	root.add_child(raiz)
	var ap: AnimationPlayer = raiz.find_child("AnimationPlayer", true, false)
	var sk: Skeleton3D = raiz.find_child("Skeleton3D", true, false)
	for anim in ["Idle", "Walk"]:
		ap.play(anim)
		ap.seek(0.0, true)
		var cabeca := sk.get_bone_global_pose(sk.find_bone("head")).origin
		var pelvis := sk.get_bone_global_pose(sk.find_bone("pelvic_2")).origin
		var v := sk.global_transform * (cabeca - pelvis)
		print("FRENTE ", anim, " cabeca-pelvis (m) = ", v, " | angulo no plano XZ (graus, 0 = aponta para +Z) = ",
			snapped(rad_to_deg(atan2(v.x, v.z)), 0.1))
	quit(0)
