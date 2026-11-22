class_name MacieiraColhivel
extends Interagivel
## Macieira do Pomar Alto: tronco, copa e maçãs visíveis. Cada E colhe uma maçã (vai para o inventário) até acabarem.

static var _m_tronco: StandardMaterial3D
static var _m_copa: StandardMaterial3D
static var _m_fruto: StandardMaterial3D
static var _malha_copa: SphereMesh
static var _malha_fruto: SphereMesh

var macas := 4
var _frutos: Array[MeshInstance3D] = []


func _ready() -> void:
	super()
	id = "macieira"
	texto = "Colher maçã"
	uma_vez = false
	raio = 2.6
	if _m_tronco == null:
		_m_tronco = _material(Color(0.32, 0.21, 0.12))
		_m_copa = _material(Color(0.22, 0.45, 0.16))
		_m_fruto = _material(Color(0.75, 0.08, 0.06))
		_malha_copa = SphereMesh.new()
		_malha_copa.radius = 1.0
		_malha_copa.height = 1.7
		_malha_copa.radial_segments = 8
		_malha_copa.rings = 5
		_malha_copa.material = _m_copa
		_malha_fruto = SphereMesh.new()
		_malha_fruto.radius = 0.11
		_malha_fruto.height = 0.2
		_malha_fruto.radial_segments = 6
		_malha_fruto.rings = 3
		_malha_fruto.material = _m_fruto
	var tronco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.16
	cil.bottom_radius = 0.24
	cil.height = 2.1
	cil.radial_segments = 6
	cil.material = _m_tronco
	tronco.mesh = cil
	tronco.position.y = 1.05
	add_child(tronco)
	for p in [Vector3(0, 2.7, 0), Vector3(0.7, 2.4, 0.3), Vector3(-0.6, 2.5, -0.4)]:
		var copa := MeshInstance3D.new()
		copa.mesh = _malha_copa
		copa.position = p
		copa.scale = Vector3.ONE * randf_range(0.85, 1.1)
		add_child(copa)
	for p in [Vector3(0.9, 2.3, 0.2), Vector3(-0.8, 2.6, 0.5), Vector3(0.2, 2.2, -0.9), Vector3(-0.3, 3.0, 0.8)]:
		var fruto := MeshInstance3D.new()
		fruto.mesh = _malha_fruto
		fruto.position = p
		add_child(fruto)
		_frutos.append(fruto)
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.28
	forma.height = 2.2
	cs.shape = forma
	cs.position.y = 1.1
	corpo.add_child(cs)
	add_child(corpo)


static func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.95
	return m


func disponivel() -> bool:
	return macas > 0


func _ao_acionar() -> void:
	macas -= 1
	_frutos[macas].visible = false
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog:
		jog.coletar("maca", 1)
