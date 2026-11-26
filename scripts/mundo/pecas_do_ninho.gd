class_name PecasDoNinho
extends PecasDeConstrucao
## Peças da Montanha dos Dragões: o ninho do topo (roda de pedras em pé, ossada, ovos, brasa), os marcos de pedra da
## trilha e o arco de ossos que marca o começo e o fim dela. Bancada: tools/bancada_construcao.gd -- ninho.

const ROCHA := Color(0.32, 0.3, 0.29)
const ROCHA_CLARA := Color(0.46, 0.43, 0.4)
const OSSO := Color(0.86, 0.82, 0.72)
const BRASA := Color(1.0, 0.5, 0.15)


func _eh_pedra(cor: Color) -> bool:
	return cor.is_equal_approx(ROCHA) or cor.is_equal_approx(ROCHA_CLARA)


## Peça inclinada: caixa (ou outra malha) com giro em Y e depois tombada em X e em Z.
func _torta(pos: Vector3, tam: Vector3, giro: float, tomba_x: float, tomba_z: float, cor: Color, malha := "caixa", luz := false) -> void:
	_peca(malha, cor, Transform3D((Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, tomba_x) * Basis(Vector3.BACK, tomba_z)).scaled_local(tam), pos), luz)


## O ninho: doze pedras em pé em roda, um leito de galhos, cinco ovos, a brasa no meio e a ossada de uma presa grande.
func ninho(p: Vector3) -> void:
	for k in 12:
		var a := TAU * k / 12.0
		var alt := 5.0 + 3.0 * absf(sin(k * 2.3))
		var q := p + Vector3(cos(a) * 30.0, 0, sin(a) * 30.0)
		_torta(q + Vector3(0, alt / 2.0 - 0.6, 0), Vector3(2.6, alt, 2.0), -a, 0.12 * sin(k * 1.7), 0.1 * cos(k * 2.9), ROCHA if k % 2 == 0 else ROCHA_CLARA)
		_torta(q + Vector3(0, alt - 0.3, 0), Vector3(1.6, 1.8, 1.4), -a + 0.4, 0.2, 0.15, ROCHA_CLARA, "piramide")
		_solido(q + Vector3(0, alt / 2.0, 0), Vector3(2.4, alt, 1.9), -a)
	for k in 26:   # leito de galhos queimados em roda da brasa
		var a := TAU * k / 26.0 + 0.1 * sin(k * 5.1)
		var r := 4.6 + 0.8 * sin(k * 3.7)
		_torta(p + Vector3(cos(a) * r, 0.35 + 0.2 * (k % 3), sin(a) * r), Vector3(0.22, 0.22, 3.4), -a + PI / 2.0 + 0.5, 0.1 * (k % 4), 0.0, Color(0.2, 0.15, 0.12))
	_cilindro(p + Vector3(0, 0.12, 0), 3.4, 0.24, Color(0.12, 0.1, 0.1))
	_peca("cilindro", BRASA, Transform3D(Basis.from_scale(Vector3(4.4, 0.1, 4.4)), p + Vector3(0, 0.27, 0)), true)
	for k in 5:   # ovos de dragão, cada um de uma cor, meio enterrados na cinza quente
		var a := TAU * k / 5.0 + 0.4
		var cor_ovo: Color = [Color(0.75, 0.3, 0.25), Color(0.3, 0.45, 0.7), Color(0.35, 0.6, 0.4), Color(0.8, 0.65, 0.3), Color(0.5, 0.4, 0.65)][k]
		var e := p + Vector3(cos(a) * 1.4, 0.55, sin(a) * 1.4)
		_torta(e, Vector3(0.75, 1.1, 0.75), a, 0.2, 0.1, cor_ovo, "cilindro")
		_torta(e + Vector3(0, 0.5, 0), Vector3(0.62, 0.5, 0.62), a, 0.2, 0.1, cor_ovo.lightened(0.15), "cilindro")
		_torta(e + Vector3(0, 0.1, 0), Vector3(0.8, 0.12, 0.8), a, 0.2, 0.1, cor_ovo.darkened(0.3), "cilindro")
	var o := p + Vector3(-13.0, 0.0, -9.0)   # ossada: espinha, costelas em arco e o crânio
	_torta(o + Vector3(0, 0.5, 0), Vector3(0.4, 0.4, 9.0), 0.6, 0.0, 0.0, OSSO)
	for k in 7:
		var z := -3.4 + k * 1.0
		var base := o + Basis(Vector3.UP, 0.6) * Vector3(0, 0, z)
		for sx in [-1.0, 1.0]:
			_torta(base + Basis(Vector3.UP, 0.6) * Vector3(sx * 0.9, 1.3, 0), Vector3(0.2, 2.6, 0.2), 0.6, 0.0, -sx * 0.55, OSSO)
	_torta(o + Basis(Vector3.UP, 0.6) * Vector3(0, 0.8, 5.4), Vector3(1.5, 1.2, 2.2), 0.6, -0.15, 0.0, OSSO)
	for sx in [-1.0, 1.0]:
		_torta(o + Basis(Vector3.UP, 0.6) * Vector3(sx * 0.6, 1.7, 4.9), Vector3(0.22, 1.3, 0.22), 0.6, -0.6, sx * 0.3, OSSO, "piramide")
	_solido(o + Vector3(0, 0.8, 0), Vector3(2.0, 1.6, 9.0), 0.6)


## Marco da trilha: uma pedra em pé com um risco de garra pintado; a cada quatro, uma tocha acesa em cima.
func marco(p: Vector3, indice: int) -> void:
	var giro := indice * 1.9
	_torta(p + Vector3(0, 0.9, 0), Vector3(1.1, 2.4, 0.9), giro, 0.08, 0.06 * (indice % 3 - 1), ROCHA if indice % 2 == 0 else ROCHA_CLARA)
	for k in 3:
		_torta(p + Basis(Vector3.UP, giro) * Vector3(-0.2 + k * 0.2, 1.3, 0.47), Vector3(0.06, 0.8, 0.03), giro, 0.0, 0.25, Color(0.7, 0.2, 0.15))
	if indice % 4 == 0:
		_cilindro(p + Vector3(0, 2.5, 0), 0.07, 1.0, Color(0.25, 0.17, 0.1))
		_caixa(p + Vector3(0, 3.1, 0), Vector3(0.3, 0.4, 0.3), giro, BRASA, false, true)
	_solido(p + Vector3(0, 1.0, 0), Vector3(1.1, 2.0, 0.9), giro)


## Arco de ossos atravessado na trilha: duas costelas gigantes que se cruzam no alto e um crânio pendurado.
func arco_de_ossos(p: Vector3, ao_longo: Vector2) -> void:
	var giro := atan2(ao_longo.x, ao_longo.y)
	var b := Basis(Vector3.UP, giro)
	for sx in [-1.0, 1.0]:
		_torta(p + b * Vector3(sx * 3.6, 3.2, 0), Vector3(0.5, 7.4, 0.5), giro, 0.0, sx * 0.42, OSSO)
		_torta(p + b * Vector3(sx * 5.2, 0.4, 0), Vector3(1.6, 1.0, 1.4), giro, 0.0, 0.0, ROCHA)
		_solido(p + b * Vector3(sx * 4.6, 1.5, 0), Vector3(1.6, 3.0, 1.4), giro)
	_torta(p + b * Vector3(0, 5.6, 0), Vector3(1.3, 1.1, 1.7), giro, 0.3, 0.0, OSSO)
	for sx in [-1.0, 1.0]:
		_torta(p + b * Vector3(sx * 0.5, 6.4, -0.3), Vector3(0.2, 1.1, 0.2), giro, -0.5, sx * 0.3, OSSO, "piramide")
