class_name Fogo
extends Node3D
## Fogo de verdade: labareda em camadas (miolo claro e chama laranja que escurece), fumaça, fagulhas e uma luz que tremula.
## Se `dano` > 0, queima o jogador que ficar dentro do raio (um golpe de dano a cada `intervalo_dano` segundos).

@export var escala := 1.0
@export var dano := 0
@export var raio_dano := 0.9           # em metros, já na escala final
@export var intervalo_dano := 0.7
@export var energia_luz := 2.4
@export var alcance_luz := 16.0
@export var com_fumaca := true

var _luz: OmniLight3D
var _t := randf() * 10.0
var _t_dano := 0.0
static var _bola: GradientTexture2D


func _ready() -> void:
	_chama(0.34, 0.42, 1.4, 0.8, Color(1.0, 0.45, 0.08, 0.9), 34)   # labareda
	_chama(0.18, 0.28, 1.0, 0.55, Color(1.0, 0.95, 0.65, 0.95), 22)  # miolo quente
	if com_fumaca:
		_fumaca()
	_fagulhas()
	_luz = OmniLight3D.new()
	_luz.light_color = Color(1.0, 0.6, 0.28)
	_luz.light_energy = energia_luz
	_luz.omni_range = alcance_luz
	_luz.position = Vector3(0.0, 0.9 * escala, 0.0)
	add_child(_luz)


func _process(delta: float) -> void:
	_t += delta
	_luz.light_energy = energia_luz * (0.82 + 0.18 * sin(_t * 9.0) + 0.12 * sin(_t * 23.0 + 1.3))


func _physics_process(delta: float) -> void:
	if dano <= 0:
		return
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog == null or jog.morto:
		_t_dano = 0.0
		return
	var d := jog.global_position - global_position
	var dentro := Vector2(d.x, d.z).length() < raio_dano and d.y > -0.5 and d.y < 1.8
	if not dentro:
		_t_dano = 0.0
		return
	_t_dano -= delta
	if _t_dano <= 0.0:
		_t_dano = intervalo_dano
		jog.receber_dano(dano, self)


static func _textura_bola() -> GradientTexture2D:
	if _bola == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.45, Color(1, 1, 1, 0.55))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_bola = GradientTexture2D.new()
		_bola.gradient = g
		_bola.fill = GradientTexture2D.FILL_RADIAL
		_bola.fill_from = Vector2(0.5, 0.5)
		_bola.fill_to = Vector2(1.0, 0.5)
		_bola.width = 64
		_bola.height = 64
	return _bola


func _material(aditivo: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if aditivo else BaseMaterial3D.BLEND_MODE_MIX
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _textura_bola()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.particles_anim_h_frames = 1
	m.particles_anim_v_frames = 1
	m.particles_anim_loop = false
	return m


func _particulas(quantidade: int, vida: float, tamanho: float, aditivo: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = quantidade
	p.lifetime = vida
	p.local_coords = true
	var q := QuadMesh.new()
	q.size = Vector2(tamanho, tamanho) * escala
	q.material = _material(aditivo)
	p.mesh = q
	add_child(p)
	return p


func _chama(raio: float, tamanho: float, vel: float, vida: float, cor: Color, quantidade: int) -> void:
	var p := _particulas(quantidade, vida, tamanho * 2.2, true)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = raio * escala
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0.0, 0.4, 0.0)
	p.initial_velocity_min = vel * 0.6 * escala
	p.initial_velocity_max = vel * escala
	p.position = Vector3(0.0, 0.18 * escala, 0.0)
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.55))
	curva.add_point(Vector2(0.3, 1.0))
	curva.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curva
	var rampa := Gradient.new()
	rampa.set_color(0, Color(cor.r, cor.g, cor.b, 0.0))
	rampa.add_point(0.12, cor)
	rampa.add_point(0.55, Color(cor.r, cor.g * 0.55, cor.b * 0.3, cor.a * 0.7))
	rampa.set_color(rampa.get_point_count() - 1, Color(0.35, 0.06, 0.02, 0.0))
	p.color_ramp = rampa


func _fumaca() -> void:
	var p := _particulas(14, 2.8, 1.1, false)
	var mf := (p.mesh as QuadMesh).material as StandardMaterial3D
	mf.vertex_color_use_as_albedo = false
	mf.albedo_color = Color(0.45, 0.43, 0.42, 0.22)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2 * escala
	p.direction = Vector3.UP
	p.spread = 16.0
	p.gravity = Vector3(0.0, 0.25, 0.0)
	p.initial_velocity_min = 0.5 * escala
	p.initial_velocity_max = 0.9 * escala
	p.position = Vector3(0.0, 0.9 * escala, 0.0)
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.4))
	curva.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = curva


func _fagulhas() -> void:
	var p := _particulas(12, 1.7, 0.07, true)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.25 * escala
	p.direction = Vector3.UP
	p.spread = 30.0
	p.gravity = Vector3(0.0, 0.3, 0.0)
	p.initial_velocity_min = 1.2 * escala
	p.initial_velocity_max = 2.6 * escala
	p.position = Vector3(0.0, 0.4 * escala, 0.0)
	var rampa := Gradient.new()
	rampa.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
	rampa.set_color(rampa.get_point_count() - 1, Color(1.0, 0.3, 0.05, 0.0))
	p.color_ramp = rampa
