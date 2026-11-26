class_name QuadroDeAvisos
extends Interagivel
## Quadro de avisos da praça: duas estacas e uma tábua com papéis. Mostra o próximo serviço disponível
## (ou por que ainda não pode ler).

func _ready() -> void:
	super()
	id = "quadro_avisos"
	texto = "Ler o quadro de avisos"
	uma_vez = false
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.36, 0.24, 0.13)
	var papel := StandardMaterial3D.new()
	papel.albedo_color = Color(0.85, 0.8, 0.65)
	for x in [-0.8, 0.8]:
		_caixa(Vector3(x, 1.0, 0.0), Vector3(0.12, 2.0, 0.12), madeira)
	_caixa(Vector3(0.0, 1.35, 0.0), Vector3(1.8, 1.0, 0.08), madeira)
	for p in [[-0.5, 1.5, 0.3, 0.4], [0.05, 1.3, 0.35, 0.45], [0.55, 1.5, 0.3, 0.35]]:
		_caixa(Vector3(p[0], p[1], 0.06), Vector3(p[2], p[3], 0.02), papel)
	var corpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.8, 2.0, 0.3)
	cs.shape = forma
	cs.position.y = 1.0
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
	if GerenciadorMissoes.instancia == null:
		return
	if Jogo.historia:
		GerenciadorMissoes.instancia.ler_quadro()
	else:   # mundo aberto sem missões: o quadro não oferece serviço
		GerenciadorMissoes.instancia.aviso.emit("Não há aviso novo no quadro.", 3.0)
