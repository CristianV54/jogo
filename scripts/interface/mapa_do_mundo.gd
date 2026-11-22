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
	var area := Rect2(tela.x * 0.08, tela.y * 0.08, tela.x * 0.84, tela.y * 0.82)
	draw_rect(Rect2(Vector2.ZERO, tela), Color(0.02, 0.02, 0.02, 0.97))   # cobre a tela toda (some vida, rastreador e dicas)
	draw_rect(area, COR_FUNDO)
	draw_rect(area, COR_ESTRADA, false, 2.0)
	var fonte := ThemeDB.fallback_font
	draw_string(fonte, area.position + Vector2(24, 40), "MAPA DO MUNDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, COR_ACENTO)
	draw_string(fonte, area.position + Vector2(area.size.x - 260, 40), "M fecha", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.8, 0.8))
	var mapa := Rect2(area.position + Vector2(20, 60), area.size - Vector2(40, 150))
	for e in ESTRADAS:   # estradas, tracejadas quando a região de destino ainda está trancada
		var a := mapa.position + mapa.size * Vector2(REGIOES[e[0]]["pos"])
		var b := mapa.position + mapa.size * Vector2(REGIOES[e[1]]["pos"])
		var aberta: bool = liberadas.get(e[1], false) and liberadas.get(e[0], false)
		if aberta:
			draw_line(a, b, COR_ESTRADA, 6.0)
		else:
			var n := int(a.distance_to(b) / 16.0)
			for i in n:
				if i % 2 == 0:
					draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), Color(0.35, 0.3, 0.25), 4.0)
	for id in REGIOES:
		var p := mapa.position + mapa.size * Vector2(REGIOES[id]["pos"])
		var livre: bool = liberadas.get(id, false)
		var cor := Color(0.35, 0.6, 0.35) if livre else Color(0.3, 0.28, 0.27)
		draw_circle(p, 17.0, Color(0.05, 0.05, 0.05))
		draw_circle(p, 14.0, cor)
		if id == alvo:   # a missão ativa fica nesta região
			draw_arc(p, 24.0 + sin(_t * 4.0) * 3.0, 0.0, TAU, 32, COR_ACENTO, 3.0)
		if id == atual:
			draw_circle(p, 6.0, Color(1, 1, 1))
		var linhas: PackedStringArray = String(REGIOES[id]["nome"]).split("\n")
		for k in linhas.size():
			draw_string(fonte, p + Vector2(-80, 40 + k * 20), linhas[k], HORIZONTAL_ALIGNMENT_CENTER, 160, 17, Color(0.95, 0.92, 0.85) if livre else Color(0.6, 0.55, 0.5))
	var y := area.position.y + area.size.y - 80
	draw_circle(area.position + Vector2(34, y - area.position.y + 6), 6.0, Color(1, 1, 1))
	draw_string(fonte, area.position + Vector2(48, y - area.position.y + 12), "Você está aqui: " + String(REGIOES.get(atual, {}).get("nome", "?")).replace("\n", " "), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.95, 0.95))
	if missao_texto != "":
		draw_arc(area.position + Vector2(34, y - area.position.y + 36), 8.0, 0.0, TAU, 20, COR_ACENTO, 3.0)
		draw_string(fonte, area.position + Vector2(48, y - area.position.y + 42), "Missão: " + missao_texto + (" (anel dourado)" if alvo != "" else ""), HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 80, 18, COR_ACENTO)
	if motivos.has(atual) == false:
		var trancadas: PackedStringArray = []
		for id in motivos:
			trancadas.append("%s: %s" % [String(REGIOES[id]["nome"]).replace("\n", " "), motivos[id]])
		if trancadas.size() > 0:
			draw_string(fonte, area.position + Vector2(48, y - area.position.y + 66), trancadas[0], HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 80, 16, Color(0.75, 0.7, 0.65))
