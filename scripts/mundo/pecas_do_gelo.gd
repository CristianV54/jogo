class_name PecasDoGelo
extends PecasDeConstrucao
## Peças das Terras do Gelo: a placa do Lago Congelado e os cristais de gelo. Bancada: tools/bancada_construcao.gd -- gelo.

const GELO := Color(0.7, 0.88, 0.98)
const GELO_CLARO := Color(0.86, 0.94, 1.0)
const RACHADURA := Color(0.3, 0.45, 0.6)


## A placa de gelo do lago: disco em que se anda, um anel claro de neve na beira e rachaduras riscadas no gelo.
func lago(p: Vector3, raio: float) -> void:
	_peca("cilindro", GELO, Transform3D(Basis.from_scale(Vector3(raio * 2.0, 0.5, raio * 2.0)), p + Vector3(0, 0.05, 0)))
	_peca("cilindro", GELO_CLARO, Transform3D(Basis.from_scale(Vector3(raio * 2.0 + 5.0, 0.3, raio * 2.0 + 5.0)), p + Vector3(0, 0.0, 0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 27
	for k in 26:   # rachaduras: riscos finos e escuros, em feixes que saem de alguns pontos
		var a := rng.randf() * TAU
		var d := rng.randf() * raio * 0.75
		var comp := rng.randf_range(6.0, 22.0)
		_caixa(p + Vector3(cos(a) * d, 0.31, sin(a) * d), Vector3(0.12, 0.02, comp), rng.randf() * TAU, RACHADURA, false)
	var corpo := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = 0.5
	corpo.shape = forma
	corpo.position = p + Vector3(0, 0.05, 0)
	_corpo.add_child(corpo)


## Cristal de gelo: de três a cinco pontas inclinadas saindo do mesmo pé, a maior no meio.
func cristal(p: Vector3, tamanho: float, semente: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var pontas := rng.randi_range(3, 5)
	for k in pontas:
		var a := TAU * k / pontas + rng.randf() * 0.6
		var alto := tamanho * (1.6 if k == 0 else rng.randf_range(0.6, 1.1))
		var tomba := 0.0 if k == 0 else rng.randf_range(0.25, 0.6)
		var base := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, tomba)
		var meio := p + base * Vector3(0, alto * 0.5 - 0.15, 0) + Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else tamanho * 0.25)
		_peca("piramide", GELO if k % 2 == 0 else GELO_CLARO, Transform3D(base.scaled_local(Vector3(tamanho * 0.5, alto, tamanho * 0.5)), meio))
	if tamanho > 1.6:
		_solido(p + Vector3(0, tamanho * 0.5, 0), Vector3(tamanho * 0.7, tamanho, tamanho * 0.7), 0.0)
