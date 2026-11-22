class_name RaizMedicinal
extends Interagivel
## Raiz medicinal do Riacho da Névoa: ervas verdes sobre um bulbo claro. Aperte E para colher (vai para o inventário).

var _visual: Node3D


func _ready() -> void:
	super()
	id = "raiz"
	texto = "Colher raiz medicinal"
	raio = 2.0
	_visual = Node3D.new()
	add_child(_visual)
	var folha := StandardMaterial3D.new()
	folha.albedo_color = Color(0.2, 0.5, 0.15)
	var bulbo := StandardMaterial3D.new()
	bulbo.albedo_color = Color(0.82, 0.75, 0.55)
	for i in 5:
		var f := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.13
		s.height = 0.5
		s.radial_segments = 5
		s.rings = 3
		s.material = folha
		f.mesh = s
		var a := TAU * i / 5.0
		f.position = Vector3(cos(a) * 0.14, 0.22, sin(a) * 0.14)
		f.rotation = Vector3(sin(a) * 0.5, 0.0, -cos(a) * 0.5)
		_visual.add_child(f)
	var b := MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 0.1
	bs.height = 0.16
	bs.radial_segments = 6
	bs.rings = 3
	bs.material = bulbo
	b.mesh = bs
	b.position.y = 0.04
	_visual.add_child(b)


func _ao_acionar() -> void:
	_visual.visible = false
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog:
		jog.coletar("raiz", 1)
