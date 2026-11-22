class_name Obelisco
extends Node3D
## O primeiro obelisco de Ferro Negro: base circular com runas brilhantes, corpo vertical rachado com veios luminosos e
## três âncoras menores ligadas por correntes. Destruir é em etapas: quebrar as 3 âncoras faz o corpo desabar e soltar
## Ferro Negro bruto. Não se mata o corpo a golpes.

signal caiu

const RAIO_ANCORAS := 14.0

var ancoras: Array[AncoraDeObelisco] = []
var restantes := 3
var _corpo: Node3D
var _luz: OmniLight3D
var _runas: StandardMaterial3D
var _terreno_y: Callable


func montar(altura_em: Callable) -> void:
	_terreno_y = altura_em
	var pedra := StandardMaterial3D.new()
	pedra.albedo_color = Color(0.13, 0.13, 0.16)
	pedra.roughness = 0.85
	var veio := StandardMaterial3D.new()
	veio.albedo_color = Color(0.1, 0.18, 0.5)
	veio.emission_enabled = true
	veio.emission = Color(0.3, 0.5, 1.0)
	veio.emission_energy_multiplier = 3.0
	_runas = veio
	# base circular com runas
	var base := MeshInstance3D.new()
	var cb := CylinderMesh.new()
	cb.top_radius = 6.0
	cb.bottom_radius = 6.4
	cb.height = 0.5
	cb.radial_segments = 20
	cb.material = pedra
	base.mesh = cb
	base.position.y = 0.25
	add_child(base)
	var anel := MeshInstance3D.new()
	var ca := CylinderMesh.new()
	ca.top_radius = 5.2
	ca.bottom_radius = 5.2
	ca.height = 0.05
	ca.radial_segments = 20
	ca.material = veio
	anel.mesh = ca
	anel.position.y = 0.52
	add_child(anel)
	for i in 12:   # runas em volta
		var a := TAU * i / 12.0
		var runa := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.18, 0.06, 0.7)
		b.material = veio
		runa.mesh = b
		runa.position = Vector3(cos(a) * 4.4, 0.54, sin(a) * 4.4)
		runa.rotation.y = -a
		add_child(runa)
	# corpo
	_corpo = Node3D.new()
	add_child(_corpo)
	var cc := CylinderMesh.new()
	cc.top_radius = 0.5
	cc.bottom_radius = 1.9
	cc.height = 15.0
	cc.radial_segments = 4
	cc.material = pedra
	var tronco := MeshInstance3D.new()
	tronco.mesh = cc
	tronco.position.y = 8.0
	tronco.rotation.y = PI / 4.0
	_corpo.add_child(tronco)
	for i in 6:   # veios luminosos e rachaduras
		var f := MeshInstance3D.new()
		var vb := BoxMesh.new()
		vb.size = Vector3(0.07, 3.0 + i * 0.6, 0.05)
		vb.material = veio
		f.mesh = vb
		var ang := i * PI / 2.0 + 0.4
		var raio_f := 1.7 - i * 0.18
		f.position = Vector3(cos(ang) * raio_f, 3.0 + i * 1.6, sin(ang) * raio_f)
		f.rotation = Vector3(0.0, -ang, 0.1 * i)
		_corpo.add_child(f)
	_luz = OmniLight3D.new()
	_luz.light_color = Color(0.3, 0.5, 1.0)
	_luz.light_energy = 3.0
	_luz.omni_range = 26.0
	_luz.position.y = 6.0
	add_child(_luz)
	var corpo_solido := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 1.8
	forma.height = 15.0
	cs.shape = forma
	cs.position.y = 7.5
	corpo_solido.add_child(cs)
	add_child(corpo_solido)
	# âncoras e correntes
	for k in 3:
		var a := PI / 2.0 + TAU * k / 3.0
		var pos := Vector3(cos(a) * RAIO_ANCORAS, 0.0, sin(a) * RAIO_ANCORAS)
		var an := AncoraDeObelisco.new()
		an.position = Vector3(pos.x, _terreno_y.call(global_position.x + pos.x, global_position.z + pos.z) - global_position.y, pos.z)
		add_child(an)
		var corrente := MeshInstance3D.new()   # da gema da âncora até o corpo do obelisco
		var de := an.position + Vector3(0.0, 4.4, 0.0)
		var para := Vector3(0.0, 8.0, 0.0)
		var cc2 := CylinderMesh.new()
		cc2.top_radius = 0.07
		cc2.bottom_radius = 0.07
		cc2.height = de.distance_to(para)
		cc2.radial_segments = 4
		cc2.material = veio
		corrente.mesh = cc2
		corrente.position = (de + para) / 2.0
		corrente.basis = Basis(Quaternion(Vector3.UP, (para - de).normalized()))
		add_child(corrente)
		an.corrente = corrente
		an.destruida.connect(_ao_ancora_destruida)
		ancoras.append(an)


func _ao_ancora_destruida() -> void:
	restantes -= 1
	_luz.light_energy = 3.0 * restantes / 3.0 + 0.3
	_runas.emission_energy_multiplier = 3.0 * restantes / 3.0 + 0.5
	if restantes > 0:
		GerenciadorMissoes.instancia.aviso.emit("Âncora quebrada. Faltam %d." % restantes, 2.5)
		return
	_desabar()


func _desabar() -> void:
	GerenciadorMissoes.instancia.aviso.emit("O obelisco treme e desaba!", 4.0)
	var tw := create_tween()
	tw.tween_property(_corpo, "rotation:z", 0.35, 1.2)
	tw.parallel().tween_property(_corpo, "position:y", -4.0, 2.2).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_luz, "light_energy", 0.0, 1.8)
	_runas.emission_energy_multiplier = 0.2
	var poeira := CPUParticles3D.new()
	poeira.one_shot = true
	poeira.explosiveness = 0.8
	poeira.amount = 80
	poeira.lifetime = 2.5
	poeira.direction = Vector3.UP
	poeira.spread = 80.0
	poeira.initial_velocity_min = 3.0
	poeira.initial_velocity_max = 9.0
	poeira.gravity = Vector3(0.0, -2.0, 0.0)
	var bola := SphereMesh.new()
	bola.radius = 0.4
	bola.height = 0.8
	bola.radial_segments = 6
	bola.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.4, 0.38, 0.36, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bola.material = m
	poeira.mesh = bola
	poeira.position.y = 1.0
	add_child(poeira)
	poeira.emitting = true
	var tabela := {"minerio_bruto": [3, 3]}
	Pickup.largar(get_parent(), global_position + Vector3(0.0, 0.5, 3.5), tabela)
	GerenciadorMissoes.evento("destruir", "obelisco")
	caiu.emit()
