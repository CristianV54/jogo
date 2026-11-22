class_name Humanoide
extends Node3D
## Qualquer personagem humano montado com o esqueleto de 65 ossos (Universal Base Characters + trajes).
## Liga o modelo à biblioteca de animações compartilhada (Universal Animation Library, CC0).
## O nó filho "Modelo" é o .glb; as animações têm o caminho "Armature/Skeleton3D:osso", relativo à raiz do modelo.

const BIBLIOTECA: AnimationLibrary = preload("res://assets/animations/ual/ual1_biblioteca.res")

## Cor que multiplica a textura de cabelo e sobrancelha (a textura do pacote é cinza-clara).
@export var cor_cabelo := Color(1, 1, 1)
## Escala do corpo todo (1,0 = 1,82 m, a altura da base). Usada para diferenciar personagens.
@export var escala_corpo := 1.0
## Cabeça maior em relação ao corpo (crianças: 1,3). Mexe só no osso da cabeça.
@export var cabeca_grande := 1.0
## Cor que multiplica as peças de traje (não a pele): serve para diferenciar chefes e soldados.
@export var tom_traje := Color(1, 1, 1)
## Arma na mão direita (opcional). O giro e o deslocamento foram calibrados por captura.
@export var arma_cena: PackedScene
@export var arma_escala := 0.25
@export var arma_giro := Vector3.ZERO
@export var arma_deslocamento := Vector3.ZERO     # onde o punho fecha, no espaço do osso hand_r
@export var arma_empunhadura := Vector3.ZERO      # ponto do cabo na arma (sem escala): é ele que vai para o punho
## Animação em loop que toca ao entrar na cena.
@export var animacao_inicial := "Idle"

## Ao correr a espada vai para as costas (na mão, o braço balançando a levava para a cabeça).
@export var costas_giro := Vector3(90.0, 0.0, 40.0)
@export var costas_deslocamento := Vector3(0.0, -0.08, -0.22)

@onready var modelo: Node3D = $Modelo
var animacoes: AnimationPlayer
var _arma_mao: Node3D
var _arma_costas: Node3D
var _correndo_antes := false


func _ready() -> void:
	modelo.scale = Vector3.ONE * escala_corpo
	_tingir_cabelo()
	_tingir_traje()
	if cabeca_grande != 1.0:
		var esq0: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
		var osso := esq0.find_bone("head") if esq0 else -1
		if osso >= 0:
			esq0.set_bone_pose_scale(osso, Vector3.ONE * cabeca_grande)
	if arma_cena:
		_arma_mao = equipar_arma(arma_cena, arma_escala, arma_giro, arma_deslocamento, arma_empunhadura)
		_guardar_nas_costas()
	animacoes = AnimationPlayer.new()
	animacoes.name = "Animacoes"
	add_child(animacoes)
	animacoes.root_node = animacoes.get_path_to(modelo)
	animacoes.add_animation_library("", BIBLIOTECA)
	tocar(animacao_inicial)


func _guardar_nas_costas() -> void:
	var esq: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
	if esq == null or esq.find_bone("spine_03") < 0:
		return
	var anexo := BoneAttachment3D.new()
	anexo.name = "ArmaNasCostas"
	anexo.bone_name = "spine_03"
	esq.add_child(anexo)
	_arma_costas = arma_cena.instantiate()
	_arma_costas.scale = Vector3.ONE * arma_escala
	_arma_costas.rotation_degrees = costas_giro
	_arma_costas.position = costas_deslocamento
	_arma_costas.visible = false
	anexo.add_child(_arma_costas)


func _process(_delta: float) -> void:
	if _arma_mao == null or _arma_costas == null or animacoes == null:
		return
	var a := animacoes.current_animation
	var correndo := a == "Sprint" or a == "Jog_Fwd" or a == "Jog_Bwd" or a == "Jog_Left" or a == "Jog_Right"
	if correndo != _correndo_antes:
		_correndo_antes = correndo
		_arma_mao.visible = not correndo
		_arma_costas.visible = correndo


func tocar(nome: String, mistura := 0.2) -> void:
	if not animacoes.has_animation(nome):
		push_warning("Humanoide: animação inexistente: " + nome)
		return
	if animacoes.current_animation != nome:
		animacoes.play(nome, mistura)


func tem(nome: String) -> bool:
	return animacoes.has_animation(nome)


func _tingir_cabelo() -> void:
	if cor_cabelo == Color(1, 1, 1):
		return
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("Hair") or String(mi.name).begins_with("Eyebrows"):
			for i in mi.mesh.get_surface_count():
				var mat: Material = mi.get_active_material(i)
				if mat is BaseMaterial3D:
					var copia: BaseMaterial3D = mat.duplicate()
					copia.albedo_color = cor_cabelo
					mi.set_surface_override_material(i, copia)


func _tingir_traje() -> void:
	if tom_traje == Color(1, 1, 1):
		return
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var nome_malha := String(mi.name)
		if nome_malha.begins_with("Male_") or nome_malha.begins_with("Female_"):
			for i in mi.mesh.get_surface_count():
				var mat: Material = mi.get_active_material(i)
				if mat is BaseMaterial3D and not mat.resource_name.begins_with("MI_Regular"):   # a pele (MI_Regular_*) não é tingida
					var copia: BaseMaterial3D = mat.duplicate()
					copia.albedo_color = tom_traje
					mi.set_surface_override_material(i, copia)


## Coloca uma arma na mão direita (osso hand_r). O ponto `empunhadura` do cabo (nas medidas da arma, sem escala) vai
## para `deslocamento` (onde o punho fecha, no espaço do osso). `giro_graus` é a rotação da arma em relação ao osso.
func equipar_arma(arma: PackedScene, escala_arma: float, giro_graus: Vector3, deslocamento: Vector3, empunhadura := Vector3.ZERO) -> Node3D:
	var esq: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
	var anexo := BoneAttachment3D.new()
	anexo.name = "ArmaMaoDireita"
	anexo.bone_name = "hand_r"
	esq.add_child(anexo)
	var inst: Node3D = arma.instantiate()
	inst.scale = Vector3.ONE * escala_arma
	inst.rotation_degrees = giro_graus
	anexo.add_child(inst)
	inst.position = deslocamento - inst.transform.basis * empunhadura
	return inst
