class_name Npc
extends Node3D
## Personagem não jogável: um humanoide parado numa animação, que pode olhar para um ponto e tem falas.
## Como no jogador, o modelo olha para +Z; por isso o visual fica girado 180° e o nó olha para -Z.

@export var nome := ""
@export var papel := ""
@export var falas: PackedStringArray = []
@export var animacao := "Idle"
@export var cena: PackedScene

const PROTESTOS := ["Ei! Calma!", "Está louco?! Guarde essa espada!", "Pare com isso, Torin!", "Isso dói!", "Eu sou do seu bando!"]

var visual: Humanoide
var raio_colisao := 0.5
var morto := false   # os NPCs da história nunca morrem; só reagem
var _protesto: Label3D


func _ready() -> void:
	visual = cena.instantiate()
	visual.animacao_inicial = animacao
	visual.rotation_degrees.y = 180.0
	add_child(visual)
	name = nome if nome != "" else name
	add_to_group("atingiveis")


func olhar_para(alvo: Vector3) -> void:
	var d := alvo - global_position
	rotation.y = atan2(-d.x, -d.z)


## Leva um golpe: pisca em vermelho, se encolhe e reclama. Não perde vida nem morre.
func receber_dano(_quantidade: int, _de: Node3D = null) -> void:
	Efeitos.piscar(visual)
	visual.tocar("Hit_Chest", 0.05)
	if _protesto == null:
		_protesto = Label3D.new()
		_protesto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_protesto.position = Vector3(0.0, 2.3, 0.0)
		_protesto.font_size = 48
		_protesto.pixel_size = 0.006
		_protesto.outline_size = 12
		_protesto.no_depth_test = true
		add_child(_protesto)
	_protesto.text = PROTESTOS[randi() % PROTESTOS.size()]
	_protesto.visible = true
	await get_tree().create_timer(0.6).timeout
	visual.tocar(animacao, 0.2)
	await get_tree().create_timer(1.6).timeout
	_protesto.visible = false
