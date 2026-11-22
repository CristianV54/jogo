class_name CestoVirado
extends Interagivel
## Cesto de colheita tombado pelo vento, com maçãs espalhadas. Aperte E para endireitá-lo.

var _cesto: Node3D


func _ready() -> void:
	super()
	id = "cesto_virado"
	texto = "Endireitar o cesto"
	var palha := StandardMaterial3D.new()
	palha.albedo_color = Color(0.62, 0.45, 0.22)
	var fruto := StandardMaterial3D.new()
	fruto.albedo_color = Color(0.75, 0.08, 0.06)
	_cesto = Node3D.new()
	add_child(_cesto)
	var corpo := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.42
	cil.bottom_radius = 0.3
	cil.height = 0.55
	cil.radial_segments = 8
	cil.material = palha
	corpo.mesh = cil
	corpo.position.y = 0.28
	_cesto.add_child(corpo)
	_cesto.rotation_degrees.z = 80.0   # tombado de lado
	_cesto.position.y = 0.3
	for p in [Vector3(0.7, 0.1, 0.2), Vector3(0.95, 0.1, -0.15), Vector3(0.55, 0.1, -0.35)]:
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.1
		s.height = 0.2
		s.radial_segments = 6
		s.rings = 3
		s.material = fruto
		m.mesh = s
		m.position = p
		add_child(m)


func _ao_acionar() -> void:
	texto = "Cesto de pé"
	var tw := create_tween()
	tw.tween_property(_cesto, "rotation_degrees:z", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_cesto, "position:y", 0.0, 0.5)
