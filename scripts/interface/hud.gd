class_name Hud
extends CanvasLayer
## Interface do jogo, desenhada por código: vida do jogador, vida do chefe, nome da área, dica de interação,
## caixa de diálogo e mensagens centrais. Sem fonte nem arte final: é uma interface funcional, para trocar depois.

const COR_FUNDO := Color(0.05, 0.05, 0.06, 0.78)
const COR_VIDA := Color(0.78, 0.22, 0.12)
const COR_CHEFE := Color(0.85, 0.62, 0.15)

var _raiz: Control
var _vida_fundo: ColorRect
var _vida_barra: ColorRect
var _vida_texto: Label
var _chefe_caixa: Control
var _chefe_barra: ColorRect
var _chefe_nome: Label
var _area_label: Label
var _dica_label: Label
var _dialogo_caixa: ColorRect
var _dialogo_nome: Label
var _dialogo_texto: Label
var _mensagem: Label
var _tween_area: Tween

var dialogo_aberto := false


func _ready() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)

	_vida_fundo = _retangulo(Vector2(24, 24), Vector2(260, 22), COR_FUNDO)
	_vida_barra = _retangulo(Vector2(26, 26), Vector2(256, 18), COR_VIDA)
	_vida_texto = _rotulo("Torin", Vector2(30, 48), 18)

	_chefe_caixa = Control.new()
	_chefe_caixa.visible = false
	_raiz.add_child(_chefe_caixa)
	var fundo_chefe := ColorRect.new()
	fundo_chefe.color = COR_FUNDO
	fundo_chefe.position = Vector2(340, 28)
	fundo_chefe.size = Vector2(600, 20)
	_chefe_caixa.add_child(fundo_chefe)
	_chefe_barra = ColorRect.new()
	_chefe_barra.color = COR_CHEFE
	_chefe_barra.position = Vector2(342, 30)
	_chefe_barra.size = Vector2(596, 16)
	_chefe_caixa.add_child(_chefe_barra)
	_chefe_nome = Label.new()
	_chefe_nome.position = Vector2(340, 50)
	_chefe_nome.add_theme_font_size_override("font_size", 20)
	_chefe_caixa.add_child(_chefe_nome)

	_area_label = _rotulo("", Vector2(0, 90), 34)
	_area_label.size = Vector2(1280, 50)
	_area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_label.modulate.a = 0.0

	_dica_label = _rotulo("", Vector2(0, 600), 22)
	_dica_label.size = Vector2(1280, 40)
	_dica_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_dialogo_caixa = _retangulo(Vector2(240, 500), Vector2(800, 150), COR_FUNDO)
	_dialogo_caixa.visible = false
	_dialogo_nome = Label.new()
	_dialogo_nome.position = Vector2(18, 10)
	_dialogo_nome.add_theme_font_size_override("font_size", 24)
	_dialogo_nome.add_theme_color_override("font_color", COR_CHEFE)
	_dialogo_caixa.add_child(_dialogo_nome)
	_dialogo_texto = Label.new()
	_dialogo_texto.position = Vector2(18, 48)
	_dialogo_texto.size = Vector2(764, 90)
	_dialogo_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogo_texto.add_theme_font_size_override("font_size", 22)
	_dialogo_caixa.add_child(_dialogo_texto)

	var legenda := _rotulo("WASD andar    Shift correr    Espaço pular    J golpe    K rolar    E falar    F Fagulha voar    Esc solta o mouse", Vector2(24, 690), 15)
	legenda.modulate.a = 0.85

	_mensagem = _rotulo("", Vector2(80, 260), 40)
	_mensagem.size = Vector2(1120, 160)
	_mensagem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensagem.visible = false


func _retangulo(pos: Vector2, tam: Vector2, cor: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = tam
	r.color = cor
	_raiz.add_child(r)
	return r


func _rotulo(texto: String, pos: Vector2, tamanho_fonte: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.add_theme_font_size_override("font_size", tamanho_fonte)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 6)
	_raiz.add_child(l)
	return l


func definir_vida(atual: int, maximo: int) -> void:
	_vida_barra.size.x = 256.0 * clampf(float(atual) / float(maximo), 0.0, 1.0)
	_vida_texto.text = "Torin  %d / %d" % [atual, maximo]


func mostrar_chefe(nome: String, atual: int, maximo: int) -> void:
	_chefe_caixa.visible = true
	_chefe_nome.text = nome
	_chefe_barra.size.x = 596.0 * clampf(float(atual) / float(maximo), 0.0, 1.0)


func esconder_chefe() -> void:
	_chefe_caixa.visible = false


func mostrar_area(nome: String) -> void:
	_area_label.text = nome
	if _tween_area:
		_tween_area.kill()
	_area_label.modulate.a = 1.0
	_tween_area = create_tween()
	_tween_area.tween_interval(2.2)
	_tween_area.tween_property(_area_label, "modulate:a", 0.0, 1.2)


func dica(texto: String) -> void:
	_dica_label.text = texto


func dialogo(nome: String, texto: String) -> void:
	dialogo_aberto = true
	_dialogo_caixa.visible = true
	_dialogo_nome.text = nome
	_dialogo_texto.text = texto


func fechar_dialogo() -> void:
	dialogo_aberto = false
	_dialogo_caixa.visible = false


func mensagem(texto: String, segundos := 3.0) -> void:
	_mensagem.text = texto
	_mensagem.visible = true
	if segundos > 0.0:
		get_tree().create_timer(segundos).timeout.connect(func() -> void: _mensagem.visible = false)
