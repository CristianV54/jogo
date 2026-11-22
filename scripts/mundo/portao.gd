class_name Portao
extends Node3D
## Portão de ferro de duas folhas. Fechado bloqueia a passagem; `abrir()` afasta as folhas e libera o caminho.

var largura := 10.0
var _folhas: Array[StaticBody3D] = []


func _ready() -> void:
	var ferro := VilaRefugio._mat(Color(0.1, 0.1, 0.12))
	for lado in [-1.0, 1.0]:
		var f := StaticBody3D.new()
		f.position = Vector3(lado * largura / 4.0, 0.0, 0.0)
		for i in 7:
			var mi := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(0.18, 6.0, 0.18)
			b.material = ferro
			mi.mesh = b
			mi.position = Vector3(-largura / 4.0 + 0.4 + i * (largura / 2.0 - 0.8) / 6.0, 3.0, 0.0) + Vector3(largura / 4.0, 0, 0) * 0.0
			f.add_child(mi)
		var trav := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(largura / 2.0, 0.2, 0.2)
		tb.material = ferro
		trav.mesh = tb
		trav.position = Vector3(0.0, 4.5, 0.0)
		f.add_child(trav)
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(largura / 2.0, 6.0, 0.5)
		cs.shape = forma
		cs.position = Vector3(0.0, 3.0, 0.0)
		f.add_child(cs)
		add_child(f)
		_folhas.append(f)


func abrir() -> void:
	for i in _folhas.size():
		var f := _folhas[i]
		f.collision_layer = 0
		create_tween().tween_property(f, "position:x", f.position.x + (-1.0 if i == 0 else 1.0) * largura / 2.0, 1.6)
