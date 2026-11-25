class_name MapaDoMundo
extends Control
## Mapa do mundo (tecla M): a ilha inteira na tela, pintada (biomas, mata, praia, mar, rios). Interativo:
##   roda do mouse (ou + e -) aproxima e afasta; arrastar com o botão esquerdo move o mapa;
##   clique marca o destino (bandeira); clique na bandeira ou botão direito tira a marca.
## Como num mapa de verdade, os nomes aparecem por importância: de longe só o reino, as cidades e as vilas grandes;
## chegando perto aparecem fazendas, postos e cabanas. O Jogo ouve `destino_mudou` e guia o Torin até lá.

signal destino_mudou(tem: bool, ponto: Vector2)

## Onde cada missão acontece (para o anel dourado do mapa).
const REGIAO_DA_MISSAO := {
	"C1-M1": "refugio_do_pinhal", "C1-M2": "pomar_alto", "C1-M3": "refugio_do_pinhal", "C1-M4": "refugio_do_pinhal",
	"C2-M1": "bosque_velado", "C2-M2": "bosque_velado", "C2-M3": "bosque_velado", "C2-M4": "bosque_velado",
	"C3-M1": "acampamento_ruptura", "C3-M2": "fronteira_ferrogris", "C3-M3": "fronteira_ferrogris", "C3-M4": "fronteira_ferrogris",
	"C4-M1": "cratera_ignis", "C4-M2": "cratera_ignis", "C4-M3": "cratera_ignis", "C4-M4": "cratera_ignis",
	"C5-M1": "valdoria", "C5-M2": "castelo_imperial", "C5-M3": "castelo_imperial", "C5-M4": "castelo_imperial",
}
const COR_ACENTO := Color(0.95, 0.72, 0.2)
const COR_TINTA := Color(0.16, 0.1, 0.06)
const ZOOM_MAX := 8.0
const ZOOM_NOMES_PEQUENOS := 3.0   # a partir deste zoom aparecem os nomes de fazendas, postos e cabanas

var alvo := ""                 # região da missão ativa
var tem_destino := false
var destino := Vector2.ZERO    # ponto marcado, em metros do mundo
var zoom := 1.0
var centro := Vector2.ZERO     # ponto do mundo no meio da tela
var _t := 0.0
var _arrastando := false
var _arrastou := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visible = false


func mostrar(dados: Dictionary) -> void:
	alvo = dados.get("alvo", "")
	zoom = 1.0
	centro = MundoDados.LIMITES.get_center()
	visible = true
	queue_redraw()


func esconder() -> void:
	visible = false
	_arrastando = false


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


## Pixels por metro com o zoom atual (zoom 1 = a ilha inteira cabe na tela).
func _escala() -> float:
	var tela := get_viewport_rect().size
	return minf(tela.x, tela.y) / MundoDados.LIMITES.size.y * zoom * 1.08


func mundo_para_tela(p: Vector2) -> Vector2:
	return get_viewport_rect().size / 2.0 + (p - centro) * _escala()


func tela_para_mundo(q: Vector2) -> Vector2:
	return centro + (q - get_viewport_rect().size / 2.0) / _escala()


func _aproximar(fator: float, em_torno: Vector2) -> void:
	var antes := tela_para_mundo(em_torno)
	zoom = clampf(zoom * fator, 1.0, ZOOM_MAX)
	centro += antes - tela_para_mundo(em_torno)   # o ponto debaixo do mouse fica parado
	_limitar()


func _limitar() -> void:
	var lim := MundoDados.LIMITES
	centro = centro.clamp(lim.position, lim.end)
	if zoom <= 1.0:
		centro = lim.get_center()


func marcar(ponto: Vector2) -> void:
	tem_destino = true
	destino = ponto
	destino_mudou.emit(true, ponto)


func desmarcar() -> void:
	if tem_destino:
		tem_destino = false
		destino_mudou.emit(false, Vector2.ZERO)


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton:
		var e := evento as InputEventMouseButton
		if e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_aproximar(1.2, e.position)
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_aproximar(1.0 / 1.2, e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
			desmarcar()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_arrastando = true
				_arrastou = false
			else:
				_arrastando = false
				if not _arrastou:   # clique sem arrastar: marca (ou, em cima da bandeira, desmarca)
					if tem_destino and mundo_para_tela(destino).distance_to(e.position) < 16.0:
						desmarcar()
					elif Costa.distancia(tela_para_mundo(e.position).x, tela_para_mundo(e.position).y) > 0.0:
						marcar(tela_para_mundo(e.position))
	elif evento is InputEventMouseMotion and _arrastando:
		var m := evento as InputEventMouseMotion
		if m.relative.length() > 0.5:
			_arrastou = true
			centro -= m.relative / _escala()
			_limitar()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not visible or not evento.is_pressed():
		return
	var k := evento as InputEventKey
	if k.physical_keycode == KEY_EQUAL or k.physical_keycode == KEY_KP_ADD:
		_aproximar(1.3, get_viewport_rect().size / 2.0)
	elif k.physical_keycode == KEY_MINUS or k.physical_keycode == KEY_KP_SUBTRACT:
		_aproximar(1.0 / 1.3, get_viewport_rect().size / 2.0)


func _nome(q: Vector2, texto: String, tamanho: int, cor := COR_TINTA) -> void:
	var fonte := ThemeDB.fallback_font
	var larg := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	var pos := q + Vector2(-larg / 2.0, 0.0)
	draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 5, Color(0.96, 0.92, 0.8, 0.9))
	draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)


func _draw() -> void:
	var tela := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, tela), Color(0.13, 0.3, 0.44))   # o mar cobre a tela toda
	var mundo := Mundo.instancia
	if mundo == null:
		return
	var lim := MundoDados.LIMITES
	var esc := _escala()
	if mundo.mapa_floresta:
		draw_texture_rect(mundo.mapa_floresta, Rect2(mundo_para_tela(lim.position), lim.size * esc), false)
	for id in mundo.estradas:      # estradas principais: um traço fino de tinta, como em mapa antigo
		var pts := PackedVector2Array()
		for p in mundo.estradas[id]:
			pts.append(mundo_para_tela(p))
		draw_polyline(pts, Color(0.42, 0.28, 0.14, 0.75), clampf(1.2 * zoom, 1.5, 4.0), true)
	if zoom >= ZOOM_NOMES_PEQUENOS:   # trilhas até as fazendas e cabanas: só de perto
		for trilha in mundo.trilhas:
			var pts := PackedVector2Array()
			for p in trilha:
				pts.append(mundo_para_tela(p))
			draw_polyline(pts, Color(0.42, 0.28, 0.14, 0.5), 1.5, true)
	for pid in mundo.povoados:
		var pv: Dictionary = mundo.povoados[pid]
		var q := mundo_para_tela(pv["centro"])
		if String(pv.get("tipo", "")) == "vila":   # vila: casinha e nome sempre
			draw_circle(q, 4.5, Color(0.96, 0.92, 0.8))
			draw_circle(q, 3.0, Color(0.62, 0.2, 0.12))
			_nome(q + Vector2(0, -8), String(pv.get("nome", "")), 13)
		else:                                        # lugar pequeno: um ponto; o nome só de perto
			draw_circle(q, 2.2, Color(0.3, 0.2, 0.12))
			if zoom >= ZOOM_NOMES_PEQUENOS:
				_nome(q + Vector2(0, -6), String(pv.get("nome", "")), 11, Color(0.3, 0.2, 0.12))
	for id in MundoDados.REGIOES:   # cidades e lugares grandes: marca maior e nome em destaque
		var q := mundo_para_tela(MundoDados.centro(id))
		var capital: bool = id == "valdoria"
		var r := 8.0 if capital else 6.0
		draw_rect(Rect2(q - Vector2(r, r), Vector2(r, r) * 2.0), Color(0.96, 0.92, 0.8))
		draw_rect(Rect2(q - Vector2(r - 2, r - 2), Vector2(r - 2, r - 2) * 2.0), Color(0.5, 0.12, 0.1) if capital else COR_TINTA)
		if id == alvo:   # a missão ativa fica aqui
			draw_arc(q, r + 7.0 + sin(_t * 4.0) * 2.0, 0.0, TAU, 32, COR_ACENTO, 2.5)
		if id == "castelo_imperial" and zoom < 1.6:
			continue   # de longe o castelo faz parte do reino: um nome só
		var nome := "VALDORIA, o reino" if capital and zoom < 1.6 else String(MundoDados.REGIOES[id]["nome"])
		_nome(q + Vector2(0, -r - 6), nome.to_upper() if capital else nome, 19 if capital else 15)
	if tem_destino:   # bandeira do destino
		var q := mundo_para_tela(destino)
		draw_line(q, q + Vector2(0, -22), COR_TINTA, 2.5)
		draw_colored_polygon(PackedVector2Array([q + Vector2(1, -22), q + Vector2(17, -17), q + Vector2(1, -11)]), Color(0.85, 0.15, 0.1))
		draw_circle(q, 3.0, COR_TINTA)
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog:   # o Torin: seta apontando para onde ele olha
		var pj := Vector2(jog.global_position.x, jog.global_position.z)
		var q := mundo_para_tela(pj)
		if tem_destino:
			draw_dashed_line(q, mundo_para_tela(destino), Color(0.85, 0.15, 0.1, 0.8), 2.0, 8.0)
		var f := Vector2(-sin(jog.global_rotation.y), -cos(jog.global_rotation.y))
		var lado := Vector2(-f.y, f.x)
		draw_colored_polygon(PackedVector2Array([q + f * 13.0, q - f * 7.0 + lado * 8.0, q - f * 7.0 - lado * 8.0]), COR_TINTA)
		draw_colored_polygon(PackedVector2Array([q + f * 10.0, q - f * 5.0 + lado * 5.5, q - f * 5.0 - lado * 5.5]), Color(1, 1, 1))
	# rosa dos ventos, escala e ajuda (discretas, nos cantos)
	var fonte := ThemeDB.fallback_font
	var n := Vector2(tela.x - 56, 64)
	draw_colored_polygon(PackedVector2Array([n + Vector2(0, -26), n + Vector2(8, 0), n + Vector2(-8, 0)]), Color(1, 1, 1, 0.9))
	draw_string(fonte, n + Vector2(-6, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))
	var metros := 1000.0 if zoom < 2.5 else (250.0 if zoom < 6.0 else 100.0)
	var b := Vector2(30, tela.y - 34)
	draw_line(b, b + Vector2(metros * esc, 0), Color(1, 1, 1, 0.9), 3.0)
	draw_string(fonte, b + Vector2(0, -8), ("%d km" % int(metros / 1000.0)) if metros >= 1000.0 else ("%d m" % int(metros)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.9))
	var ajuda := "roda do mouse: zoom    arrastar: mover    clique: marcar destino    botão direito: tirar a marca    M: fechar"
	if tem_destino and jog:
		ajuda = "Destino marcado a %d m.    " % int(Vector2(jog.global_position.x, jog.global_position.z).distance_to(destino)) + ajuda
	draw_string_outline(fonte, Vector2(30, tela.y - 10), ajuda, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 0.6))
	draw_string(fonte, Vector2(30, tela.y - 10), ajuda, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.9))
