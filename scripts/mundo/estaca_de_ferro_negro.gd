class_name EstacaDeFerroNegro
extends Interagivel
## Estaca de Ferro Negro cravada no pinhal, prendendo o dragão por correntes. Precisa de 3 puxadas (E, E, E) para sair;
## a cada puxada afunda e o brilho azul enfraquece. Conta para a missão a cada puxada.

const PUXADAS := 3

var puxadas := 0
var _visual: Node3D
var _luz: OmniLight3D
var _brilho: StandardMaterial3D


func _ready() -> void:
	super()
	id = "estaca_ferro"
	texto = "Arrancar a estaca de Ferro Negro (0/3)"
	uma_vez = false
	raio = 3.0
	_visual = Node3D.new()
	add_child(_visual)
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.07, 0.07, 0.09)
	ferro.metallic = 0.6
	ferro.roughness = 0.4
	_brilho = StandardMaterial3D.new()
	_brilho.albedo_color = Color(0.1, 0.12, 0.2)
	_brilho.emission_enabled = true
	_brilho.emission = Color(0.2, 0.4, 1.0)
	_brilho.emission_energy_multiplier = 2.5
	var espeto := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 0.28
	cone.height = 2.6
	cone.radial_segments = 6
	cone.material = ferro
	espeto.mesh = cone
	espeto.position.y = 1.3
	_visual.add_child(espeto)
	for y in [0.7, 1.3, 1.9]:   # veios azuis
		var veio := MeshInstance3D.new()
		var anel := CylinderMesh.new()
		anel.top_radius = 0.27 - y * 0.1
		anel.bottom_radius = 0.28 - y * 0.1
		anel.height = 0.07
		anel.radial_segments = 6
		anel.material = _brilho
		veio.mesh = anel
		veio.position.y = y
		_visual.add_child(veio)
	_luz = OmniLight3D.new()
	_luz.light_color = Color(0.3, 0.5, 1.0)
	_luz.light_energy = 1.8
	_luz.omni_range = 7.0
	_luz.position.y = 1.5
	add_child(_luz)
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.3
	forma.height = 2.4
	cs.shape = forma
	cs.position.y = 1.2
	corpo.add_child(cs)
	_visual.add_child(corpo)


func disponivel() -> bool:
	return puxadas < PUXADAS


func _ao_acionar() -> void:
	puxadas += 1
	texto = "Arrancar a estaca de Ferro Negro (%d/%d)" % [puxadas, PUXADAS]
	var tw := create_tween()
	tw.tween_property(_visual, "position:y", -0.9 * puxadas, 0.4)
	tw.parallel().tween_property(_luz, "light_energy", 1.8 * float(PUXADAS - puxadas) / PUXADAS, 0.4)
	_brilho.emission_energy_multiplier = 2.5 * float(PUXADAS - puxadas) / PUXADAS
	if puxadas >= PUXADAS:
		tw.tween_callback(func() -> void: _visual.visible = false)
