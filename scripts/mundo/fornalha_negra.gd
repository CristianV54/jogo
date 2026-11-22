class_name FornalhaNegra
extends Node3D
## Fornalha negra da Cratera de Ignis. Três tipos, cada um com um mecanismo próprio:
##   0 SOPRO:  gire as 3 válvulas de vapor dentro de 25 segundos (senão a pressão volta e recomeça);
##   1 CANOS:  quebre os 2 canos de lava a golpes de espada;
##   2 RUNAS:  toque as 3 runas na ordem 1, 2, 3 (erro apaga todas).
## Ao apagar avisa as missões ("interagir", "fornalha_apagada") e emite `apagou`.

signal apagou

const TIPOS := ["Fornalha do Sopro", "Fornalha dos Canos", "Fornalha das Runas"]

var tipo := 0
var apagada := false
var _fogo: Fogo
var _valvulas: Array[Gatilho] = []
var _giradas := 0
var _janela := 0.0
var _canos_restantes := 2
var _runas: Array[Gatilho] = []
var _proxima := 1


## Cano de lava que leva golpes (grupo "atingiveis").
class Cano extends StaticBody3D:
	signal quebrado
	var morto := false
	var raio_colisao := 0.9
	var vida := 40
	var _mesh: MeshInstance3D

	func _ready() -> void:
		add_to_group("atingiveis")
		collision_layer = 1
		_mesh = MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.35
		c.bottom_radius = 0.35
		c.height = 3.0
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.2, 0.15, 0.14)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.3, 0.05)
		m.emission_energy_multiplier = 1.0
		c.material = m
		_mesh.mesh = c
		_mesh.position.y = 1.5
		add_child(_mesh)
		var cs := CollisionShape3D.new()
		var f := CylinderShape3D.new()
		f.radius = 0.5
		f.height = 3.0
		cs.shape = f
		cs.position.y = 1.5
		add_child(cs)

	func receber_dano(quantidade: int, _de: Node3D = null) -> void:
		if morto:
			return
		vida -= quantidade
		Efeitos.piscar(_mesh, 0.12)
		if vida > 0:
			return
		morto = true
		collision_layer = 0
		create_tween().tween_property(_mesh, "scale", Vector3(1.0, 0.1, 1.0), 0.4)
		quebrado.emit()


func _ready() -> void:
	var pedra := VilaRefugio._mat(Color(0.14, 0.12, 0.12))
	_corpo(pedra)
	_fogo = Fogo.new()
	_fogo.escala = 1.4
	_fogo.energia_luz = 2.5
	_fogo.alcance_luz = 16.0
	_fogo.position = Vector3(0, 3.1, 0)
	add_child(_fogo)
	var rotulo := Label3D.new()
	rotulo.text = TIPOS[tipo]
	rotulo.font_size = 44
	rotulo.pixel_size = 0.0055
	rotulo.outline_size = 8
	rotulo.modulate = Color(1.0, 0.8, 0.5)
	rotulo.position = Vector3(0, 6.2, 0)
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(rotulo)
	match tipo:
		0:
			for k in 3:
				var v := _gatilho(Vector3(-4.0 + k * 4.0, 0.0, 4.2), "Girar válvula %d (as 3 em 25 s)" % (k + 1))
				v.ao_usar = _ao_girar
				_valvulas.append(v)
				_roda(v, Color(0.7, 0.2, 0.15))
		1:
			for lado in [-1.0, 1.0]:
				var c := Cano.new()
				c.position = Vector3(lado * 3.8, 0.0, 3.4)
				add_child(c)
				c.quebrado.connect(_ao_cano_quebrado)
			var dica := Label3D.new()
			dica.text = "Quebre os dois canos de lava"
			dica.font_size = 34
			dica.pixel_size = 0.005
			dica.outline_size = 8
			dica.position = Vector3(0, 1.2, 6.0)
			dica.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(dica)
		2:
			for k in 3:
				var numero: int = [2, 3, 1][k]   # fora de ordem na fileira
				var r := _gatilho(Vector3(-3.5 + k * 3.5, 0.0, 4.4), "Tocar a runa %d" % numero)
				r.set_meta("numero", numero)
				r.ao_usar = _ao_runa
				_runas.append(r)
				var pilar := MeshInstance3D.new()
				var b := BoxMesh.new()
				b.size = Vector3(0.8, 1.6, 0.8)
				b.material = VilaRefugio._mat(Color(0.2, 0.2, 0.24))
				pilar.mesh = b
				pilar.position.y = 0.8
				r.add_child(pilar)
				var n := Label3D.new()
				n.name = "Numero"
				n.text = str(numero)
				n.font_size = 80
				n.pixel_size = 0.008
				n.outline_size = 10
				n.modulate = Color(0.4, 0.7, 1.0)
				n.position = Vector3(0, 2.0, 0)
				n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				r.add_child(n)


func _corpo(pedra: Material) -> void:
	var corpo := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(4.5, 3.0, 4.5)
	b.material = pedra
	mi.mesh = b
	mi.position.y = 1.5
	corpo.add_child(mi)
	var chamine := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.9
	c.bottom_radius = 1.3
	c.height = 4.0
	c.material = pedra
	chamine.mesh = c
	chamine.position = Vector3(0, 5.0, -1.2)
	corpo.add_child(chamine)
	var cs := CollisionShape3D.new()
	var f := BoxShape3D.new()
	f.size = Vector3(4.5, 3.0, 4.5)
	cs.shape = f
	cs.position.y = 1.5
	corpo.add_child(cs)
	add_child(corpo)


func _gatilho(pos: Vector3, texto: String) -> Gatilho:
	var g := Gatilho.new()
	g.texto = texto
	g.raio = 2.0
	g.uma_vez = true
	g.position = pos
	add_child(g)
	return g


func _roda(pai: Node3D, cor: Color) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 0.15
	c.material = VilaRefugio._mat(cor)
	mi.mesh = c
	mi.position.y = 1.2
	mi.rotation_degrees.x = 90.0
	pai.add_child(mi)
	var haste := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.18, 1.2, 0.18)
	b.material = VilaRefugio._mat(Color(0.15, 0.15, 0.17))
	haste.mesh = b
	haste.position.y = 0.6
	pai.add_child(haste)


# ---- tipo 0: válvulas

func _ao_girar(g: Gatilho) -> void:
	_giradas += 1
	if _giradas == 1:
		_janela = 25.0
	GerenciadorMissoes.instancia.aviso.emit("Válvula %d de 3 girada." % _giradas, 1.5)
	create_tween().tween_property(g.get_child(0), "rotation_degrees:z", 360.0, 0.5)
	if _giradas >= 3:
		_apagar()


func _process(delta: float) -> void:
	if tipo != 0 or apagada or _giradas == 0:
		return
	_janela -= delta
	if _janela <= 0.0:
		_giradas = 0
		for v in _valvulas:
			v.usado = false
		GerenciadorMissoes.instancia.aviso.emit("A pressão voltou! Gire as três válvulas mais rápido.", 3.0)


# ---- tipo 1: canos

func _ao_cano_quebrado() -> void:
	_canos_restantes -= 1
	GerenciadorMissoes.instancia.aviso.emit("Cano rompido. Faltam %d." % _canos_restantes, 1.8)
	if _canos_restantes <= 0:
		_apagar()


# ---- tipo 2: runas

func _ao_runa(g: Gatilho) -> void:
	var numero: int = g.get_meta("numero")
	var n := g.get_node("Numero") as Label3D
	if numero == _proxima:
		_proxima += 1
		n.modulate = Color(0.4, 1.0, 0.4)
		if _proxima > 3:
			_apagar()
		return
	_proxima = 1
	for r in _runas:
		r.usado = false
		(r.get_node("Numero") as Label3D).modulate = Color(0.4, 0.7, 1.0)
	GerenciadorMissoes.instancia.aviso.emit("Ordem errada: as runas se apagaram. Comece pela 1.", 3.0)


func _apagar() -> void:
	if apagada:
		return
	apagada = true
	_fogo.queue_free()
	GerenciadorMissoes.instancia.aviso.emit("%s apagada!" % TIPOS[tipo], 3.0)
	GerenciadorMissoes.evento("interagir", "fornalha_apagada")
	apagou.emit()


## A fornalha desaba quando Ignis-Maw se liberta (destrói parte das forjas).
func desabar() -> void:
	create_tween().tween_property(self, "scale", Vector3(1.0, 0.25, 1.0), 1.5)
	var chama := Fogo.new()
	chama.escala = 2.2
	chama.energia_luz = 3.0
	chama.alcance_luz = 20.0
	chama.position = Vector3(0, 1.2, 0)
	get_parent().add_child(chama)
	chama.global_position = global_position + Vector3(0, 1.0, 0)
