class_name CarrinhoDeMinerio
extends Interagivel
## Carrinho de minério sobre trilhos. Aperte E perto dele para empurrá-lo ao longo do trilho, para longe de você:
## ele rola 12 m e atropela os inimigos no caminho (90 de dano). Usado como arma na arena do Gorath.

@export var eixo := Vector3(1, 0, 0)   # direção do trilho
const DISTANCIA := 12.0
const DANO := 90

var rolando := false
var _espera := 0.0
var _atingidos: Array = []
var _corpo: AnimatableBody3D


func _ready() -> void:
	super()
	id = "carrinho"
	texto = "Empurrar o carrinho"
	uma_vez = false
	raio = 2.8
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.3, 0.2, 0.11)
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.12, 0.12, 0.14)
	ferro.metallic = 0.5
	var minerio := StandardMaterial3D.new()
	minerio.albedo_color = Color(0.05, 0.05, 0.07)
	_corpo = AnimatableBody3D.new()
	_corpo.sync_to_physics = false
	_corpo.collision_layer = 1 | Solidos.CAMADA_SERES
	add_child(_corpo)
	var visual := Node3D.new()
	visual.rotation.y = atan2(eixo.x, eixo.z)   # o comprimento do carrinho segue o trilho
	_corpo.add_child(visual)
	_caixa(visual, Vector3(0.0, 0.8, 0.0), Vector3(1.5, 0.8, 2.2), madeira)
	_caixa(visual, Vector3(0.0, 1.22, 0.0), Vector3(1.3, 0.1, 2.0), minerio)
	for dx in [-0.78, 0.78]:
		for dz in [-0.8, 0.8]:
			var roda := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.28
			c.bottom_radius = 0.28
			c.height = 0.1
			c.radial_segments = 8
			c.material = ferro
			roda.mesh = c
			roda.rotation.z = PI / 2.0
			roda.position = Vector3(dx, 0.3, dz)
			visual.add_child(roda)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.5, 1.0, 2.2)
	cs.shape = forma
	cs.position.y = 0.7
	cs.rotation.y = atan2(eixo.x, eixo.z)
	_corpo.add_child(cs)


func _caixa(pai: Node3D, pos: Vector3, tam: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	b.material = mat
	mi.mesh = b
	mi.position = pos
	pai.add_child(mi)


func disponivel() -> bool:
	return not rolando and _espera <= 0.0


func _physics_process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	if not rolando:
		return
	for no in get_tree().get_nodes_in_group("inimigos"):
		var ini := no as Inimigo
		if ini == null or ini.estado == Inimigo.Estado.MORTO or _atingidos.has(ini):
			continue
		var d := ini.global_position - _corpo.global_position
		d.y = 0.0
		if d.length() < 2.2 + ini.raio_colisao:
			_atingidos.append(ini)
			ini.receber_dano(DANO, self)


func _ao_acionar() -> void:
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	var sentido := 1.0
	if jog:
		sentido = signf((global_position - jog.global_position).dot(eixo))
		if sentido == 0.0:
			sentido = 1.0
	rolando = true
	_atingidos.clear()
	var tw := create_tween()
	tw.tween_property(self, "position", position + eixo * sentido * DISTANCIA, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		rolando = false
		_espera = 3.0
		usado = false)
