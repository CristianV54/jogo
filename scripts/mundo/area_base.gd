class_name AreaBase
extends Node3D
## Base de toda área do mundo. O jogador, o Fagulha e a câmera NÃO ficam aqui: ficam no jogo, que troca a área.
## Cada área declara seus pontos de entrada (spawns) e emite `pediu_troca` quando o jogador cruza um portal.

signal pediu_troca(destino: String, spawn: String)

var nome_area := ""
var spawns: Dictionary = {}          # nome -> Transform3D
var npcs: Array[Npc] = []


func ponto_de_spawn(nome: String) -> Transform3D:
	return spawns.get(nome, spawns.get("Principal", Transform3D.IDENTITY))


func altura_em(_x: float, _z: float) -> float:
	return 0.0


func _novo_spawn(nome: String, posicao: Vector3, olhando_para: Vector3) -> void:
	var t := Transform3D(Basis.IDENTITY, posicao)
	var d := olhando_para - posicao
	t.basis = Basis(Vector3.UP, atan2(-d.x, -d.z))
	spawns[nome] = t


func _portal(pos: Vector3, destino: String, spawn: String, largura := 8.0) -> Portal:
	var p := Portal.new()
	p.destino = destino
	p.spawn = spawn
	p.tamanho = Vector3(largura, 5.0, 2.0)
	p.position = pos
	add_child(p)
	p.usado.connect(func(d: String, s: String) -> void: pediu_troca.emit(d, s))
	return p


## Céu, névoa e sol do mundo aberto (pinhais e campos).
func _ambiente_padrao() -> void:
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color(0.32, 0.5, 0.78)
	ceu.sky_horizon_color = Color(0.74, 0.8, 0.86)
	ceu.ground_horizon_color = Color(0.62, 0.68, 0.66)
	ceu.ground_bottom_color = Color(0.3, 0.38, 0.32)
	var sky := Sky.new()
	sky.sky_material = ceu
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.fog_enabled = true
	e.fog_light_color = Color(0.72, 0.79, 0.84)
	e.fog_density = 0.0035
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = e
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sol.light_energy = 1.15
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 130.0
	add_child(sol)
