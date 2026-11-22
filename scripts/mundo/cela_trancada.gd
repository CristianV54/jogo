class_name CelaTrancada
extends Interagivel
## Cela de ferro de Ferrogris com cativos dentro (civis, soldados ou um dragão jovem). E com uma chave no inventário
## abre a porta: os cativos saem e fogem para o portão. Conta como um "setor_prisao" para a missão C3-M3.

var tipo := "civis"   # "civis", "soldados" ou "dragao"
var ocupantes: Array[Node3D] = []
var _porta: Node3D
var _raiz: Node3D   # o desenho da cela, deslocado para que a origem fique NA PORTA (o E vale perto da porta, não dos presos)


func _ready() -> void:
	super()
	id = "setor_prisao"
	texto = "Abrir a cela (precisa de chave)"
	raio = 3.0
	_raiz = Node3D.new()
	add_child(_raiz)
	_raiz.position.z = -(4.0 if tipo != "dragao" else 7.0) / 2.0
	var ferro := VilaRefugio._mat(Color(0.1, 0.1, 0.12))
	var l := 4.0 if tipo != "dragao" else 7.0
	for dx in [-l / 2.0, l / 2.0]:
		for dz in [-l / 2.0, l / 2.0]:
			_barra(Vector3(dx, 1.4, dz), Vector3(0.18, 2.8, 0.18), ferro, _raiz)
	for y in [0.1, 2.8]:
		for lado in [-l / 2.0, l / 2.0]:
			_barra(Vector3(0.0, y, lado), Vector3(l, 0.12, 0.12), ferro, _raiz)
			_barra(Vector3(lado, y, 0.0), Vector3(0.12, 0.12, l), ferro, _raiz)
	var n := int(l / 0.5)
	for i in n:   # grades de três lados
		var t := -l / 2.0 + 0.25 + i * 0.5
		_barra(Vector3(t, 1.4, -l / 2.0), Vector3(0.07, 2.7, 0.07), ferro, _raiz)
		_barra(Vector3(-l / 2.0, 1.4, t), Vector3(0.07, 2.7, 0.07), ferro, _raiz)
		_barra(Vector3(l / 2.0, 1.4, t), Vector3(0.07, 2.7, 0.07), ferro, _raiz)
	_porta = Node3D.new()
	_porta.position = Vector3(-l / 2.0, 0.0, l / 2.0)
	_raiz.add_child(_porta)
	for i in n:
		_barra(Vector3(0.25 + i * 0.5, 1.4, 0.0), Vector3(0.07, 2.7, 0.07), ferro, _porta)
	_barra(Vector3(l / 2.0, 0.15, 0.0), Vector3(l, 0.1, 0.1), ferro, _porta)
	_barra(Vector3(l / 2.0, 2.75, 0.0), Vector3(l, 0.1, 0.1), ferro, _porta)
	var corpo := StaticBody3D.new()   # a cela é sólida; a porta aberta deixa de ser (o corpo é só o fundo e os lados)
	for lado in [Vector3(0, 1.4, -l / 2.0), Vector3(-l / 2.0, 1.4, 0), Vector3(l / 2.0, 1.4, 0)]:
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(l, 2.8, 0.3) if lado.z != 0.0 else Vector3(0.3, 2.8, l)
		cs.shape = forma
		cs.position = lado
		corpo.add_child(cs)
	_raiz.add_child(corpo)
	var rotulo := Label3D.new()
	rotulo.text = {"civis": "Cela dos Civis", "soldados": "Cela dos Soldados", "dragao": "Jaula do Dragão"}[tipo]
	rotulo.font_size = 40
	rotulo.pixel_size = 0.005
	rotulo.outline_size = 8
	rotulo.modulate = Color(0.95, 0.85, 0.6)
	rotulo.position = Vector3(0, 3.4, l / 2.0)
	_raiz.add_child(rotulo)
	if tipo == "dragao":
		var d := (load("res://scenes/criaturas/filhote_de_asa_visual.tscn") as PackedScene).instantiate() as Node3D
		d.scale = Vector3.ONE * 1.1
		d.position.y = 0.05
		_raiz.add_child(d)
		ocupantes.append(d)


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
		GerenciadorMissoes.instancia.aviso.emit("Trancada. Falta uma chave: os guardas de Ferrogris carregam as chaves.", 3.0)
		return
	super()


func _ao_acionar() -> void:
	texto = "Cela aberta"
	create_tween().tween_property(_porta, "rotation_degrees:y", -100.0, 0.5)
	await get_tree().create_timer(0.5).timeout
	for o in ocupantes:
		if not is_instance_valid(o):
			continue
		if o is Npc:   # civis e soldados saem pela frente e seguem para o portão
			var npc := o as Npc
			npc.rotina = [{"ir": global_position + global_transform.basis.z * 10.0, "vel": 2.4}, {"esperar": 99.0, "anim": "Idle"}]
			npc._passo = -1
			npc._proximo_passo()
		else:   # o dragão jovem sobe e se afasta
			if o.has_method("tocar"):
				o.call("tocar", "Fly", 0.1)
			var tw := create_tween()
			tw.tween_property(o, "global_position", o.global_position + Vector3(0, 28, -50), 5.0).set_ease(Tween.EASE_IN)
			tw.tween_callback(o.queue_free)
