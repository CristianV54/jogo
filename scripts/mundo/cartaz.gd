class_name Cartaz
extends Interagivel
## Cartaz, carta ou inscrição que o Torin lê com E: uma tábua com papel (ou uma placa de pedra) e o texto numa cena de
## diálogo. É por aqui que o Imperador Solon aparece antes do Capítulo V: ordens, cartas e decretos espalhados pelo mundo.

var titulo := "Aviso do Império"
var linhas: Array[String] = []
var pedra := false     # placa de estátua em vez de cartaz de madeira


## Cria e coloca um cartaz em `pos` (coordenadas do pai, com o y do chão) olhando para `giro` (radianos em Y).
static func colocar(pai: Node3D, pos: Vector3, giro: float, titulo_c: String, linhas_c: Array, de_pedra := false) -> Cartaz:
	var c := Cartaz.new()
	c.titulo = titulo_c
	for l in linhas_c:
		c.linhas.append(String(l))
	c.pedra = de_pedra
	c.position = pos
	c.rotation.y = giro
	pai.add_child(c)
	return c


func _ready() -> void:
	super()
	texto = "Ler: " + titulo
	raio = 3.0
	uma_vez = false
	var base := StandardMaterial3D.new()
	base.albedo_color = Color(0.5, 0.5, 0.52) if pedra else Color(0.34, 0.22, 0.12)
	base.roughness = 1.0
	var papel := StandardMaterial3D.new()
	papel.albedo_color = Color(0.82, 0.78, 0.62) if not pedra else Color(0.62, 0.62, 0.64)
	papel.roughness = 1.0
	var selo := StandardMaterial3D.new()
	selo.albedo_color = Color(0.55, 0.08, 0.06)
	for x in [-0.7, 0.7]:
		_caixa(Vector3(x, 0.9, 0.0), Vector3(0.12, 1.8, 0.12), base)
	_caixa(Vector3(0.0, 1.3, 0.0), Vector3(1.6, 1.0, 0.08), base)
	_caixa(Vector3(0.0, 1.3, 0.05), Vector3(1.3, 0.8, 0.02), papel)
	_caixa(Vector3(0.0, 1.0, 0.07), Vector3(0.22, 0.22, 0.02), selo)   # selo vermelho do Império
	var rotulo := Label3D.new()   # o título escrito no papel (o texto inteiro abre ao apertar E)
	rotulo.text = titulo.to_upper() + "\n- - -"
	rotulo.font_size = 30
	rotulo.pixel_size = 0.0036
	rotulo.outline_size = 0
	rotulo.modulate = Color(0.12, 0.08, 0.05)
	rotulo.width = 330.0
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.position = Vector3(0.0, 1.5, 0.065)
	add_child(rotulo)
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.6, 1.8, 0.3)
	cs.shape = forma
	cs.position.y = 0.9
	corpo.add_child(cs)
	add_child(corpo)


func _caixa(pos: Vector3, tam: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	b.material = mat
	mi.mesh = b
	mi.position = pos
	add_child(mi)


func _ao_acionar() -> void:
	var jogo := get_tree().get_first_node_in_group("jogo")
	if jogo == null or linhas.is_empty():
		return
	var cena: Array = []
	for l in linhas:
		cena.append([titulo, l])
	jogo.cena_dialogo(cena)
