class_name JaulaDeFilhote
extends Interagivel
## Jaula de ferro com um Filhote de Asa preso. Aperte E com uma chave no inventário para abrir: a porta gira e o filhote
## voa para longe. Sem chave, avisa que está trancada (os guardas da mina carregam as chaves).

var _porta: Node3D
var _filhote: Node3D


func _ready() -> void:
	super()
	id = "jaula"
	texto = "Abrir a jaula (precisa de chave)"
	raio = 3.2
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color(0.1, 0.1, 0.12)
	ferro.metallic = 0.6
	ferro.roughness = 0.45
	for dx in [-1.3, 1.3]:
		for dz in [-1.3, 1.3]:
			_barra(Vector3(dx, 1.2, dz), Vector3(0.14, 2.4, 0.14), ferro, self)
	for y in [0.1, 2.4]:   # molduras de chão e teto
		for lado in [-1.3, 1.3]:
			_barra(Vector3(0.0, y, lado), Vector3(2.7, 0.1, 0.1), ferro, self)
			_barra(Vector3(lado, y, 0.0), Vector3(0.1, 0.1, 2.7), ferro, self)
	for i in 5:   # grades nas três paredes fixas
		var t := -0.9 + i * 0.45
		_barra(Vector3(t, 1.2, -1.3), Vector3(0.06, 2.3, 0.06), ferro, self)
		_barra(Vector3(-1.3, 1.2, t), Vector3(0.06, 2.3, 0.06), ferro, self)
		_barra(Vector3(1.3, 1.2, t), Vector3(0.06, 2.3, 0.06), ferro, self)
	_porta = Node3D.new()   # porta na frente (+Z), com dobradiça no canto esquerdo
	_porta.position = Vector3(-1.3, 0.0, 1.3)
	add_child(_porta)
	for i in 5:
		_barra(Vector3(0.1 + i * 0.5, 1.2, 0.0), Vector3(0.06, 2.3, 0.06), ferro, _porta)
	_barra(Vector3(1.3, 0.15, 0.0), Vector3(2.6, 0.08, 0.08), ferro, _porta)
	_barra(Vector3(1.3, 2.35, 0.0), Vector3(2.6, 0.08, 0.08), ferro, _porta)
	_filhote = (load("res://scenes/criaturas/filhote_de_asa_visual.tscn") as PackedScene).instantiate()
	_filhote.scale = Vector3.ONE * 0.6
	_filhote.position.y = 0.05
	add_child(_filhote)
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.7, 2.4, 2.7)
	cs.shape = forma
	cs.position.y = 1.2
	corpo.add_child(cs)
	add_child(corpo)


func _barra(pos: Vector3, tam: Vector3, mat: Material, pai: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	b.material = mat
	mi.mesh = b
	mi.position = pos
	pai.add_child(mi)


func acionar() -> void:
	if not disponivel():
		return
	var jog := get_tree().get_first_node_in_group("jogador") as Jogador
	if jog == null or not jog.gastar_item("chave", 1):
		GerenciadorMissoes.instancia.aviso.emit("Trancada. Falta uma chave: os guardas da mina carregam as chaves.", 3.0)
		return
	super()


func _ao_acionar() -> void:
	texto = "Jaula aberta"
	abrir()


## Abre a porta e solta o filhote, que voa para longe. Também é chamado sem chave quando o obelisco cai.
func abrir() -> void:
	usado = true
	create_tween().tween_property(_porta, "rotation_degrees:y", -100.0, 0.5)
	await get_tree().create_timer(0.4).timeout
	if _filhote.has_method("tocar"):
		_filhote.tocar("Fly", 0.1)
	var rumo := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
	var tw := create_tween()
	tw.tween_property(_filhote, "global_position", _filhote.global_position + rumo * 50.0 + Vector3(0.0, 30.0, 0.0), 5.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(_filhote.queue_free)
