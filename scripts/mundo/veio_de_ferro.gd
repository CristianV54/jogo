class_name VeioDeFerro
extends Interagivel
## Veio de ferro na rocha: com a PICARETA na bolsa, E tira de 2 a 3 minérios de ferro. Depois de minerado o veio fica
## apagado (pedra menor e escura) e volta em 4 minutos. Sem picareta, o jogo avisa onde conseguir uma.

const MODELO := preload("res://assets/models/itens/minerio_de_ferro/minerio_de_ferro.glb")
const VOLTA_EM := 240.0

var _pedra: Node3D
var _t_volta := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	texto = "Minerar o veio de ferro"
	raio = 3.0
	uma_vez = false
	_rng.seed = hash(global_position)
	_pedra = MODELO.instantiate() as Node3D
	_pedra.scale = Vector3.ONE * _rng.randf_range(6.0, 8.0)
	_pedra.rotation.y = _rng.randf() * TAU
	add_child(_pedra)
	var corpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.9
	forma.shape = esfera
	forma.position.y = 0.5
	corpo.add_child(forma)
	add_child(corpo)
	set_process(false)


func disponivel() -> bool:
	return _t_volta <= 0.0


func _ao_acionar() -> void:
	usado = false
	var jogador := get_tree().get_first_node_in_group("jogador") as Jogador
	var jogo := get_tree().get_first_node_in_group("jogo")
	if jogador == null:
		return
	if int(jogador.inventario.get("picareta", 0)) <= 0:
		if jogo:
			jogo.hud.mensagem("Precisa de uma picareta. Os mercadores de ferragens vendem; um ferreiro faz com 1 lingote e 1 madeira.", 4.0)
		return
	jogador.coletar("minerio_de_ferro", _rng.randi_range(2, 3))
	get_tree().call_group("sons", "tocar", "acerto")
	_t_volta = VOLTA_EM
	_pedra.scale *= 0.55
	set_process(true)


func _process(delta: float) -> void:
	_t_volta -= delta
	if _t_volta <= 0.0:
		_pedra.scale /= 0.55
		set_process(false)
