class_name PainelInventario
extends Control
## Janela do inventário: grade de espaços com o ícone (render do modelo 3D) e a quantidade de cada item, e, à direita,
## nome, descrição e o botão Usar do item selecionado. Quem decide o que "usar" faz é o jogo (sinal `usar_pedido`).

signal usar_pedido(item: String)
signal fechar_pedido

const COLUNAS := 6
const LINHAS := 5
const TAM_SLOT := 72
const COR_FUNDO := Color(0.07, 0.065, 0.06, 0.94)
const COR_SLOT := Color(0.16, 0.15, 0.14, 1.0)
const COR_SELECIONADO := Color(0.85, 0.62, 0.15, 1.0)

var _inventario := {}
var _selecionado := ""
var _slots: Array[Button] = []
var _icones := {}           # id do item -> Texture2D
var _id_do_slot: Array[String] = []
var _nome: Label
var _descricao: Label
var _quantidade: Label
var _usar: Button
var _aviso: Label
var _id_aviso := 0


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.position = Vector2(270, 100)
	fundo.size = Vector2(740, 516)
	add_child(fundo)
	var titulo := Label.new()
	titulo.text = "Inventário"
	titulo.position = Vector2(300, 112)
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", COR_SELECIONADO)
	add_child(titulo)
	var dica := Label.new()
	dica.text = "I ou Esc fecha"
	dica.position = Vector2(810, 124)
	dica.add_theme_font_size_override("font_size", 16)
	dica.modulate.a = 0.7
	add_child(dica)
	var grade := GridContainer.new()
	grade.columns = COLUNAS
	grade.position = Vector2(300, 170)
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	add_child(grade)
	for i in COLUNAS * LINHAS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(TAM_SLOT, TAM_SLOT)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", _estilo(COR_SLOT, false))
		b.add_theme_stylebox_override("hover", _estilo(COR_SLOT.lightened(0.15), false))
		b.add_theme_stylebox_override("pressed", _estilo(COR_SLOT, true))
		var icone := TextureRect.new()
		icone.name = "Icone"
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.position = Vector2(6, 6)
		icone.size = Vector2(TAM_SLOT - 12, TAM_SLOT - 12)
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icone)
		var qtd := Label.new()
		qtd.name = "Qtd"
		qtd.position = Vector2(TAM_SLOT - 34, TAM_SLOT - 26)
		qtd.size = Vector2(30, 22)
		qtd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qtd.add_theme_font_size_override("font_size", 18)
		qtd.add_theme_color_override("font_outline_color", Color.BLACK)
		qtd.add_theme_constant_override("outline_size", 5)
		qtd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(qtd)
		b.pressed.connect(_ao_clicar_slot.bind(i))
		grade.add_child(b)
		_slots.append(b)
		_id_do_slot.append("")
	_nome = _rotulo(Vector2(780, 170), 26, COR_SELECIONADO)
	_quantidade = _rotulo(Vector2(780, 208), 18, Color(0.8, 0.8, 0.8))
	_descricao = _rotulo(Vector2(780, 246), 19, Color.WHITE)
	_descricao.size = Vector2(210, 180)
	_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_usar = Button.new()
	_usar.text = "Usar (Enter)"
	_usar.position = Vector2(780, 436)
	_usar.size = Vector2(190, 44)
	_usar.focus_mode = Control.FOCUS_NONE
	_usar.add_theme_font_size_override("font_size", 20)
	_usar.add_theme_stylebox_override("normal", _estilo(Color(0.55, 0.38, 0.08), true))
	_usar.add_theme_stylebox_override("hover", _estilo(Color(0.7, 0.5, 0.12), true))
	_usar.add_theme_stylebox_override("pressed", _estilo(Color(0.4, 0.27, 0.05), true))
	_usar.add_theme_stylebox_override("disabled", _estilo(Color(0.2, 0.19, 0.18), false))
	_usar.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	_usar.pressed.connect(_ao_usar)
	add_child(_usar)
	_aviso = _rotulo(Vector2(780, 500), 19, COR_SELECIONADO)
	_aviso.size = Vector2(220, 60)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_criar_icones()
	_atualizar()


func _estilo(cor: Color, destaque: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.set_border_width_all(3 if destaque else 1)
	s.border_color = COR_SELECIONADO if destaque else Color(0.3, 0.28, 0.25)
	s.set_corner_radius_all(4)
	return s


func _rotulo(pos: Vector2, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	add_child(l)
	return l


## Um SubViewport por item renderiza o modelo 3D uma vez; a textura vira o ícone do espaço.
func _criar_icones() -> void:
	for id in Itens.ORDEM:
		var vp := SubViewport.new()
		vp.size = Vector2i(128, 128)
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(vp)
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.85, 0.85, 0.88)
		var cam := Camera3D.new()
		cam.environment = env
		cam.fov = 30.0
		vp.add_child(cam)
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
		vp.add_child(luz)
		var modelo: Node3D = (load(Itens.DADOS[id]["modelo"]) as PackedScene).instantiate()
		modelo.rotation_degrees.y = -35.0
		vp.add_child(modelo)
		var caixa := AABB()   # enquadra o modelo, seja do tamanho que for (uma maçã, uma espada, um peitoral)
		var primeira := true
		for mi in modelo.find_children("*", "MeshInstance3D", true, false):
			var c := (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb() if (mi as MeshInstance3D).is_inside_tree() else (mi as MeshInstance3D).transform * (mi as MeshInstance3D).get_aabb()
			caixa = c if primeira else caixa.merge(c)
			primeira = false
		var meio := modelo.transform * caixa.get_center() if not modelo.is_inside_tree() else caixa.get_center()
		var raio := maxf(0.05, caixa.size.length() * 0.5)
		cam.look_at_from_position(meio + Vector3(0.1, 0.35, 1.0).normalized() * raio * 3.6, meio)
		_icones[id] = vp.get_texture()


## Aviso curto no rodapé do painel (usar o item, vida cheia...), no lugar da mensagem central que cobriria a grade.
func aviso(texto: String, segundos := 2.0) -> void:
	_id_aviso += 1
	var meu := _id_aviso
	_aviso.text = texto
	get_tree().create_timer(segundos).timeout.connect(func() -> void:
		if meu == _id_aviso:
			_aviso.text = "")


func definir(inventario: Dictionary) -> void:
	_inventario = inventario
	if _selecionado == "" or not _inventario.has(_selecionado):
		_selecionado = ""
		for id in Itens.ORDEM:
			if int(_inventario.get(id, 0)) > 0:
				_selecionado = id
				break
	if is_inside_tree():
		_atualizar()


func _atualizar() -> void:
	var i := 0
	for id in Itens.ORDEM:
		var qtd := int(_inventario.get(id, 0))
		if qtd <= 0:
			continue
		_preencher(i, id, qtd)
		i += 1
	for j in range(i, _slots.size()):
		_preencher(j, "", 0)
	_detalhe()


func _preencher(i: int, id: String, qtd: int) -> void:
	var b := _slots[i]
	_id_do_slot[i] = id
	(b.get_node("Icone") as TextureRect).texture = _icones.get(id) if id != "" else null
	(b.get_node("Qtd") as Label).text = "x%d" % qtd if id != "" else ""
	b.add_theme_stylebox_override("normal", _estilo(COR_SLOT, id != "" and id == _selecionado))


func _detalhe() -> void:
	if _selecionado == "":
		_nome.text = "Vazio"
		_quantidade.text = "Mate animais para conseguir itens."
		_descricao.text = ""
		_usar.disabled = true
		return
	var dados: Dictionary = Itens.DADOS[_selecionado]
	_nome.text = dados["nome"]
	_quantidade.text = "Quantidade: %d" % int(_inventario.get(_selecionado, 0))
	_descricao.text = dados["descricao"]
	var comida := int(dados.get("cura", 0)) > 0 or float(dados.get("fome", 0)) > 0.0
	var equipavel := dados.has("dano") or dados.has("defesa")
	_usar.disabled = not (comida or equipavel)
	_usar.text = "Equipar (Enter)" if equipavel else ("Comer (Enter)" if comida else "Usar (Enter)")


func _ao_clicar_slot(i: int) -> void:
	if _id_do_slot[i] == "":
		return
	_selecionado = _id_do_slot[i]
	_atualizar()


func _ao_usar() -> void:
	if _selecionado != "":
		usar_pedido.emit(_selecionado)


func _unhandled_key_input(evento: InputEvent) -> void:
	if not visible or not (evento is InputEventKey) or not evento.pressed or evento.echo:
		return
	if evento.physical_keycode == KEY_ENTER or evento.physical_keycode == KEY_KP_ENTER:
		_ao_usar()
		get_viewport().set_input_as_handled()
	elif evento.physical_keycode == KEY_ESCAPE:
		fechar_pedido.emit()
		get_viewport().set_input_as_handled()
