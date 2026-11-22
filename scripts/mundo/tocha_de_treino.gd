class_name TochaDeTreino
extends Interagivel
## Tocha do pátio de treino: poste de madeira com uma cesta de ferro. Aperte E para acendê-la (chama pequena e luz).

func _ready() -> void:
	super()
	id = "tocha_treino"
	texto = "Acender tocha"
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.34, 0.22, 0.12)
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.12, 0.12, 0.13)
	ferro.metallic = 0.5
	var poste := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.1
	cil.bottom_radius = 0.13
	cil.height = 1.7
	cil.radial_segments = 6
	cil.material = madeira
	poste.mesh = cil
	poste.position.y = 0.85
	add_child(poste)
	var cesta := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.3
	cone.bottom_radius = 0.14
	cone.height = 0.3
	cone.radial_segments = 6
	cone.material = ferro
	cesta.mesh = cone
	cesta.position.y = 1.8
	add_child(cesta)
	var corpo := StaticBody3D.new()   # o poste bloqueia o jogador
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.12
	forma.height = 1.9
	cs.shape = forma
	cs.position.y = 0.95
	corpo.add_child(cs)
	add_child(corpo)


func _ao_acionar() -> void:
	texto = "Tocha acesa"
	var fogo := Fogo.new()
	fogo.escala = 0.55
	fogo.com_fumaca = false
	fogo.energia_luz = 1.6
	fogo.alcance_luz = 9.0
	fogo.position = Vector3(0.0, 1.9, 0.0)
	add_child(fogo)
