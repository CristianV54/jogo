class_name Criatura
extends Node3D
## Criatura com animações no próprio modelo (dragões e animais). O nó filho "Modelo" é o .glb importado.
## Mesma interface do Humanoide (tocar, tem), para o Inimigo tratar os dois do mesmo jeito.

@export var animacao_inicial := "Idle"
## Animações que repetem sem parar (para modelos cujo arquivo não traz essa marca, como o lobo).
@export var animacoes_em_laco: PackedStringArray = []

@onready var modelo: Node3D = $Modelo
var animacoes: AnimationPlayer


func _ready() -> void:
	_cores_por_vertice()
	animacoes = modelo.find_child("AnimationPlayer", true, false)
	if animacoes:
		for nome in animacoes_em_laco:
			if animacoes.has_animation(nome):
				animacoes.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
		tocar(animacao_inicial)


func tocar(nome: String, mistura := 0.2) -> void:
	if animacoes and animacoes.has_animation(nome) and animacoes.current_animation != nome:
		animacoes.play(nome, mistura)


func tem(nome: String) -> bool:
	return animacoes != null and animacoes.has_animation(nome)


## Modelos com pelagem pintada por vértice (o lobo): o importador não liga a cor do vértice sozinho.
func _cores_por_vertice() -> void:
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			if m3.mesh.surface_get_format(i) & Mesh.ARRAY_FORMAT_COLOR == 0:
				continue
			var mat := m3.get_active_material(i)
			if mat is BaseMaterial3D:
				var d := mat.duplicate() as BaseMaterial3D
				d.vertex_color_use_as_albedo = true
				d.albedo_color = Color.WHITE
				m3.set_surface_override_material(i, d)
