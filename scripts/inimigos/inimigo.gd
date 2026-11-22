class_name Inimigo
extends CharacterBody3D
## Inimigo genérico, serve de criatura comum e de chefe: espera, persegue, ataca, reage ao dano e morre.
## Na metade da vida (ou no valor de `enfurece_em`) fica mais rápido e mais forte.
## O visual é um Humanoide (animações da biblioteca) ou uma Criatura (animações do próprio modelo);
## os dois têm `tocar(nome, mistura)` e `tem(nome)`. Se faltar a animação de dano ou morte, não toca nada em vez de travar.

signal vida_mudou(atual: int, maximo: int)
signal morreu(inimigo: Inimigo)

enum Estado { PARADO, PERSEGUINDO, ATACANDO, DANO, MORTO }

@export var nome := "Inimigo"
@export var vida_max := 60
@export var dano := 8
@export var velocidade := 3.2
@export var alcance_visao := 16.0
@export var alcance_ataque := 1.9
@export var intervalo_ataque := 1.6
@export var momento_do_ataque := 0.45
@export var enfurece_em := 0.0          # fração da vida; 0 = nunca
@export var cena_visual: PackedScene
@export var escala_visual := 1.0
@export var projetil := false         # arqueiro: desenha uma flecha até o alvo ao atacar
@export var acessorio := ""        # ver Acessorios
@export var especie := ""           # chave de VariacaoDeCores
@export var drops := {}               # {item: [mínimo, máximo]} largados ao morrer (só inimigos comuns)
@export var raio_colisao := 0.5
@export var altura_colisao := 1.8
@export var chefe := false
@export var anim_parado := "Idle"
@export var anim_andar := "Walk"
@export var anim_correr := "Jog_Fwd"
@export var anim_atacar := "Punch_Jab"
@export var anim_dano := "Hit_Chest"
@export var anim_morte := "Death01"

var vida := 0
var estado := Estado.PARADO
var alvo: Jogador
var visual: Node3D
var enfurecido := false
var _tempo := 0.0
var _atacou := false


func _ready() -> void:
	vida = vida_max
	add_to_group("inimigos")
	visual = cena_visual.instantiate()
	visual.rotation_degrees.y = 180.0
	visual.scale = Vector3.ONE * escala_visual
	add_child(visual)
	VariacaoDeCores.aplicar(visual, especie)
	Acessorios.aplicar(visual, acessorio)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = raio_colisao
	cap.height = maxf(altura_colisao, raio_colisao * 2.0 + 0.1)
	cs.shape = cap
	cs.position.y = altura_colisao / 2.0
	add_child(cs)
	_tocar(anim_parado)


func _tocar(nome_anim: String, mistura := 0.2) -> void:
	if visual and visual.has_method("tem") and visual.tem(nome_anim):
		visual.tocar(nome_anim, mistura)


func _physics_process(delta: float) -> void:
	if estado == Estado.MORTO:
		return
	if alvo == null:
		var js := get_tree().get_nodes_in_group("jogador")
		if js.size() > 0:
			alvo = js[0] as Jogador
		return
	_tempo += delta
	var ate := alvo.global_position - global_position
	ate.y = 0.0
	var dist := ate.length()
	if alvo.morto and estado != Estado.PARADO:
		estado = Estado.PARADO
		_tocar(anim_parado)

	match estado:
		Estado.PARADO:
			velocity.x = 0.0
			velocity.z = 0.0
			if dist < alcance_visao and not alvo.morto:
				estado = Estado.PERSEGUINDO
		Estado.PERSEGUINDO:
			if dist <= alcance_ataque:
				estado = Estado.ATACANDO
				_tempo = 0.0
				_atacou = false
				velocity.x = 0.0
				velocity.z = 0.0
				_tocar(anim_atacar, 0.1)
			else:
				var dir := ate.normalized()
				velocity.x = dir.x * velocidade
				velocity.z = dir.z * velocidade
				rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 8.0 * delta)
				_tocar(anim_correr if dist > 10.0 and anim_correr != "" else anim_andar)
		Estado.ATACANDO:
			velocity.x = 0.0
			velocity.z = 0.0
			if dist > 0.1:
				rotation.y = lerp_angle(rotation.y, atan2(-ate.x, -ate.z), 6.0 * delta)
			if not _atacou and _tempo >= momento_do_ataque:
				_atacou = true
				if dist <= alcance_ataque * 1.35:
					if projetil:
						Efeitos.flecha(self, alvo)
					alvo.receber_dano(dano, self)
			if _tempo >= intervalo_ataque:
				estado = Estado.PERSEGUINDO
		Estado.DANO:
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
			if _tempo >= 0.4:
				estado = Estado.PERSEGUINDO
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()


func receber_dano(quantidade: int, de: Node3D = null) -> void:
	if estado == Estado.MORTO:
		return
	vida = maxi(0, vida - quantidade)
	vida_mudou.emit(vida, vida_max)
	if enfurece_em > 0.0 and not enfurecido and float(vida) / vida_max <= enfurece_em:
		enfurecido = true
		velocidade *= 1.35
		dano = int(dano * 1.35)
		intervalo_ataque *= 0.75
	if vida <= 0:
		_morrer()
		return
	if not chefe:   # chefe não é interrompido pelos golpes comuns
		estado = Estado.DANO
		_tempo = 0.0
		_tocar(anim_dano, 0.05)
		if de:
			var empurrao := global_position - de.global_position
			empurrao.y = 0.0
			velocity = empurrao.normalized() * 4.0


func _morrer() -> void:
	estado = Estado.MORTO
	velocity = Vector3.ZERO
	collision_layer = 0
	remove_from_group("inimigos")
	var tem_morte: bool = visual.has_method("tem") and visual.tem(anim_morte)
	if tem_morte:
		_tocar(anim_morte, 0.05)
	else:   # sem animação de morte (dragões): tomba de lado e afunda
		var tw := create_tween()
		tw.tween_property(visual, "rotation_degrees:z", 80.0, 0.9)
		tw.parallel().tween_property(visual, "position:y", -0.6 * escala_visual, 1.6)
	morreu.emit(self)
	if especie != "":
		GerenciadorMissoes.evento("derrotar", especie)
	if not chefe:
		Pickup.largar(get_parent(), global_position, drops)
		get_tree().create_timer(4.0).timeout.connect(func() -> void: Efeitos.desintegrar(self, visual))
