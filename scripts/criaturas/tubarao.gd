class_name Tubarao
extends Node3D
## O mar em volta da ilha tem dono. No raso junto à praia dá para andar; quem passa do raso é avisado e, se insistir mar
## adentro, o tubarão vem e mata. É o limite do mundo (no lugar de uma parede seca na praia).
## O Jogo liga `aviso` ao HUD. O corpo é um PLACEHOLDER visível (falta o modelo do tubarão: ver assets/ASSETS.md).

signal aviso(texto: String)

const AVISA_EM := -Costa.LARGURA_RASO + 4.0   # distância da costa (negativa = mar) em que o aviso aparece
const ATACA_EM := -Costa.LARGURA_RASO - 6.0   # dali para fora o tubarão vem
const VELOCIDADE := 14.0

var _corpo: Node3D
var _avisou := false
var _cacando := false


func _ready() -> void:
	_corpo = Node3D.new()
	_corpo.name = "PLACEHOLDER_Tubarao"
	var barbatana := MeshInstance3D.new()   # só a barbatana fora d'água: stand-in declarado até entrar o modelo de verdade
	var prisma := PrismMesh.new()
	prisma.size = Vector3(1.6, 1.3, 0.12)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 0.28, 0.32)
	prisma.material = m
	barbatana.mesh = prisma
	barbatana.rotation.y = PI / 2.0
	barbatana.position.y = 0.5
	_corpo.add_child(barbatana)
	_corpo.visible = false
	add_child(_corpo)


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
