@tool
extends EditorScenePostImport
# Roda toda vez que o Godot importa o dragão. Faz de forma explícita o que a importação não fez sozinha:
# 1) liga a cor pintada nos vértices em todos os materiais (no corpo ele não ligou);
# 2) fecha o ciclo das animações cuja última pose difere da primeira (Fly: 88°, Run: 6°),
#    misturando o trecho final de volta para a pose inicial, para o loop não dar pulo.

const JANELA_FRACAO := 0.2   # fração final da animação que é misturada
const LIMITE_GRAUS := 3.0    # só mexe em animação cujo salto de emenda passe disso

# Trechos que repetem de verdade, achados medindo o ângulo entre todos os pares de quadros (24 fps do Blender).
# Fly: o clipe é decolar -> voar -> pousar e termina parado; só os quadros 52 a 112 formam um ciclo de bater de asas
# (emenda de 0,01° em média). Os demais ficam como estão.
const RECORTES := {"Fly": [52.0 / 24.0, 112.0 / 24.0]}

func _post_import(cena: Node) -> Object:
	for mi in cena.find_children("*", "MeshInstance3D", true, true):
		var malha: Mesh = mi.mesh
		for i in malha.get_surface_count():
			var mt: Material = malha.surface_get_material(i)
			if mt is BaseMaterial3D:
				mt.vertex_color_use_as_albedo = true
	var ap: AnimationPlayer = cena.find_child("AnimationPlayer", true, false)
	if ap:
		for nome in ap.get_animation_list():
			for chave in RECORTES:
				if String(nome).begins_with(chave):
					_recortar(ap.get_animation(nome), RECORTES[chave][0], RECORTES[chave][1])
			_fechar_ciclo(ap.get_animation(nome))
	return cena

func _tipo_de_pose(an: Animation, t: int) -> bool:
	var tipo := an.track_get_type(t)
	return tipo == Animation.TYPE_ROTATION_3D or tipo == Animation.TYPE_POSITION_3D or tipo == Animation.TYPE_SCALE_3D

# Fica só com [t0, t1], com chaves exatas nas bordas, e leva o começo para o tempo 0.
func _recortar(an: Animation, t0: float, t1: float) -> void:
	for t in an.get_track_count():
		if not _tipo_de_pose(an, t) or an.track_get_key_count(t) < 2:
			continue
		var tipo := an.track_get_type(t)
		var v0
		var v1
		if tipo == Animation.TYPE_ROTATION_3D:
			v0 = an.rotation_track_interpolate(t, t0)
			v1 = an.rotation_track_interpolate(t, t1)
		elif tipo == Animation.TYPE_POSITION_3D:
			v0 = an.position_track_interpolate(t, t0)
			v1 = an.position_track_interpolate(t, t1)
		else:
			v0 = an.scale_track_interpolate(t, t0)
			v1 = an.scale_track_interpolate(t, t1)
		for k in range(an.track_get_key_count(t) - 1, -1, -1):
			var tempo := an.track_get_key_time(t, k)
			if tempo <= t0 or tempo >= t1:
				an.track_remove_key(t, k)
		if tipo == Animation.TYPE_ROTATION_3D:
			an.rotation_track_insert_key(t, t0, v0)
			an.rotation_track_insert_key(t, t1, v1)
		elif tipo == Animation.TYPE_POSITION_3D:
			an.position_track_insert_key(t, t0, v0)
			an.position_track_insert_key(t, t1, v1)
		else:
			an.scale_track_insert_key(t, t0, v0)
			an.scale_track_insert_key(t, t1, v1)
		for k in an.track_get_key_count(t):
			an.track_set_key_time(t, k, an.track_get_key_time(t, k) - t0)
	an.length = t1 - t0

func _salto_de_rotacao(an: Animation) -> float:
	var maior := 0.0
	for t in an.get_track_count():
		if an.track_get_type(t) == Animation.TYPE_ROTATION_3D and an.track_get_key_count(t) > 1:
			var a: Quaternion = an.track_get_key_value(t, 0)
			var b: Quaternion = an.track_get_key_value(t, an.track_get_key_count(t) - 1)
			maior = max(maior, rad_to_deg(a.angle_to(b)))
	return maior

func _fechar_ciclo(an: Animation) -> void:
	if _salto_de_rotacao(an) <= LIMITE_GRAUS:
		return
	var inicio := an.length * (1.0 - JANELA_FRACAO)
	for t in an.get_track_count():
		var tipo := an.track_get_type(t)
		if tipo != Animation.TYPE_ROTATION_3D and tipo != Animation.TYPE_POSITION_3D and tipo != Animation.TYPE_SCALE_3D:
			continue
		var n := an.track_get_key_count(t)
		if n < 2:
			continue
		var primeiro = an.track_get_key_value(t, 0)
		for k in n:
			var tempo := an.track_get_key_time(t, k)
			if tempo <= inicio:
				continue
			var w := smoothstep(0.0, 1.0, (tempo - inicio) / (an.length - inicio))
			var v = an.track_get_key_value(t, k)
			var novo = v.slerp(primeiro, w) if tipo == Animation.TYPE_ROTATION_3D else v.lerp(primeiro, w)
			an.track_set_key_value(t, k, novo)
