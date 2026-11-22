class_name ColisoresDeArvores
extends StaticBody3D
## Troncos sólidos sob demanda. As florestas do mundo aberto têm dezenas de milhares de árvores; dar uma colisão a cada uma
## travaria a física. Aqui as árvores ficam numa grade de células e só as que estão perto do jogador ganham um tronco
## sólido, reaproveitando um punhado de colisores (o "pool"), que se movem junto com o jogador.

const CELULA := 32.0
const RAIO_ATIVO := 38.0

var _celulas: Dictionary = {}   # Vector2i -> Array[Vector3] (x, z, raio)
var _pool: Array[CollisionShape3D] = []
var _formas: Array[CylinderShape3D] = []
var _ultimo := Vector2(1e9, 1e9)
var _t := 0.0
var altura_em: Callable


func iniciar(tamanho_pool := 200) -> void:
	name = "TroncosSobDemanda"
	for i in tamanho_pool:
		var cs := CollisionShape3D.new()
		var f := CylinderShape3D.new()
		f.height = 4.0
		f.radius = 0.5
		cs.shape = f
		cs.disabled = true
		add_child(cs)
		_pool.append(cs)
		_formas.append(f)


func adicionar(x: float, z: float, raio: float) -> void:
	var k := Vector2i(int(floor(x / CELULA)), int(floor(z / CELULA)))
	if not _celulas.has(k):
		_celulas[k] = []
	(_celulas[k] as Array).append(Vector3(x, z, raio))


func total() -> int:
	var n := 0
	for k in _celulas:
		n += (_celulas[k] as Array).size()
	return n


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.2
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog == null:
		return
	var p := Vector2(jog.global_position.x, jog.global_position.z)
	if p.distance_to(_ultimo) < 3.0:
		return
	atualizar(p)


## Põe os troncos mais perto de `p` nos colisores do pool (e desliga os que sobrarem).
func atualizar(p: Vector2) -> void:
	_ultimo = p
	var c0 := Vector2i(int(floor(p.x / CELULA)), int(floor(p.y / CELULA)))
	var perto: Array = []
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var k := Vector2i(c0.x + dx, c0.y + dz)
			if not _celulas.has(k):
				continue
			for a: Vector3 in _celulas[k]:
				var d2 := (a.x - p.x) * (a.x - p.x) + (a.y - p.y) * (a.y - p.y)
				if d2 < RAIO_ATIVO * RAIO_ATIVO:
					perto.append([d2, a])
	perto.sort_custom(func(m: Array, n: Array) -> bool: return m[0] < n[0])
	for i in _pool.size():
		if i < perto.size():
			var a: Vector3 = perto[i][1]
			_formas[i].radius = a.z
			var y: float = altura_em.call(a.x, a.y) if altura_em.is_valid() else 0.0
			_pool[i].position = Vector3(a.x, y + 2.0, a.y)
			_pool[i].disabled = false
		else:
			_pool[i].disabled = true
