class_name MapaDoMundo
extends Control
## Mapa do mundo (tecla M): as 8 regiões ligadas pelas estradas, com a posição do jogador, o que já está liberado, o que
## ainda está trancado (e por quê) e a região da missão ativa. Desenhado por código, sem arte final.

const REGIOES := {
	"pomar_alto": {"nome": "Pomar Alto", "pos": Vector2(0.10, 0.62)},
	"refugio_do_pinhal": {"nome": "Refúgio do Pinhal", "pos": Vector2(0.28, 0.62)},
	"bosque_velado": {"nome": "Bosque Velado\ne Mina", "pos": Vector2(0.28, 0.26)},
	"acampamento_ruptura": {"nome": "Acampamento\nda Ruptura", "pos": Vector2(0.46, 0.66)},
	"fronteira_ferrogris": {"nome": "Fortaleza de\nFerrogris", "pos": Vector2(0.62, 0.56)},
	"cratera_ignis": {"nome": "Cratera de Ignis", "pos": Vector2(0.78, 0.40)},
	"valdoria": {"nome": "Valdoria", "pos": Vector2(0.66, 0.2)},
	"castelo_imperial": {"nome": "Castelo Imperial", "pos": Vector2(0.88, 0.14)},
}
## Estradas entre as regiões (os portais de cada área).
const ESTRADAS := [
	["pomar_alto", "refugio_do_pinhal"], ["refugio_do_pinhal", "bosque_velado"], ["refugio_do_pinhal", "acampamento_ruptura"],
	["acampamento_ruptura", "fronteira_ferrogris"], ["fronteira_ferrogris", "cratera_ignis"], ["cratera_ignis", "valdoria"],
	["valdoria", "castelo_imperial"],
]
## Onde cada missão acontece (para o anel dourado do mapa).
const REGIAO_DA_MISSAO := {
	"C1-M1": "refugio_do_pinhal", "C1-M2": "pomar_alto", "C1-M3": "refugio_do_pinhal", "C1-M4": "refugio_do_pinhal",
	"C2-M1": "bosque_velado", "C2-M2": "bosque_velado", "C2-M3": "bosque_velado", "C2-M4": "bosque_velado",
	"C3-M1": "acampamento_ruptura", "C3-M2": "fronteira_ferrogris", "C3-M3": "fronteira_ferrogris", "C3-M4": "fronteira_ferrogris",
	"C4-M1": "cratera_ignis", "C4-M2": "cratera_ignis", "C4-M3": "cratera_ignis", "C4-M4": "cratera_ignis",
	"C5-M1": "valdoria", "C5-M2": "castelo_imperial", "C5-M3": "castelo_imperial", "C5-M4": "castelo_imperial",
}
const COR_FUNDO := Color(0.07, 0.06, 0.05, 1.0)
const COR_ESTRADA := Color(0.55, 0.45, 0.3)
const COR_ACENTO := Color(0.95, 0.72, 0.2)

var atual := ""
var alvo := ""                 # região da missão ativa
var liberadas: Dictionary = {}  # id -> true/false
var motivos: Dictionary = {}    # id -> texto de por que está trancada
var missao_texto := ""
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func mostrar(dados: Dictionary) -> void:
	atual = dados.get("atual", "")
	alvo = dados.get("alvo", "")
	liberadas = dados.get("liberadas", {})
	motivos = dados.get("motivos", {})
	missao_texto = dados.get("missao", "")
	visible = true
	queue_redraw()


func esconder() -> void:
	visible = false


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var tela := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, tela), Color(0.02, 0.02, 0.02, 0.97))   # cobre a tela toda (some vida, rastreador e dicas)
	var fonte := ThemeDB.fallback_font
	draw_string(fonte, Vector2(40, 52), "MAPA DO MUNDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, COR_ACENTO)
	draw_string(fonte, Vector2(tela.x - 160, 52), "M fecha", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.8, 0.8))
	var mundo := Mundo.instancia
	if mundo == null:
		return
	var lim := MundoDados.LIMITES
	var area := Rect2(40, 70, tela.x * 0.42, tela.y - 100)
	var esc := minf(area.size.x / lim.size.x, area.size.y / lim.size.y)
	var origem := area.position + (area.size - lim.size * esc) / 2.0
	draw_rect(Rect2(origem, lim.size * esc), Color(0.1, 0.13, 0.09))
	draw_rect(Rect2(origem, lim.size * esc), COR_ESTRADA, false, 2.0)
	var mundo_para_mapa := func(p: Vector2) -> Vector2: return origem + (p - lim.position) * esc
	for r in mundo.terreno.rios:   # rios
		var pts := PackedVector2Array()
		for p in r["pontos"]:
			pts.append(mundo_para_mapa.call(p))
		draw_polyline(pts, Color(0.25, 0.5, 0.75), 2.5)
	for id in mundo.estradas:      # estradas
		var pts := PackedVector2Array()
		for p in mundo.estradas[id]:
			pts.append(mundo_para_mapa.call(p))
		draw_polyline(pts, COR_ESTRADA, 3.0)
	for id in REGIOES:
		var rect := MundoDados.retangulo(id)
		var a: Vector2 = mundo_para_mapa.call(rect.position)
		var b: Vector2 = mundo_para_mapa.call(rect.end)
		var livre: bool = liberadas.get(id, false)
		draw_rect(Rect2(a, b - a), Color(0.22, 0.42, 0.24, 0.85) if livre else Color(0.28, 0.26, 0.25, 0.85))
		draw_rect(Rect2(a, b - a), Color(0.6, 0.55, 0.45), false, 1.5)
		if id == alvo:   # a missão ativa fica nesta região
			draw_rect(Rect2(a - Vector2(4, 4), b - a + Vector2(8, 8)), COR_ACENTO, false, 2.0 + sin(_t * 4.0))
		if id == atual:
			draw_rect(Rect2(a + Vector2(2, 2), b - a - Vector2(4, 4)), Color(1, 1, 1, 0.6), false, 1.0)
	for pid in mundo.povoados:     # povoados e fazendas
		var q: Vector2 = mundo_para_mapa.call(mundo.povoados[pid]["centro"])
		draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), Color(0.9, 0.75, 0.35))
	for bid in mundo.barreiras:    # barreiras: vermelhas fechadas, verdes abertas
		var bar: Barreira = mundo.barreiras[bid]
		var q: Vector2 = mundo_para_mapa.call(Vector2(bar.global_position.x, bar.global_position.z))
		draw_rect(Rect2(q - Vector2(5, 2), Vector2(10, 4)), Color(0.4, 0.85, 0.4) if bar.aberta else Color(0.9, 0.25, 0.2))
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog:   # o Torin: seta branca apontando para onde ele olha
		var q: Vector2 = mundo_para_mapa.call(Vector2(jog.global_position.x, jog.global_position.z))
		var f := Vector2(-sin(jog.global_rotation.y), -cos(jog.global_rotation.y))
		var r := Vector2(-f.y, f.x)
		draw_colored_polygon(PackedVector2Array([q + f * 9.0, q - f * 5.0 + r * 5.0, q - f * 5.0 - r * 5.0]), Color(1, 1, 1))
	draw_string(fonte, origem + Vector2(lim.size.x * esc / 2.0 - 4.0, 16.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.8, 0.8))
	# coluna da direita: regiões, lugares e a missão
	var x := tela.x * 0.50
	var y := 100.0
	draw_string(fonte, Vector2(x, y), "Regiões", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COR_ACENTO)
	y += 10.0
	for id in REGIOES:
		y += 26.0
		var livre: bool = liberadas.get(id, false)
		draw_rect(Rect2(x, y - 14.0, 12, 12), Color(0.35, 0.65, 0.35) if livre else Color(0.35, 0.33, 0.32))
		var txt: String = String(REGIOES[id]["nome"]).replace("\n", " ")
		var cor_txt := Color(0.95, 0.92, 0.85) if livre else Color(0.6, 0.55, 0.5)
		draw_string(fonte, Vector2(x + 22, y), txt + (" (você está aqui)" if id == atual else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, cor_txt)
		if motivos.has(id):
			y += 20.0
			draw_string(fonte, Vector2(x + 22, y), motivos[id], HORIZONTAL_ALIGNMENT_LEFT, tela.x * 0.46, 14, Color(0.7, 0.62, 0.5))
	y += 40.0
	draw_string(fonte, Vector2(x, y), "Legenda: estrada marrom, rio azul, quadrado dourado = povoado, barra vermelha = barreira fechada", HORIZONTAL_ALIGNMENT_LEFT, tela.x * 0.46, 15, Color(0.75, 0.75, 0.75))
	y += 34.0
	if missao_texto != "":
		draw_rect(Rect2(x, y - 14.0, 12, 12), COR_ACENTO, false, 2.0)
		draw_string(fonte, Vector2(x + 22, y), "Missão: " + missao_texto, HORIZONTAL_ALIGNMENT_LEFT, tela.x * 0.44, 18, COR_ACENTO)
