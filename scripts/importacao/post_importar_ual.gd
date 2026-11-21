@tool
extends EditorScenePostImport
# Roda quando o Godot importa a Universal Animation Library (CC0, Quaternius).
# Extrai as animações para uma biblioteca reutilizável por qualquer humanoide com o mesmo esqueleto (65 ossos).

const SAIDA := "res://assets/animations/ual/ual1_biblioteca.res"

func _post_import(cena: Node) -> Object:
	var ap: AnimationPlayer = cena.find_child("AnimationPlayer", true, false)
	if ap == null:
		push_error("post_importar_ual: sem AnimationPlayer")
		return cena
	# O Godot já tira o sufixo "_Loop" do nome (Idle_Loop vira Idle) e liga o loop sozinho: não mexer aqui.
	var lib: AnimationLibrary = ap.get_animation_library("")
	var erro := ResourceSaver.save(lib, SAIDA)
	if erro != OK:
		push_error("post_importar_ual: falhou ao salvar a biblioteca (%d)" % erro)
	return cena
