class_name RodaDagua
extends Node3D
## Roda d'água do moinho: aro de madeira com pás, gira devagar em torno do eixo X local.

@export var velocidade := 0.7
@export var raio := 1.6


func _ready() -> void:
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.32, 0.21, 0.12)
	var eixo := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.12
	cil.bottom_radius = 0.12
	cil.height = 0.9
	cil.radial_segments = 6
	cil.material = madeira
	eixo.mesh = cil
	eixo.rotation_degrees.z = 90.0
	add_child(eixo)
	for i in 8:
		var a := TAU * i / 8.0
		var raio_caixa := MeshInstance3D.new()   # raio da roda
		var b := BoxMesh.new()
		b.size = Vector3(0.1, raio * 2.0, 0.12)
		b.material = madeira
		raio_caixa.mesh = b
		raio_caixa.rotation.x = a
		add_child(raio_caixa)
		var pa := MeshInstance3D.new()   # pá na ponta
		var bp := BoxMesh.new()
		bp.size = Vector3(0.6, 0.12, 0.45)
		bp.material = madeira
		pa.mesh = bp
		pa.position = Vector3(0.0, cos(a) * raio, sin(a) * raio)
		pa.rotation.x = a
		add_child(pa)


func _process(delta: float) -> void:
	rotation.x += velocidade * delta
