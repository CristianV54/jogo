class_name MapaDoMundo
extends Control
## Mapa do mundo (tecla M): a ilha inteira na tela, em estilo de mapa antigo desenhado (ver PinturaDoMapa). Interativo:
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
var _nomes_postos: Array[Rect2] = []   # onde já há nome escrito neste quadro
var _fonte_regiao: Font
var _cor_do_mar := Color(0.5, 0.62, 0.64)
var _fonte_vila: Font
var _costa := PackedVector2Array()   # contorno da ilha, em metros do mundo


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	var lim := MundoDados.LIMITES.size
	return minf(tela.x / lim.x, (tela.y - 46.0) / lim.y) * zoom * 1.0   # 46 = a faixa da escala, embaixo


func mundo_para_tela(p: Vector2) -> Vector2:
	return get_viewport_rect().size / 2.0 - Vector2(0, 23) + (p - centro) * _escala()


func tela_para_mundo(q: Vector2) -> Vector2:
	return centro + (q - get_viewport_rect().size / 2.0 + Vector2(0, 23)) / _escala()


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


## Escreve um nome centrado em `q`. Se já houver outro nome ali, este desce para baixo da marca.
func _nome(q: Vector2, texto: String, tamanho: int, fonte: Font, cor := COR_TINTA, entre_letras := 0.0) -> void:
	var larg := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x + entre_letras * texto.length()
	var pos := q + Vector2(-larg / 2.0, 0.0)
	var caixa := Rect2(pos + Vector2(0, -tamanho), Vector2(larg, tamanho + 3.0))
	for outra in _nomes_postos:
		if caixa.intersects(outra):
			pos.y += tamanho + 22.0
			caixa.position.y += tamanho + 22.0
			break
	_nomes_postos.append(caixa)
	if entre_letras <= 0.0:
		draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 4, Color(0.9, 0.84, 0.68, 0.85))
		draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
		return
	for letra in texto:   # letras espaçadas, como nos nomes de região de mapa antigo
		draw_string_outline(fonte, pos, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 4, Color(0.9, 0.84, 0.68, 0.85))
		draw_string(fonte, pos, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
		pos.x += fonte.get_string_size(letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x + entre_letras


## Fonte com serifa do sistema (Georgia no Mac), reta ou itálica: letra de mapa, não de menu.
func _serifa(italica: bool, negrito: bool) -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Georgia", "Palatino", "Baskerville", "Times New Roman", "DejaVu Serif", "serif"])
	f.font_italic = italica
	f.font_weight = 700 if negrito else 400
	return f


## Contorno da ilha (linha da praia), achado uma vez: de cada direção, o ponto onde a terra acaba.
func _tracar_costa() -> void:
	var meio := MundoDados.LIMITES.get_center()
	var longe := MundoDados.LIMITES.size.length() * 0.5
	for k in 900:
		var dir := Vector2.from_angle(TAU * k / 900.0)
		var dentro := 0.0
		var fora := longe
		for passo in 22:   # bisseção: terra de um lado, mar do outro
			var m := (dentro + fora) / 2.0
			if Costa.distancia(meio.x + dir.x * m, meio.y + dir.y * m) > 0.0:
				dentro = m
			else:
				fora = m
		_costa.append(meio + dir * dentro)
	_costa.append(_costa[0])


func _draw() -> void:
	var tela := get_viewport_rect().size
	_nomes_postos.clear()
	var mundo := Mundo.instancia
	if mundo == null:
		return
	if _fonte_regiao == null:
		_fonte_regiao = _serifa(false, true)
		_fonte_vila = _serifa(true, false)
		_tracar_costa()
		if mundo.mapa_floresta:
			_cor_do_mar = mundo.mapa_floresta.get_image().get_pixel(1, 1)   # o mar aberto da pintura: o fundo da tela usa a mesma cor
	draw_rect(Rect2(Vector2.ZERO, tela), _cor_do_mar)   # o mar cobre a tela toda
	var lim := MundoDados.LIMITES
	var esc := _escala()
	if mundo.mapa_floresta:
		draw_texture_rect(mundo.mapa_floresta, Rect2(mundo_para_tela(lim.position), lim.size * esc), false)
	# costa: linha de tinta e, mar adentro, linhas cada vez mais fracas (as "ondas" dos mapas antigos)
	var meio := lim.get_center()
	for onda in [[1.045, 0.12], [1.028, 0.2], [1.013, 0.32]]:
		var pts := PackedVector2Array()
		for p in _costa:
			pts.append(mundo_para_tela(meio + (p - meio) * float(onda[0])))
		draw_polyline(pts, Color(0.2, 0.3, 0.34, float(onda[1])), 1.2, true)
	var praia := PackedVector2Array()
	for p in _costa:
		praia.append(mundo_para_tela(p))
	draw_polyline(praia, Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, 0.85), 2.0, true)
	for r in mundo.terreno.rios:   # rios: azul de aquarela com a margem em tinta
		var pts := PackedVector2Array()
		for p in r["pontos"]:
			pts.append(mundo_para_tela(p))
		var larg := clampf(float(r["largura"]) * esc * 1.6, 2.0, 14.0)
		draw_polyline(pts, Color(0.22, 0.3, 0.36, 0.7), larg + 1.6, true)
		draw_polyline(pts, Color(0.56, 0.7, 0.74), larg, true)
	for id in mundo.estradas:      # estradas principais: traço fino de tinta
		var pts := PackedVector2Array()
		for p in mundo.estradas[id]:
			pts.append(mundo_para_tela(p))
		draw_polyline(pts, Color(0.36, 0.24, 0.13, 0.8), clampf(0.9 * zoom, 1.4, 3.5), true)
	if zoom >= ZOOM_NOMES_PEQUENOS:   # trilhas até as fazendas e cabanas: tracejadas, só de perto
		for trilha in mundo.trilhas:
			for i in range(0, trilha.size() - 1):
				draw_dashed_line(mundo_para_tela(trilha[i]), mundo_para_tela(trilha[i + 1]), Color(0.36, 0.24, 0.13, 0.6), 1.3, 5.0)
	for pid in mundo.povoados:
		var pv: Dictionary = mundo.povoados[pid]
		var q := mundo_para_tela(pv["centro"])
		if String(pv.get("tipo", "")) == "vila":   # vila: marca redonda e nome em itálico, sempre
			draw_circle(q, 4.5, COR_TINTA)
			draw_circle(q, 3.0, Color(0.72, 0.24, 0.14))
			_nome(q + Vector2(0, -8), String(pv.get("nome", "")), 14, _fonte_vila)
		else:                                        # lugar pequeno: um ponto; o nome só de perto
			draw_circle(q, 2.0, Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, 0.8))
			if zoom >= ZOOM_NOMES_PEQUENOS:
				_nome(q + Vector2(0, -6), String(pv.get("nome", "")), 12, _fonte_vila, Color(0.3, 0.2, 0.12))
	for id in MundoDados.REGIOES:   # cidades e lugares grandes: marca maior e nome em maiúsculas espaçadas
		var q := mundo_para_tela(MundoDados.centro(id))
		var capital: bool = id == "valdoria"
		var r := 8.0 if capital else 5.5
		draw_rect(Rect2(q - Vector2(r, r), Vector2(r, r) * 2.0), COR_TINTA)
		draw_rect(Rect2(q - Vector2(r - 2, r - 2), Vector2(r - 2, r - 2) * 2.0), Color(0.62, 0.14, 0.1) if capital else Color(0.86, 0.78, 0.6))
		if id == alvo:   # a missão ativa fica aqui
			draw_arc(q, r + 7.0 + sin(_t * 4.0) * 2.0, 0.0, TAU, 32, COR_ACENTO, 2.5)
		if id == "castelo_imperial" and zoom < 1.6:
			continue   # de longe o castelo faz parte do reino: um nome só
		_nome(q + Vector2(0, -r - 7), String(MundoDados.REGIOES[id]["nome"]).to_upper(), 22 if capital else 15, _fonte_regiao, COR_TINTA, 4.0 if capital else 2.0)
	if tem_destino:   # bandeira do destino
		var q := mundo_para_tela(destino)
		draw_line(q, q + Vector2(0, -22), COR_TINTA, 2.5)
		draw_colored_polygon(PackedVector2Array([q + Vector2(1, -22), q + Vector2(17, -17), q + Vector2(1, -11)]), Color(0.8, 0.14, 0.1))
		draw_circle(q, 3.0, COR_TINTA)
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog:   # o Torin: seta apontando para onde ele olha
		var pj := Vector2(jog.global_position.x, jog.global_position.z)
		var q := mundo_para_tela(pj)
		if tem_destino:
			draw_dashed_line(q, mundo_para_tela(destino), Color(0.8, 0.14, 0.1, 0.85), 2.0, 8.0)
		var f := Vector2(-sin(jog.global_rotation.y), -cos(jog.global_rotation.y))
		var lado := Vector2(-f.y, f.x)
		draw_colored_polygon(PackedVector2Array([q + f * 13.0, q - f * 7.0 + lado * 8.0, q - f * 7.0 - lado * 8.0]), COR_TINTA)
		draw_colored_polygon(PackedVector2Array([q + f * 10.0, q - f * 5.0 + lado * 5.5, q - f * 5.0 - lado * 5.5]), Color(0.95, 0.9, 0.78))
	# moldura: filete duplo de tinta e uma faixa de papel embaixo para a escala e a ajuda
	draw_rect(Rect2(Vector2(0, tela.y - 46), Vector2(tela.x, 46)), Color(0.87, 0.8, 0.63, 0.92))
	draw_line(Vector2(0, tela.y - 46), Vector2(tela.x, tela.y - 46), COR_TINTA, 1.5)
	draw_rect(Rect2(Vector2(8, 8), tela - Vector2(16, 16)), COR_TINTA, false, 3.0)
	draw_rect(Rect2(Vector2(14, 14), tela - Vector2(28, 28)), Color(COR_TINTA.r, COR_TINTA.g, COR_TINTA.b, 0.6), false, 1.0)
	# rosa dos ventos, escala e ajuda (discretas, nos cantos)
	var n := Vector2(tela.x - 64, 78)
	draw_arc(n, 22.0, 0.0, TAU, 40, COR_TINTA, 1.5, true)
	draw_colored_polygon(PackedVector2Array([n + Vector2(0, -30), n + Vector2(6, 0), n + Vector2(-6, 0)]), COR_TINTA)
	draw_colored_polygon(PackedVector2Array([n + Vector2(0, 30), n + Vector2(6, 0), n + Vector2(-6, 0)]), Color(0.86, 0.78, 0.6))
	draw_polyline(PackedVector2Array([n + Vector2(0, 30), n + Vector2(6, 0), n + Vector2(-6, 0), n + Vector2(0, 30)]), COR_TINTA, 1.2, true)
	draw_string(_fonte_regiao, n + Vector2(-6, -36), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COR_TINTA)
	var metros := 1000.0 if zoom < 2.5 else (250.0 if zoom < 6.0 else 100.0)
	var b := Vector2(40, tela.y - 20)
	draw_line(b, b + Vector2(metros * esc, 0), COR_TINTA, 3.0)
	draw_line(b + Vector2(0, -5), b + Vector2(0, 5), COR_TINTA, 2.0)
	draw_line(b + Vector2(metros * esc, -5), b + Vector2(metros * esc, 5), COR_TINTA, 2.0)
	var rotulo := ("%d km" % int(metros / 1000.0)) if metros >= 1000.0 else ("%d m" % int(metros))
	draw_string(_fonte_vila, b + Vector2(metros * esc + 10.0, 5.0), rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COR_TINTA)
	var ajuda := "roda do mouse: zoom    arrastar: mover    clique: marcar destino    botão direito: tirar a marca    M: fechar"
	if tem_destino and jog:
		ajuda = "Destino a %d m.    " % int(Vector2(jog.global_position.x, jog.global_position.z).distance_to(destino)) + ajuda
	var larg_ajuda := _fonte_vila.get_string_size(ajuda, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(_fonte_vila, Vector2(tela.x - larg_ajuda - 40.0, tela.y - 16), ajuda, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_TINTA)
