class_name Clima
extends Node
## Ciclo de dia e noite, céu, sol, lua, nuvens, chuva e tempestade. É dono do ambiente do jogo: as áreas só dizem como é
## o ar da região (`estilo`: cor da névoa, densidade, cor do sol), e o clima mistura isso com a hora e o tempo.
##   - 1 dia = SEGUNDOS_POR_DIA segundos reais; sol e lua cruzam o céu, com disco, estrelas e nuvens no céu (shader);
##   - tempo: limpo, nublado, chuva, tempestade (com relâmpagos e trovão); chuva cai em volta da câmera;
##   - sons gerados por código (chuva e trovão), sem arquivos de áudio.

enum Tempo { LIMPO, NUBLADO, CHUVA, TEMPESTADE }
const NOMES := ["Céu limpo", "Nublado", "Chuva", "Tempestade"]
const SEGUNDOS_POR_DIA := 720.0   # 12 minutos reais por dia

var hora := 9.0
var tempo := Tempo.LIMPO
var chuva := 0.0          # 0 a 1, suavizado
var cobertura := 0.15     # nuvens, 0 a 1
var escuro := 0.0         # céu carregado (chuva e tempestade)
var relampago := 0.0
var congelado := false    # testes: a hora não anda
var tempo_automatico := true
var camera: Node3D
var estilo := {"neblina": Color(0.72, 0.79, 0.84), "densidade": 0.0035, "sol": Color(1.0, 0.96, 0.88), "energia": 1.15, "ambiente": 0.9, "topo": Color(0.32, 0.5, 0.78), "horizonte": Color(0.74, 0.8, 0.86)}

var _estilo_atual := {}
var _env: Environment
var _sol: DirectionalLight3D
var _lua: DirectionalLight3D
var _ceu: ShaderMaterial
var _gotas: CPUParticles3D
var _t_tempo := 150.0
var _t_raio := 8.0
var _trovoes: Array[float] = []
var _chuva_som: AudioStreamPlayer
var _trovao_som: AudioStreamPlayer
var _chuva_fase := 0.0
var _trovao_amp := 0.0
var _rng := RandomNumberGenerator.new()

const SHADER_CEU := """shader_type sky;
uniform vec3 sol_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 lua_dir = vec3(0.0, -1.0, 0.0);
uniform float dia = 1.0;
uniform float cobertura = 0.2;
uniform float escuro = 0.0;
uniform float relampago = 0.0;
uniform vec3 topo_dia = vec3(0.32, 0.5, 0.78);
uniform vec3 horizonte_dia = vec3(0.74, 0.8, 0.86);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * ruido(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}
void sky() {
	vec3 d = EYEDIR;
	float horizonte = pow(1.0 - clamp(d.y, 0.0, 1.0), 3.0);
	vec3 c_dia = mix(topo_dia, horizonte_dia, horizonte);
	vec3 c_noite = mix(vec3(0.015, 0.025, 0.07), vec3(0.05, 0.07, 0.14), horizonte);
	vec3 c = mix(c_noite, c_dia, dia);
	float baixo = clamp(1.0 - abs(sol_dir.y) * 2.5, 0.0, 1.0);
	float perto = pow(max(dot(d, sol_dir), 0.0), 6.0);
	c += vec3(1.0, 0.45, 0.15) * perto * baixo * (0.4 + horizonte) * 0.9;   // nascer e pôr do sol
	float disco = smoothstep(0.99925, 0.9995, dot(d, sol_dir));
	c += vec3(1.0, 0.95, 0.8) * disco * 3.0 * (1.0 - escuro * 0.9);
	float lua = smoothstep(0.9988, 0.9993, dot(d, lua_dir));
	c += vec3(0.85, 0.9, 1.0) * lua * 1.8 * (1.0 - dia) * (1.0 - escuro);
	if (d.y > 0.0) {
		vec2 e = d.xz / (d.y + 0.25) * 55.0;
		float s = step(0.9972, hash(floor(e)));
		c += vec3(s) * (1.0 - dia) * (1.0 - cobertura) * (1.0 - escuro);
		vec2 uv = d.xz / (d.y + 0.15) * 1.5 + vec2(TIME * 0.012, 0.0);
		float n = fbm(uv);
		float limite = 1.02 - cobertura * 0.75;
		float nuvem = smoothstep(limite, limite + 0.2, n);
		vec3 cn = mix(vec3(1.0), vec3(0.3, 0.32, 0.37), escuro) * mix(vec3(0.12, 0.14, 0.22), vec3(1.0), dia);
		cn += vec3(0.7, 0.75, 1.0) * relampago * nuvem;
		c = mix(c, cn, nuvem * clamp(d.y * 3.5, 0.0, 1.0));
	}
	c += vec3(0.8, 0.85, 1.0) * relampago * 0.5;
	COLOR = c;
}
"""


## Registra o vento como variável global dos shaders (as plantas balançam mais na tempestade). Chamar antes de criar áreas.
static var _globais_ok := false


static func registrar_globais() -> void:
	if not _globais_ok:
		_globais_ok = true
		RenderingServer.global_shader_parameter_add("vento_forca", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0)


func _ready() -> void:
	registrar_globais()
	_rng.randomize()
	_estilo_atual = estilo.duplicate()
	var sh := Shader.new()
	sh.code = SHADER_CEU
	_ceu = ShaderMaterial.new()
	_ceu.shader = sh
	var sky := Sky.new()
	sky.sky_material = _ceu
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.fog_enabled = true
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.name = "AmbienteDoMundo"
	we.environment = _env
	add_child(we)
	_sol = DirectionalLight3D.new()
	_sol.name = "Sol"
	_sol.shadow_enabled = true
	_sol.directional_shadow_max_distance = 130.0
	add_child(_sol)
	_lua = DirectionalLight3D.new()
	_lua.name = "Lua"
	_lua.light_color = Color(0.55, 0.65, 1.0)
	add_child(_lua)
	_gotas = _criar_chuva()
	add_child(_gotas)
	_chuva_som = _criar_som()
	_trovao_som = _criar_som()
	_aplicar()


func _criar_som() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var g := AudioStreamGenerator.new()
	g.mix_rate = 22050.0
	g.buffer_length = 0.25
	p.stream = g
	add_child(p)
	p.play()
	return p


func _criar_chuva() -> CPUParticles3D:
	var c := CPUParticles3D.new()
	c.name = "Chuva"
	c.amount = 2200
	c.lifetime = 1.0
	c.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	c.emission_box_extents = Vector3(24.0, 0.5, 24.0)
	c.direction = Vector3(0.18, -1.0, 0.05)
	c.spread = 3.0
	c.gravity = Vector3(0.0, -10.0, 0.0)
	c.initial_velocity_min = 22.0
	c.initial_velocity_max = 28.0
	var malha := BoxMesh.new()
	malha.size = Vector3(0.015, 0.7, 0.015)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.85, 1.0, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	malha.material = m
	c.mesh = malha
	c.local_coords = false
	c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.emitting = false
	return c


## Define como é o ar da região (neblina, densidade, sol). Vem do ambiente de cada área.
func definir_estilo(novo: Dictionary) -> void:
	for k in novo:
		estilo[k] = novo[k]


func definir_hora(h: float) -> void:
	hora = fposmod(h, 24.0)
	_aplicar()


func forcar_tempo(t: Tempo) -> void:
	tempo = t
	tempo_automatico = false
	_t_tempo = 1e9
	var a := _alvo(t)
	cobertura = a[0]
	chuva = a[1]
	escuro = a[2]
	_aplicar()


func _alvo(t: Tempo) -> Array:   # [cobertura, chuva, escuro]
	match t:
		Tempo.LIMPO:
			return [0.15, 0.0, 0.0]
		Tempo.NUBLADO:
			return [0.65, 0.0, 0.35]
		Tempo.CHUVA:
			return [0.85, 0.65, 0.6]
		_:
			return [1.0, 1.0, 0.95]


func hora_texto() -> String:
	return "%02d:%02d" % [int(hora), int((hora - int(hora)) * 60.0)]


func eh_noite() -> bool:
	return sol_dir().y < 0.0


## Hora de recolher: das 19h30 às 5h30 (e quando chove forte) o povo vai para casa.
func hora_de_dormir() -> bool:
	return hora >= 19.5 or hora < 5.5


func sol_dir() -> Vector3:
	var a := (hora - 6.0) / 24.0 * TAU
	return Vector3(cos(a), sin(a), 0.3).normalized()


func _process(delta: float) -> void:
	if not congelado:
		hora = fposmod(hora + delta * 24.0 / SEGUNDOS_POR_DIA, 24.0)
	if tempo_automatico:
		_t_tempo -= delta
		if _t_tempo <= 0.0:
			_sortear_tempo()
		var a := _alvo(tempo)
		cobertura = move_toward(cobertura, a[0], delta * 0.04)
		chuva = move_toward(chuva, a[1], delta * 0.08)
		escuro = move_toward(escuro, a[2], delta * 0.06)
	for k in estilo:   # a névoa e o sol da região mudam devagar quando se anda de uma para outra
		if estilo[k] is Color:
			_estilo_atual[k] = (_estilo_atual.get(k, estilo[k]) as Color).lerp(estilo[k], clampf(delta * 1.2, 0.0, 1.0))
		else:
			_estilo_atual[k] = lerpf(_estilo_atual.get(k, estilo[k]), estilo[k], clampf(delta * 1.2, 0.0, 1.0))
	_relampagos(delta)
	_aplicar()
	_sons()


func _sortear_tempo() -> void:
	var sorteio := _rng.randf()
	match tempo:
		Tempo.LIMPO:
			tempo = Tempo.NUBLADO if sorteio < 0.6 else Tempo.LIMPO
		Tempo.NUBLADO:
			tempo = Tempo.LIMPO if sorteio < 0.4 else (Tempo.CHUVA if sorteio < 0.85 else Tempo.TEMPESTADE)
		Tempo.CHUVA:
			tempo = Tempo.NUBLADO if sorteio < 0.5 else (Tempo.TEMPESTADE if sorteio < 0.75 else Tempo.CHUVA)
		_:
			tempo = Tempo.CHUVA if sorteio < 0.7 else Tempo.NUBLADO
	_t_tempo = _rng.randf_range(120.0, 300.0)


func _relampagos(delta: float) -> void:
	relampago = maxf(0.0, relampago - delta * 4.0)
	for i in range(_trovoes.size() - 1, -1, -1):
		_trovoes[i] -= delta
		if _trovoes[i] <= 0.0:
			_trovoes.remove_at(i)
			_trovao_amp = 0.9
	if escuro > 0.8 and chuva > 0.7:
		_t_raio -= delta
		if _t_raio <= 0.0:
			_t_raio = _rng.randf_range(5.0, 18.0)
			relampago = 1.0
			_trovoes.append(_rng.randf_range(0.4, 3.0))


func _aplicar() -> void:
	if _env == null:
		return
	var s := sol_dir()
	var dia := smoothstep(-0.1, 0.2, s.y)
	var lua_d := -s + Vector3(0.0, 0.0, 0.2)
	var nublado := 1.0 - escuro * 0.55
	_sol.visible = s.y > -0.05
	_sol.look_at_from_position(Vector3.ZERO, -s, Vector3.UP if absf(s.y) < 0.99 else Vector3.RIGHT)
	var calor := smoothstep(0.0, 0.5, s.y)   # perto do horizonte a luz fica laranja
	var cor_sol: Color = Color(1.0, 0.55, 0.25).lerp(_estilo_atual["sol"], calor)
	_sol.light_color = cor_sol
	_sol.light_energy = float(_estilo_atual["energia"]) * dia * nublado * (1.0 + relampago * 2.0)
	_lua.visible = lua_d.y > 0.0
	_lua.look_at_from_position(Vector3.ZERO, -lua_d, Vector3.UP)
	_lua.light_energy = 0.6 * (1.0 - dia) * (1.0 - escuro * 0.6)
	var topo: Color = _estilo_atual["topo"]
	var horizonte: Color = _estilo_atual["horizonte"]
	_ceu.set_shader_parameter("sol_dir", s)
	_ceu.set_shader_parameter("lua_dir", lua_d.normalized())
	_ceu.set_shader_parameter("dia", dia)
	_ceu.set_shader_parameter("cobertura", cobertura)
	_ceu.set_shader_parameter("escuro", escuro)
	_ceu.set_shader_parameter("relampago", relampago)
	_ceu.set_shader_parameter("topo_dia", Vector3(topo.r, topo.g, topo.b))
	_ceu.set_shader_parameter("horizonte_dia", Vector3(horizonte.r, horizonte.g, horizonte.b))
	var noite_cor := Color(0.11, 0.14, 0.26)
	var ar := noite_cor.lerp(Color(0.6, 0.65, 0.75) * float(_estilo_atual["ambiente"]) / 0.9, dia)
	_env.ambient_light_color = ar.lerp(Color(0.45, 0.48, 0.55), escuro * 0.4 * dia) + Color(0.5, 0.55, 0.7) * relampago * 0.4
	_env.ambient_light_energy = lerpf(0.75, 0.9, dia) * (1.0 - escuro * 0.25)
	var neblina: Color = _estilo_atual["neblina"]
	var fn := Color(0.04, 0.06, 0.1).lerp(neblina, dia).lerp(Color(0.38, 0.4, 0.45) * lerpf(0.35, 1.0, dia), escuro * 0.7)
	_env.fog_light_color = fn
	_env.fog_density = float(_estilo_atual["densidade"]) * (1.0 + chuva * 2.0 + escuro) * lerpf(1.3, 1.0, dia)
	_gotas.emitting = chuva > 0.03
	var quantidade := 2400 if chuva > 0.66 else (1300 if chuva > 0.3 else 600)   # trocar a quantidade reinicia as gotas: só em degraus
	if quantidade != _gotas.amount:
		_gotas.amount = quantidade
	if camera:
		_gotas.global_position = camera.global_position + Vector3(0.0, 14.0, 0.0)
	RenderingServer.global_shader_parameter_set("vento_forca", 1.0 + escuro * 3.0 + chuva * 1.5)


## Chuva (ruído suave) e trovão (estrondo grave que decai), gerados direto no buffer de áudio. Só gera quando há o que tocar
## e no máximo 800 amostras por quadro (encher o buffer inteiro com uma função por amostra travava o jogo).
func _sons() -> void:
	if chuva > 0.03:
		var pb := _chuva_som.get_stream_playback() as AudioStreamGeneratorPlayback
		if pb:
			var n := mini(pb.get_frames_available(), 800)
			if n > 0:
				var buf := PackedVector2Array()
				buf.resize(n)
				var amp := 0.22 * chuva
				for i in n:
					_chuva_fase = lerpf(_chuva_fase, _rng.randf() * 2.0 - 1.0, 0.35)
					buf[i] = Vector2(_chuva_fase * amp, _chuva_fase * amp)
				pb.push_buffer(buf)
	if _trovao_amp > 0.001:
		var pt := _trovao_som.get_stream_playback() as AudioStreamGeneratorPlayback
		if pt:
			var n := mini(pt.get_frames_available(), 800)
			if n > 0:
				var buf := PackedVector2Array()
				buf.resize(n)
				var anterior := 0.0
				for i in n:
					_trovao_amp = maxf(0.0, _trovao_amp - 0.00004)
					anterior = lerpf(anterior, (_rng.randf() * 2.0 - 1.0) * _trovao_amp * _trovao_amp * 0.5, 0.5)
					buf[i] = Vector2(anterior, anterior)
				pt.push_buffer(buf)
