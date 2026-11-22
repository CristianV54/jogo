class_name Humanoide
extends Node3D
## Qualquer personagem humano montado com o esqueleto de 65 ossos (Universal Base Characters + trajes).
## Liga o modelo à biblioteca de animações compartilhada (Universal Animation Library, CC0).
## O nó filho "Modelo" é o .glb; as animações têm o caminho "Armature/Skeleton3D:osso", relativo à raiz do modelo.

const BIBLIOTECA: AnimationLibrary = preload("res://assets/animations/ual/ual1_biblioteca.res")

## Cor que multiplica a textura de cabelo e sobrancelha (a textura do pacote é cinza-clara).
@export var cor_cabelo := Color(1, 1, 1)
## Escala do corpo todo (1,0 = 1,82 m, a altura da base). Usada para diferenciar personagens.
@export var escala_corpo := 1.0
## Animação em loop que toca ao entrar na cena.
@export var animacao_inicial := "Idle"

@onready var modelo: Node3D = $Modelo
var animacoes: AnimationPlayer


func _ready() -> void:
	modelo.scale = Vector3.ONE * escala_corpo
	_tingir_cabelo()
	animacoes = AnimationPlayer.new()
	animacoes.name = "Animacoes"
	add_child(animacoes)
	animacoes.root_node = animacoes.get_path_to(modelo)
	animacoes.add_animation_library("", BIBLIOTECA)
	tocar(animacao_inicial)


func tocar(nome: String, mistura := 0.2) -> void:
	if not animacoes.has_animation(nome):
		push_warning("Humanoide: animação inexistente: " + nome)
		return
	if animacoes.current_animation != nome:
		animacoes.play(nome, mistura)


func tem(nome: String) -> bool:
	return animacoes.has_animation(nome)


func _tingir_cabelo() -> void:
	if cor_cabelo == Color(1, 1, 1):
		return
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("Hair") or String(mi.name).begins_with("Eyebrows"):
			for i in mi.mesh.get_surface_count():
				var mat: Material = mi.get_active_material(i)
				if mat is BaseMaterial3D:
					var copia: BaseMaterial3D = mat.duplicate()
					copia.albedo_color = cor_cabelo
					mi.set_surface_override_material(i, copia)
