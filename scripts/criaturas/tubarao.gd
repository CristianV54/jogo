class_name Tubarao
extends Node3D
## O mar em volta da ilha tem dono. No raso junto à praia dá para andar; quem passa do raso é avisado e, se insistir mar
## adentro, o tubarão vem e mata. É o limite do mundo (no lugar de uma parede seca na praia).
## O Jogo liga `aviso` ao HUD. O corpo é um tubarão-martelo rigado, com a animação Swim (ver assets/ASSETS.md).

signal aviso(texto: String)

const AVISA_EM := -Costa.LARGURA_RASO + 4.0   # distância da costa (negativa = mar) em que o aviso aparece
const ATACA_EM := -Costa.LARGURA_RASO - 6.0   # dali para fora o tubarão vem
const VELOCIDADE := 14.0
const MODELO := preload("res://assets/models/criaturas/tubarao/tubarao.glb")
const ESCALA := 0.75   # 5,7 m de comprimento

var _corpo: Node3D
var _avisou := false
var _cacando := false


func _ready() -> void:
	_corpo = Node3D.new()
	_corpo.name = "Tubarao"
	var modelo := criar_modelo()
	modelo.rotation.y = PI            # look_at aponta o -Z do corpo para o alvo: o modelo vira para lá
	modelo.position.y = -0.55         # o corpo vai debaixo d'água; só a barbatana das costas corta a superfície
	_corpo.add_child(modelo)
	_corpo.visible = false
	add_child(_corpo)


## O tubarão-martelo CC0 (ver assets/ASSETS.md) no tamanho do jogo, cinza-azulado e já nadando. A frente do modelo é +Z.
static func criar_modelo() -> Node3D:
	var modelo := MODELO.instantiate() as Node3D
	modelo.name = "Modelo"
	modelo.scale = Vector3.ONE * ESCALA
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha := mi as MeshInstance3D
		for i in malha.mesh.get_surface_count():
			var mat := malha.get_active_material(i)
			if mat is StandardMaterial3D:
				var d := mat.duplicate() as StandardMaterial3D
				d.albedo_color = Color(0.3, 0.35, 0.43)   # a pintura original é quase branca: escurece para cinza de tubarão (no mar, com 0,5 ainda saía claro demais)
				malha.set_surface_override_material(i, d)
	var anim := modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim and anim.has_animation("Swim"):
		anim.get_animation("Swim").loop_mode = Animation.LOOP_LINEAR
		anim.play("Swim")
		anim.speed_scale = 1.6
	return modelo


func _physics_process(delta: float) -> void:
	var jogador := get_tree().get_first_node_in_group("jogador") as Node3D
	if jogador == null:
		return
	var p := jogador.global_position
	var d := Costa.distancia(p.x, p.z)
	var na_agua := p.y < Costa.NIVEL_MAR + 2.5   # voando no Fagulha por cima do mar, o tubarão não alcança
	if d > AVISA_EM or not na_agua:
		_avisou = false
		if d > 0.0 or not na_agua:
			_cacando = false
			_corpo.visible = false
		return
	if not _avisou:
		_avisou = true
		aviso.emit("Há uma barbatana na água. Volte para a praia!")
	if d < ATACA_EM and not _cacando:
		_cacando = true
		_corpo.visible = true
		var fora := Vector2(p.x, p.z).normalized()   # nasce mar adentro, à frente do Torin
		_corpo.global_position = Vector3(p.x + fora.x * 35.0, Costa.NIVEL_MAR, p.z + fora.y * 35.0)
	if _cacando:
		var alvo := Vector3(p.x, Costa.NIVEL_MAR, p.z)
		var vai := alvo - _corpo.global_position
		if vai.length() < 1.5:
			_cacando = false
			aviso.emit("O tubarão pegou você.")
			jogador.call("receber_dano", 9999, self)
		else:
			_corpo.global_position += vai.normalized() * VELOCIDADE * delta
			_corpo.look_at(alvo, Vector3.UP)
