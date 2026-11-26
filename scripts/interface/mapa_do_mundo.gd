class_name MapaDoMundo
extends Control
## Mapa do mundo (tecla M): a ilha inteira na tela, como mapa de jogo (relevo pintado, ícones, letra clara; ver
## PinturaDoMapa). De longe o mapa é limpo: capital, regiões, montanha e os ícones das vilas. Interativo:
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
const ZOOM_NOMES_DE_VILA := 1.7    # de longe só os ícones; os nomes das vilas (e os ícones dos lugares pequenos) aparecem ao aproximar
const ZOOM_NOMES_PEQUENOS := 3.0   # a partir deste zoom aparecem os nomes de fazendas, postos e cabanas
const COR_TEXTO := Color(0.98, 0.95, 0.86)   # letra clara com contorno escuro: lê-se em cima de qualquer cor do mapa

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
		draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 6, Color(0.04, 0.04, 0.06, 0.9))
		draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
		return
	for letra in texto:   # letras espaçadas, como nos nomes de região de mapa antigo
		draw_string_outline(fonte, pos, letra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 6, Color(0.04, 0.04, 0.06, 0.9))
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
	var praia := PackedVector2Array()   # a linha da costa: um filete claro (espuma) com contorno escuro fino
	for p in _costa:
		praia.append(mundo_para_tela(p))
	draw_polyline(praia, Color(0.05, 0.12, 0.18, 0.55), 3.5, true)
	draw_polyline(praia, Color(0.95, 0.97, 0.92, 0.8), 1.4, true)
	for r in mundo.terreno.rios:   # rios: azul vivo com margem escura
		var pts := PackedVector2Array()
		for p in r["pontos"]:
			pts.append(mundo_para_tela(p))
		var larg := clampf(float(r["largura"]) * esc * 1.6, 2.5, 14.0)
		draw_polyline(pts, Color(0.06, 0.2, 0.32, 0.8), larg + 2.0, true)
		draw_polyline(pts, Color(0.38, 0.68, 0.82), larg, true)
	for id in mundo.estradas:      # estradas: faixa clara com borda escura, como nos mapas de jogo
		var pts := PackedVector2Array()
		for p in mundo.estradas[id]:
			pts.append(mundo_para_tela(p))
		var le := clampf(1.3 * zoom, 2.2, 6.0)
		draw_polyline(pts, Color(0.2, 0.13, 0.07, 0.75), le + 2.0, true)
		draw_polyline(pts, Color(0.9, 0.8, 0.56), le, true)
	if zoom >= ZOOM_NOMES_PEQUENOS:   # trilhas até as fazendas e cabanas: tracejadas, só de perto
		for trilha in mundo.trilhas:
			for i in range(0, trilha.size() - 1):
				draw_dashed_line(mundo_para_tela(trilha[i]), mundo_para_tela(trilha[i + 1]), Color(0.92, 0.84, 0.62, 0.8), 1.6, 5.0)
	# o reino de Valdoria: mancha de cidade, muralha (aberta nos portões) e o castelo no meio
	var cidade := PackedVector2Array()
	for k in 60:
		cidade.append(mundo_para_tela(MundoDados.ponto_da_muralha(TAU * k / 60.0)))
	draw_colored_polygon(cidade, Color(0.74, 0.62, 0.5, 0.9))
	for k in 120:
		var m0 := MundoDados.ponto_da_muralha(TAU * (k + 0.5) / 120.0)
		var aberto := false
		for g in mundo.muralha.portoes:
			if m0.distance_to(g) < 16.0:
				aberto = true
		if not aberto:
			draw_line(mundo_para_tela(MundoDados.ponto_da_muralha(TAU * k / 120.0)), mundo_para_tela(MundoDados.ponto_da_muralha(TAU * (k + 1) / 120.0)), Color(0.18, 0.14, 0.12), clampf(1.6 * zoom, 2.5, 6.0), true)
	var rq := mundo_para_tela(Vector2.ZERO)
	_icone(rq, "castelo", clampf(14.0 + 3.0 * zoom, 16.0, 34.0))
	_nome(rq + Vector2(0, -clampf(18.0 + 4.0 * zoom, 22.0, 46.0)), "VALDORIA", 26, _fonte_regiao, COR_TEXTO, 5.0)
	var mq := mundo_para_tela(MundoDados.MONTANHA_CENTRO)   # a Montanha dos Dragões: o relevo já a desenha; aqui só o ícone e o nome
	_icone(mq, "dragao", clampf(12.0 + 2.0 * zoom, 14.0, 26.0))
	_nome(mq + Vector2(0, -clampf(14.0 + 2.0 * zoom, 16.0, 28.0) - 8.0), "MONTANHA DOS DRAGÕES", 15, _fonte_regiao, COR_TEXTO, 2.0)
	for pid in mundo.povoados:
		var pv: Dictionary = mundo.povoados[pid]
		var q := mundo_para_tela(pv["centro"])
		var tipo := String(pv.get("tipo", ""))
		if MundoDados.ate_a_muralha((pv["centro"] as Vector2).x, (pv["centro"] as Vector2).y) < 30.0:
			continue   # praças de dentro da cidade: o castelo já marca Valdoria
		if tipo == "vila":   # vila: ícone de casa sempre; o nome só quando se aproxima (de longe o mapa fica limpo)
			_icone(q, "vila", 9.0 if zoom < ZOOM_NOMES_DE_VILA else 11.0)
			if zoom >= ZOOM_NOMES_DE_VILA:
				_nome(q + Vector2(0, -15), String(pv.get("nome", "")), 14, _fonte_vila, COR_TEXTO)
		elif zoom >= ZOOM_NOMES_DE_VILA:   # lugares pequenos: aparecem ao aproximar, cada tipo com o seu ícone
			_icone(q, {"fazenda": "fazenda", "lavoura": "fazenda", "posto": "tenda", "posto_imperial": "bandeira", "pescador": "peixe", "cabana": "cabana"}.get(tipo, "ponto"), 7.0)
			if zoom >= ZOOM_NOMES_PEQUENOS:
				_nome(q + Vector2(0, -12), String(pv.get("nome", "")), 12, _fonte_vila, Color(0.92, 0.9, 0.82))
	for id in MundoDados.REGIOES:   # as seis regiões: escudo e nome em maiúsculas
		var q := mundo_para_tela(MundoDados.centro(id))
		_icone(q, "escudo", 12.0)
		if id == alvo:   # a missão ativa fica aqui
			draw_arc(q, 20.0 + sin(_t * 4.0) * 2.0, 0.0, TAU, 32, COR_ACENTO, 2.5)
		_nome(q + Vector2(0, -19), String(MundoDados.REGIOES[id]["nome"]).to_upper(), 15, _fonte_regiao, COR_TEXTO, 2.0)
	if tem_destino:   # destino: alfinete vermelho com anel que pulsa
		var q := mundo_para_tela(destino)
		draw_arc(q, 12.0 + sin(_t * 5.0) * 3.0, 0.0, TAU, 28, Color(1.0, 0.3, 0.2, 0.8), 2.0, true)
		draw_colored_polygon(PackedVector2Array([q, q + Vector2(-8, -20), q + Vector2(8, -20)]), Color(0.1, 0.06, 0.05))
		draw_circle(q + Vector2(0, -22), 10.0, Color(0.1, 0.06, 0.05))
		draw_circle(q + Vector2(0, -22), 7.5, Color(0.9, 0.2, 0.14))
		draw_circle(q + Vector2(0, -22), 3.0, Color(1, 1, 1))
	var jog := get_tree().get_first_node_in_group("jogador") as Node3D
	if jog:   # o Torin: seta amarela apontando para onde ele olha, com um anel que pulsa
		var pj := Vector2(jog.global_position.x, jog.global_position.z)
		var q := mundo_para_tela(pj)
		if tem_destino:
			draw_dashed_line(q, mundo_para_tela(destino), Color(1.0, 0.85, 0.3, 0.9), 2.5, 9.0)
		var f := Vector2(-sin(jog.global_rotation.y), -cos(jog.global_rotation.y))
		var lado := Vector2(-f.y, f.x)
		draw_arc(q, 17.0 + sin(_t * 3.0) * 3.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 0.55), 2.0, true)
		draw_colored_polygon(PackedVector2Array([q + f * 15.0, q - f * 8.0 + lado * 9.0, q - f * 3.0, q - f * 8.0 - lado * 9.0]), Color(0.08, 0.06, 0.04))
		draw_colored_polygon(PackedVector2Array([q + f * 11.5, q - f * 5.5 + lado * 6.0, q - f * 2.0, q - f * 5.5 - lado * 6.0]), COR_ACENTO)
	# moldura de jogo: faixas escuras em cima (título) e embaixo (legenda, escala e ajuda)
	draw_rect(Rect2(Vector2.ZERO, Vector2(tela.x, 44)), Color(0.05, 0.05, 0.07, 0.82))
	draw_line(Vector2(0, 44), Vector2(tela.x, 44), COR_ACENTO, 1.5)
	draw_string(_fonte_regiao, Vector2(24, 30), "MAPA DO MUNDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, COR_ACENTO)
	var onde := "Você está em: " + mundo.nome_do_lugar(jog.global_position) if jog else ""
	draw_string(_fonte_vila, Vector2(40.0 + _fonte_regiao.get_string_size("MAPA DO MUNDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x, 29), onde, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COR_TEXTO)
	draw_rect(Rect2(Vector2(0, tela.y - 46), Vector2(tela.x, 46)), Color(0.05, 0.05, 0.07, 0.82))
	draw_line(Vector2(0, tela.y - 46), Vector2(tela.x, tela.y - 46), COR_ACENTO, 1.5)
	var x_leg := 24.0   # legenda dos ícones
	for item in [["castelo", "Capital"], ["escudo", "Região"], ["vila", "Vila"], ["fazenda", "Fazenda"], ["tenda", "Posto"], ["peixe", "Pescador"], ["dragao", "Dragões"]]:
		_icone(Vector2(x_leg + 9.0, tela.y - 23), String(item[0]), 8.0)
		draw_string(_fonte_vila, Vector2(x_leg + 24.0, tela.y - 17), String(item[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_TEXTO)
		x_leg += 34.0 + _fonte_vila.get_string_size(String(item[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	# rosa dos ventos e escala
	var n := Vector2(tela.x - 60, 104)
	draw_circle(n, 30.0, Color(0.05, 0.05, 0.07, 0.6))
	draw_arc(n, 30.0, 0.0, TAU, 40, COR_ACENTO, 1.5, true)
	draw_colored_polygon(PackedVector2Array([n + Vector2(0, -24), n + Vector2(6, 0), n + Vector2(-6, 0)]), Color(0.9, 0.2, 0.14))
	draw_colored_polygon(PackedVector2Array([n + Vector2(0, 24), n + Vector2(6, 0), n + Vector2(-6, 0)]), COR_TEXTO)
	draw_string(_fonte_regiao, n + Vector2(-6, -34), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COR_TEXTO)
	var metros := 1000.0 if zoom < 2.5 else (250.0 if zoom < 6.0 else 100.0)
	var b := Vector2(tela.x - 60.0 - metros * esc, 150.0 + 14.0)
	draw_line(b, b + Vector2(metros * esc, 0), COR_TEXTO, 3.0)
	draw_line(b + Vector2(0, -5), b + Vector2(0, 5), COR_TEXTO, 2.0)
	draw_line(b + Vector2(metros * esc, -5), b + Vector2(metros * esc, 5), COR_TEXTO, 2.0)
	var rotulo := ("%d km" % int(metros / 1000.0)) if metros >= 1000.0 else ("%d m" % int(metros))
	draw_string_outline(_fonte_vila, b + Vector2(0, 20.0), rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 0.7))
	draw_string(_fonte_vila, b + Vector2(0, 20.0), rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_TEXTO)
	var ajuda := "roda: zoom    arrastar: mover    clique: marcar destino    botão direito: tirar a marca    M: fechar"   # na faixa de cima, à direita
	var larg_ajuda := _fonte_vila.get_string_size(ajuda, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(_fonte_vila, Vector2(tela.x - larg_ajuda - 24.0, 28), ajuda, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.76))
	if tem_destino and jog:   # na faixa de baixo, à direita: a distância até o destino marcado
		var falta := "Destino marcado a %d m" % int(Vector2(jog.global_position.x, jog.global_position.z).distance_to(destino))
		draw_string(_fonte_regiao, Vector2(tela.x - _fonte_regiao.get_string_size(falta, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x - 24.0, tela.y - 17), falta, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COR_ACENTO)


## Ícone do mapa: disco escuro com borda dourada e o desenho claro dentro. `r` é o raio do disco.
func _icone(q: Vector2, qual: String, r: float) -> void:
	draw_circle(q, r + 1.5, COR_ACENTO if qual in ["castelo", "dragao"] else Color(0.95, 0.92, 0.82))
	draw_circle(q, r, Color(0.5, 0.1, 0.08) if qual == "castelo" else (Color(0.35, 0.12, 0.4) if qual == "dragao" else Color(0.1, 0.1, 0.13)))
	var c := Color(0.98, 0.95, 0.86)
	var u := r * 0.11   # unidade do desenho
	match qual:
		"castelo":   # três torres com ameias e o portão
			for dx in [-5.0, 0.0, 5.0]:
				var alto := 7.0 if dx == 0.0 else 5.0
				draw_rect(Rect2(q + Vector2((dx - 1.5) * u, -alto * u + 2.0 * u), Vector2(3.0 * u, alto * u + 2.0 * u)), c)
			draw_rect(Rect2(q + Vector2(-5.0 * u, 0.5 * u), Vector2(10.0 * u, 3.5 * u)), c)
			draw_rect(Rect2(q + Vector2(-1.0 * u, 1.6 * u), Vector2(2.0 * u, 2.4 * u)), Color(0.5, 0.1, 0.08))
		"escudo":
			draw_colored_polygon(PackedVector2Array([q + Vector2(-5, -5) * u, q + Vector2(5, -5) * u, q + Vector2(5, 1) * u, q + Vector2(0, 6) * u, q + Vector2(-5, 1) * u]), c)
		"vila", "cabana":   # casa: telhado e parede
			draw_colored_polygon(PackedVector2Array([q + Vector2(-6, -1) * u, q + Vector2(0, -6) * u, q + Vector2(6, -1) * u]), c)
			draw_rect(Rect2(q + Vector2(-4, -1) * u, Vector2(8, 6) * u), c)
		"fazenda":   # três riscos de plantação
			for dx in [-4.0, 0.0, 4.0]:
				draw_line(q + Vector2(dx, 5) * u, q + Vector2(dx, -5) * u, c, maxf(1.5, 1.6 * u))
		"tenda":
			draw_colored_polygon(PackedVector2Array([q + Vector2(-6, 5) * u, q + Vector2(0, -6) * u, q + Vector2(6, 5) * u]), c)
		"bandeira":
			draw_line(q + Vector2(-3, 6) * u, q + Vector2(-3, -6) * u, c, maxf(1.5, 1.4 * u))
			draw_colored_polygon(PackedVector2Array([q + Vector2(-3, -6) * u, q + Vector2(6, -3) * u, q + Vector2(-3, 0) * u]), c)
		"peixe":
			draw_colored_polygon(PackedVector2Array([q + Vector2(-6, 0) * u, q + Vector2(-1, -4) * u, q + Vector2(3, 0) * u, q + Vector2(-1, 4) * u]), c)
			draw_colored_polygon(PackedVector2Array([q + Vector2(2, 0) * u, q + Vector2(7, -4) * u, q + Vector2(7, 4) * u]), c)
		"dragao":   # asas abertas em V e a cabeça
			draw_colored_polygon(PackedVector2Array([q + Vector2(0, 3) * u, q + Vector2(-8, -5) * u, q + Vector2(-3, -1) * u, q + Vector2(0, -6) * u, q + Vector2(3, -1) * u, q + Vector2(8, -5) * u]), c)
		_:
			draw_circle(q, r * 0.35, c)
