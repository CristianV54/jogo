class_name Solidos
extends RefCounted
## Ajudantes para dar corpo sólido às coisas. Camadas de colisão: 1 = mundo (paredes, cercas, troncos, inimigos),
## 4 = móveis das casas, 8 = seres vivos e peças do cenário que o jogador não atravessa (animais, NPCs, Fagulha).
## A câmera só enxerga as camadas 1 e 2; por isso não tropeça nos animais nem nos móveis.

const CAMADA_SERES := 8


## Caminho livre para quem anda sem física (animais, gente): arrasta uma esfera do tamanho do corpo por `distancia` metros
## na direção `dir`, na altura do peito, contra o mundo (camada 1) e os outros seres (camada 8). Uma esfera pega a quina de
## um tronco ou de uma pedra, o que 3 raios finos deixavam passar (o bicho acabava dentro da árvore).
static func caminho_livre(espaco_de: Node3D, de: Vector3, dir: Vector3, distancia: float, raio: float, excluir: Array = []) -> bool:
	var esfera := SphereShape3D.new()
	esfera.radius = raio
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = esfera
	q.transform = Transform3D(Basis.IDENTITY, de)
	q.motion = dir.normalized() * distancia
	q.collision_mask = 1 | CAMADA_SERES
	q.exclude = excluir
	var r := espaco_de.get_world_3d().direct_space_state.cast_motion(q)
	return r.size() < 2 or r[0] >= 0.999


## Caixa que envolve todas as malhas de `no`, em coordenadas do próprio `no`. `encolher` < 1 afina a caixa
## (a malha de animais inclui rabo e orelhas que não precisam bloquear).
static func caixa_de(no: Node3D, encolher := 1.0) -> AABB:
	var uniao := AABB()
	var primeiro := true
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D.IDENTITY
		var p: Node = mi
		while p != no:
			t = (p as Node3D).transform * t
			p = p.get_parent()
		var a: AABB = t * (mi as MeshInstance3D).get_aabb()
		uniao = a if primeiro else uniao.merge(a)
		primeiro = false
	var c := uniao.get_center()
	var tam := uniao.size * encolher
	return AABB(c - tam / 2.0, tam)


## Adiciona a `corpo` uma caixa de colisão do tamanho de `no`, já na posição e giro de `no` (que deve ser filho do
## mesmo pai de `corpo`, com `corpo` na origem).
static func colidir_com(no: Node3D, corpo: CollisionObject3D, encolher := 1.0) -> void:
	var caixa := caixa_de(no, encolher)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = caixa.size
	cs.shape = bx
	cs.transform = no.transform * Transform3D(Basis(), caixa.get_center())
	corpo.add_child(cs)


## Corpo que se move junto com o nó pai (animais, Fagulha): AnimatableBody3D, que empurra e bloqueia o jogador direito.
static func corpo_movel(pai: Node3D, caixa: AABB) -> AnimatableBody3D:
	var corpo := AnimatableBody3D.new()
	corpo.name = "CorpoSolido"
	corpo.collision_layer = CAMADA_SERES
	corpo.collision_mask = 0
	corpo.sync_to_physics = false   # o pai se move por código: a posição do corpo acompanha na hora (com true ela ficava atrasada)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = caixa.size
	cs.shape = bx
	cs.position = caixa.get_center()
	corpo.add_child(cs)
	pai.add_child(corpo)
	return corpo
