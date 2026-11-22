class_name PonteDeMadeira
extends Node3D
## Ponte de madeira sobre um rio: um tabuleiro inclinado que liga dois pontos do chão (a face de cima encosta no chão
## nas duas pontas, sem degrau), com tábuas, vigas e corrimão. Use `ligar(de, ate)` com os dois pontos em coordenadas do mundo.

var largura := 3.2


func ligar(de: Vector3, ate: Vector3) -> void:
	var dir := ate - de
	var comp := dir.length()
	var centro := (de + ate) / 2.0
	var frente := dir.normalized()
	var lado := frente.cross(Vector3.UP).normalized()
	var cima := lado.cross(frente).normalized()
	var base := Basis(lado, cima, -frente)   # eixo Z local = para trás da ponte; assim a caixa acompanha a inclinação
	var madeira := _mat(Color(0.32, 0.22, 0.12))
	var escura := _mat(Color(0.22, 0.15, 0.09))
	var corpo := StaticBody3D.new()
	corpo.transform = Transform3D(base, centro - cima * 0.15)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(largura, 0.3, comp)
	cs.shape = forma
	corpo.add_child(cs)
	add_child(corpo)
	var n := int(comp / 0.7)
	for i in n:   # tábuas atravessadas
		var t := (i + 0.5) / n - 0.5
		var tabua := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(largura, 0.08, 0.62)
		b.material = madeira if i % 2 == 0 else escura
		tabua.mesh = b
		tabua.transform = Transform3D(base, centro + frente * (t * comp) - cima * 0.04)
		add_child(tabua)
	for sinal in [-1.0, 1.0]:   # vigas laterais e corrimão com postes
		var viga := MeshInstance3D.new()
		var vb := BoxMesh.new()
		vb.size = Vector3(0.2, 0.3, comp)
		vb.material = escura
		viga.mesh = vb
		viga.transform = Transform3D(base, centro + lado * sinal * (largura / 2.0) - cima * 0.15)
		add_child(viga)
		var corrimao := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.1, 0.1, comp)
		cb.material = madeira
		corrimao.mesh = cb
		corrimao.transform = Transform3D(base, centro + lado * sinal * (largura / 2.0) + cima * 0.95)
		add_child(corrimao)
		for k in int(comp / 2.5) + 1:
			var t := float(k) / maxf(1.0, int(comp / 2.5)) - 0.5
			var poste := MeshInstance3D.new()
			var pb := BoxMesh.new()
			pb.size = Vector3(0.14, 1.1, 0.14)
			pb.material = madeira
			poste.mesh = pb
			poste.transform = Transform3D(base, centro + frente * (t * comp) + lado * sinal * (largura / 2.0) + cima * 0.45)
			add_child(poste)
		var parede := StaticBody3D.new()   # o corrimão também barra o jogador (não cai do lado)
		parede.transform = Transform3D(base, centro + lado * sinal * (largura / 2.0 + 0.1) + cima * 0.7)
		var cps := CollisionShape3D.new()
		var fs := BoxShape3D.new()
		fs.size = Vector3(0.2, 1.4, comp)
		cps.shape = fs
		parede.add_child(cps)
		add_child(parede)


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 1.0
	return m
