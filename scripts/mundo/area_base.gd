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
