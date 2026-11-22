class_name BonecoDeTreino
extends StaticBody3D
## Boneco de treino: poste com travessa de braços e uma cabeça de palha. Balança e pisca quando levado um golpe, e cada
## golpe conta para a missão ("golpear" / "boneco_treino"). Não tem vida: dá para bater para sempre.

var morto := false          # grupo "atingiveis": o golpe do jogador procura por isto e por `raio_colisao`
var raio_colisao := 0.6
var _visual: Node3D


func _ready() -> void:
	add_to_group("atingiveis")
	collision_layer = 1
	_visual = Node3D.new()
	add_child(_visual)
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.4, 0.27, 0.15)
	var palha := StandardMaterial3D.new()
	palha.albedo_color = Color(0.78, 0.66, 0.38)
	var pano := StandardMaterial3D.new()
	pano.albedo_color = Color(0.55, 0.2, 0.15)
	_peca(CylinderMesh.new(), madeira, Vector3(0.0, 0.9, 0.0), Vector3(0.16, 1.8, 0.16))
	_peca(BoxMesh.new(), madeira, Vector3(0.0, 1.4, 0.0), Vector3(1.0, 0.12, 0.12))
	_peca(SphereMesh.new(), palha, Vector3(0.0, 1.75, 0.0), Vector3(0.32, 0.32, 0.32))
	_peca(BoxMesh.new(), pano, Vector3(0.0, 1.05, 0.0), Vector3(0.5, 0.6, 0.3))
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.3
	forma.height = 1.8
	cs.shape = forma
	cs.position.y = 0.9
	add_child(cs)


func _peca(malha: PrimitiveMesh, mat: Material, pos: Vector3, tam: Vector3) -> void:
	var mi := MeshInstance3D.new()
	if malha is CylinderMesh:
		(malha as CylinderMesh).top_radius = tam.x / 2.0
		(malha as CylinderMesh).bottom_radius = tam.x / 2.0
		(malha as CylinderMesh).height = tam.y
		(malha as CylinderMesh).radial_segments = 8
	elif malha is BoxMesh:
		(malha as BoxMesh).size = tam
	elif malha is SphereMesh:
		(malha as SphereMesh).radius = tam.x / 2.0
		(malha as SphereMesh).height = tam.x
		(malha as SphereMesh).radial_segments = 8
		(malha as SphereMesh).rings = 4
	malha.material = mat
	mi.mesh = malha
	mi.position = pos
	_visual.add_child(mi)


func receber_dano(_quantidade: int, de: Node3D = null) -> void:
	Efeitos.piscar(_visual, 0.12)
	var empurrao := Vector3.ZERO
	if de:
		empurrao = (global_position - de.global_position).normalized()
	var tw := create_tween()
	tw.tween_property(_visual, "rotation", Vector3(empurrao.z * 0.35, 0.0, -empurrao.x * 0.35), 0.08)
	tw.tween_property(_visual, "rotation", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	GerenciadorMissoes.evento("golpear", "boneco_treino")
