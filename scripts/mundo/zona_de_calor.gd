class_name ZonaDeCalor
extends Node3D
## Retângulo de lava no chão: desenha a lava e queima o jogador que pisa nela (a cada `intervalo`). Pontes e passarelas
## ficam acima de `altura_max` e são seguras; só quem anda no chão, embaixo, queima.

var tamanho := Vector2(10.0, 10.0)
var dano := 12
var intervalo := 0.8
var altura_max := 0.1   # acima do chão desta zona
var _t := 0.0


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.25, 0.04)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.35, 0.05)
	mat.emission_energy_multiplier = 1.6
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(tamanho.x, 0.1, tamanho.y)
	b.material = mat
	mi.mesh = b
	mi.position.y = 0.0
	add_child(mi)


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog == null or jog.morto:
		return
	var d := jog.global_position - global_position
	if absf(d.x) < tamanho.x / 2.0 and absf(d.z) < tamanho.y / 2.0 and d.y < altura_max:
		jog.receber_dano(dano, self)
		_t = intervalo
