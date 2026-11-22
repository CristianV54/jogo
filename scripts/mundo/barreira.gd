class_name Barreira
extends Node3D
## Barreira de história no corredor entre duas regiões: fecha a passagem (colisão) até a condição ser cumprida; então abre
## (portão que desliza, entulho que desaba, carroças que saem do caminho). Quem chega perto lê por que está fechada.
##   tipo: "portao" (grade de ferro), "entulho" (pedras e troncos) ou "carroca" (carroças viradas)

var tipo := "portao"
var largura := 14.0
var texto := ""
var condicao: Callable
var aberta := false
var _corpos: Array[StaticBody3D] = []
var _visual: Node3D
var _t := 0.0
var _t_aviso := 0.0


func _ready() -> void:
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(largura, 6.0, 1.4)
	cs.shape = forma
	cs.position.y = 3.0
	corpo.add_child(cs)
	add_child(corpo)
	_corpos.append(corpo)
	_visual = Node3D.new()
	add_child(_visual)
	match tipo:
		"portao":
			_montar_portao()
		"entulho":
			_montar_entulho()
		_:
			_montar_carrocas()


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 1.0
	return m


func _caixa(pai: Node3D, pos: Vector3, tam: Vector3, cor: Color, giro := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	b.material = _mat(cor)
	mi.mesh = b
	mi.position = pos
	mi.rotation.y = giro
	pai.add_child(mi)
	return mi


func _montar_portao() -> void:
	for lado in [-1.0, 1.0]:
		_caixa(self, Vector3(lado * (largura / 2.0 + 0.6), 3.5, 0.0), Vector3(1.4, 7.0, 1.6), Color(0.35, 0.33, 0.35))
		_caixa(self, Vector3(lado * (largura / 2.0 + 0.6), 7.4, 0.0), Vector3(1.8, 0.8, 2.0), Color(0.3, 0.28, 0.3))
	_caixa(self, Vector3(0.0, 7.2, 0.0), Vector3(largura + 2.4, 0.6, 1.0), Color(0.28, 0.2, 0.12))
	var n := int(largura / 0.8)
	for i in n:
		_caixa(_visual, Vector3(-largura / 2.0 + 0.4 + i * (largura / n), 3.0, 0.0), Vector3(0.18, 6.0, 0.18), Color(0.1, 0.1, 0.12))
	_caixa(_visual, Vector3(0.0, 4.6, 0.0), Vector3(largura, 0.2, 0.2), Color(0.1, 0.1, 0.12))
	_caixa(_visual, Vector3(0.0, 1.2, 0.0), Vector3(largura, 0.2, 0.2), Color(0.1, 0.1, 0.12))


func _montar_entulho() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 14:
		var pedra := MeshInstance3D.new()
		pedra.mesh = FabricaNatureza.pedra(float(k))
		pedra.material_override = FabricaNatureza.material()
		pedra.position = Vector3(rng.randf_range(-largura / 2.0, largura / 2.0), 0.0, rng.randf_range(-0.8, 0.8))
		var e := rng.randf_range(1.6, 3.2)
		pedra.scale = Vector3(e, e * 1.3, e)
		_visual.add_child(pedra)
	for k in 6:
		_caixa(_visual, Vector3(-largura / 2.0 + 1.5 + k * 2.2, 1.6 + (k % 2) * 0.8, 0.0), Vector3(0.7, 0.7, 3.4), Color(0.3, 0.2, 0.11), rng.randf_range(-0.4, 0.4))


func _montar_carrocas() -> void:
	var n := int(largura / 4.0)
	for k in n:
		var x := -largura / 2.0 + 2.0 + k * 4.0
		_caixa(_visual, Vector3(x, 1.0, 0.0), Vector3(3.4, 1.6, 2.2), Color(0.12, 0.09, 0.09), 0.1 * (k % 3 - 1))
		_caixa(_visual, Vector3(x, 2.2, 0.2), Vector3(2.6, 0.8, 1.6), Color(0.45, 0.1, 0.08), 0.0)
		for lado in [-1.0, 1.0]:
			var roda := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.7
			c.bottom_radius = 0.7
			c.height = 0.2
			c.material = _mat(Color(0.25, 0.17, 0.1))
			roda.mesh = c
			roda.position = Vector3(x + lado * 1.4, 0.7, 1.0)
			roda.rotation.z = PI / 2.0
			_visual.add_child(roda)
	for k in 3:   # bandeira negra do Império
		_caixa(self, Vector3(-largura / 2.0 + 3.0 + k * (largura / 3.0), 4.0, 0.0), Vector3(0.15, 8.0, 0.15), Color(0.2, 0.15, 0.1))
		_caixa(self, Vector3(-largura / 2.0 + 3.6 + k * (largura / 3.0), 6.4, 0.0), Vector3(1.0, 1.4, 0.05), Color(0.08, 0.07, 0.09))


func _process(delta: float) -> void:
	if aberta:
		return
	_t -= delta
	_t_aviso -= delta
	if _t <= 0.0:
		_t = 0.4
		if condicao.is_valid() and condicao.call():
			_abrir()
			return
	if _t_aviso <= 0.0:
		var jog := get_tree().get_first_node_in_group("jogador") as Node3D
		if jog and jog.global_position.distance_to(global_position) < 14.0 and GerenciadorMissoes.instancia:
			_t_aviso = 8.0
			GerenciadorMissoes.instancia.aviso.emit(texto, 4.5)


func _abrir() -> void:
	aberta = true
	for c in _corpos:
		c.collision_layer = 0
	var tw := create_tween()
	match tipo:
		"portao":
			tw.tween_property(_visual, "position:y", 6.5, 1.8)
		"entulho":
			tw.tween_property(_visual, "position:y", -4.0, 2.5)
		_:
			tw.tween_property(_visual, "position:x", largura, 3.0)
	if GerenciadorMissoes.instancia:
		GerenciadorMissoes.instancia.aviso.emit("O caminho está livre.", 3.0)
