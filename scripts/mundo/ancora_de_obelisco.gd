class_name AncoraDeObelisco
extends StaticBody3D
## Âncora do obelisco: pilar de pedra com um cristal azul, ligada ao corpo do obelisco por uma corrente. Leva golpes
## (grupo "atingiveis") e, ao zerar a vida, desmorona e avisa as missões ("destruir", "ancora").

signal destruida

var morto := false
var raio_colisao := 1.2
var vida := 66
var corrente: Node3D        # a corrente até o obelisco, escondida quando a âncora cai
var _visual: Node3D
var _luz: OmniLight3D


func _ready() -> void:
	add_to_group("atingiveis")
	collision_layer = 1
	_visual = Node3D.new()
	add_child(_visual)
	var pedra := StandardMaterial3D.new()
	pedra.albedo_color = Color(0.2, 0.2, 0.23)
	pedra.roughness = 0.9
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.15, 0.25, 0.7)
	cristal.emission_enabled = true
	cristal.emission = Color(0.25, 0.45, 1.0)
	cristal.emission_energy_multiplier = 2.5
	var base := MeshInstance3D.new()
	var cb := CylinderMesh.new()
	cb.top_radius = 1.0
	cb.bottom_radius = 1.3
	cb.height = 0.7
	cb.radial_segments = 6
	cb.material = pedra
	base.mesh = cb
	base.position.y = 0.35
	_visual.add_child(base)
	var pilar := MeshInstance3D.new()
	var cp := CylinderMesh.new()
	cp.top_radius = 0.45
	cp.bottom_radius = 0.7
	cp.height = 3.2
	cp.radial_segments = 6
	cp.material = pedra
	pilar.mesh = cp
	pilar.position.y = 2.3
	_visual.add_child(pilar)
	var gema := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.1
	s.radial_segments = 6
	s.rings = 3
	s.material = cristal
	gema.mesh = s
	gema.position.y = 4.4
	_visual.add_child(gema)
	_luz = OmniLight3D.new()
	_luz.light_color = Color(0.3, 0.5, 1.0)
	_luz.light_energy = 1.5
	_luz.omni_range = 8.0
	_luz.position.y = 4.4
	add_child(_luz)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.9
	forma.height = 4.6
	cs.shape = forma
	cs.position.y = 2.3
	add_child(cs)


func receber_dano(quantidade: int, _de: Node3D = null) -> void:
	if morto:
		return
	vida -= quantidade
	Efeitos.piscar(_visual, 0.12)
	var tw := create_tween()
	tw.tween_property(_visual, "position:x", 0.12, 0.05)
	tw.tween_property(_visual, "position:x", 0.0, 0.1)
	if vida > 0:
		return
	morto = true
	collision_layer = 0
	if corrente:
		corrente.visible = false
	_luz.visible = false
	var queda := create_tween()
	queda.tween_property(_visual, "scale", Vector3(1.0, 0.05, 1.0), 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	GerenciadorMissoes.evento("destruir", "ancora")
	destruida.emit()
